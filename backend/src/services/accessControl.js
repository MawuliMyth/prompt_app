import crypto from 'crypto';
import { admin, auth, db } from '../config/firebaseAdmin.js';

const FREE_DAILY_LIMIT = 10;
const GUEST_DAILY_LIMIT = 5;
const TRIAL_DURATION_MS = 3 * 24 * 60 * 60 * 1000;
const guestCollection = db.collection('guestUsage');
const userCollection = db.collection('users');
const trialInstallationCollection = db.collection('trialInstallations');

function getClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.ip || req.socket?.remoteAddress || 'unknown';
}

function getDateKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

function hashIp(ip) {
  const envSalt = process.env.GUEST_USAGE_SALT;
  if (!envSalt && process.env.NODE_ENV === 'production') {
    throw new Error('GUEST_USAGE_SALT is required in production');
  }
  const salt = envSalt || 'prompt-app-local-salt';
  return crypto.createHash('sha256').update(`${salt}:${ip}`).digest('hex');
}

function hashInstallationId(installationId) {
  return crypto
    .createHash('sha256')
    .update(`trial-installation:${installationId}`)
    .digest('hex');
}

function normalizeInstallationId(installationId) {
  if (typeof installationId !== 'string') {
    return null;
  }

  const normalized = installationId.trim();
  if (normalized.length < 16 || normalized.length > 200) {
    return null;
  }

  return normalized;
}

function isTrialActive(userData) {
  if (!userData?.trialStartDate) {
    return false;
  }

  const trialStart = userData.trialStartDate.toDate
    ? userData.trialStartDate.toDate()
    : new Date(userData.trialStartDate);

  return Date.now() < trialStart.getTime() + TRIAL_DURATION_MS;
}

function hasPremiumAccess(userData) {
  if (!userData) {
    return false;
  }

  if (isTrialActive(userData)) {
    return true;
  }

  if (userData.isPremium !== true) {
    return false;
  }

  if (userData.planType === 'lifetime') {
    return true;
  }

  if (!userData.premiumExpiryDate) {
    return false;
  }

  const expiry = userData.premiumExpiryDate.toDate
    ? userData.premiumExpiryDate.toDate()
    : new Date(userData.premiumExpiryDate);

  return Date.now() < expiry.getTime();
}

async function getAuthenticatedUser(req) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return null;
  }

  const idToken = header.slice('Bearer '.length).trim();
  if (!idToken) {
    return null;
  }

  const decodedToken = await auth.verifyIdToken(idToken, true);
  const userRef = userCollection.doc(decodedToken.uid);
  const snapshot = await userRef.get();

  return {
    idToken,
    decodedToken,
    userRef,
    userData: snapshot.exists ? snapshot.data() : {},
  };
}

function createError(status, message, code) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function requireRecentSignIn(decodedToken) {
  const authTimeSeconds = decodedToken.auth_time;
  if (!authTimeSeconds) {
    throw createError(401, 'Please sign in again before continuing.', 'requires-recent-login');
  }

  const ageSeconds = Math.floor(Date.now() / 1000) - authTimeSeconds;
  if (ageSeconds > 5 * 60) {
    throw createError(401, 'Please sign in again before continuing.', 'requires-recent-login');
  }
}

async function checkEnhanceAccess(req) {
  const authenticatedUser = await getAuthenticatedUser(req);
  if (authenticatedUser) {
    return {
      type: 'user',
      authenticatedUser,
      hasPremium: hasPremiumAccess(authenticatedUser.userData),
      userId: authenticatedUser.decodedToken.uid,
    };
  }

  const ipHash = hashIp(getClientIp(req));
  const dateKey = getDateKey();
  const guestRef = guestCollection.doc(`${dateKey}_${ipHash}`);
  const snapshot = await guestRef.get();
  const count = snapshot.exists ? snapshot.data()?.count ?? 0 : 0;

  if (count >= GUEST_DAILY_LIMIT) {
    throw createError(429, 'You have reached the guest daily limit. Sign in for more prompts.', 'guest-limit-reached');
  }

  return {
    type: 'guest',
    guestRef,
    guestCount: count,
  };
}

async function checkVariationAccess(req) {
  const authenticatedUser = await getAuthenticatedUser(req);
  if (!authenticatedUser) {
    throw createError(401, 'Please sign in to use prompt variations.', 'auth-required');
  }

  if (!hasPremiumAccess(authenticatedUser.userData)) {
    throw createError(403, 'Prompt variations require premium access.', 'premium-required');
  }

  return authenticatedUser;
}

async function recordEnhanceSuccess(accessContext) {
  if (accessContext.type === 'guest') {
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(accessContext.guestRef);
      const currentCount = snapshot.exists ? snapshot.data()?.count ?? 0 : 0;

      if (currentCount >= GUEST_DAILY_LIMIT) {
        throw createError(429, 'You have reached the guest daily limit. Sign in for more prompts.', 'guest-limit-reached');
      }

      transaction.set(accessContext.guestRef, {
        count: currentCount + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
    return;
  }

  const { userRef, userData } = accessContext.authenticatedUser;
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    const latestUserData = snapshot.exists ? snapshot.data() : userData ?? {};
    const updates = {
      totalPromptsGenerated: (latestUserData?.totalPromptsGenerated ?? 0) + 1,
    };

    if (!accessContext.hasPremium) {
      const now = new Date();
      const resetDate = latestUserData?.dailyPromptsResetDate?.toDate
        ? latestUserData.dailyPromptsResetDate.toDate()
        : latestUserData?.dailyPromptsResetDate
            ? new Date(latestUserData.dailyPromptsResetDate)
            : null;

      const isSameDay = resetDate &&
        resetDate.getFullYear() === now.getFullYear() &&
        resetDate.getMonth() === now.getMonth() &&
        resetDate.getDate() === now.getDate();

      const currentUsed = isSameDay ? (latestUserData?.dailyPromptsUsed ?? 0) : 0;
      if (currentUsed >= FREE_DAILY_LIMIT) {
        throw createError(429, 'You have reached today\'s free prompt limit.', 'daily-limit-reached');
      }

      updates.dailyPromptsUsed = currentUsed + 1;
      updates.dailyPromptsResetDate = admin.firestore.FieldValue.serverTimestamp();
    }

    transaction.set(userRef, updates, { merge: true });
  });
}

async function activateTrialForUser(authenticatedUser, installationId) {
  const { userRef, userData, decodedToken } = authenticatedUser;

  const normalizedInstallationId = normalizeInstallationId(installationId);
  if (!normalizedInstallationId) {
    throw createError(400, 'A valid installation ID is required.', 'installation-required');
  }

  if (!decodedToken.email_verified) {
    throw createError(403, 'Verify your email before starting a free trial.', 'email-verification-required');
  }

  if (userData?.trialUsed) {
    throw createError(409, 'Trial already used.', 'trial-already-used');
  }

  if (hasPremiumAccess(userData)) {
    throw createError(409, 'Premium is already active.', 'premium-already-active');
  }

  const installationRef = trialInstallationCollection.doc(
    hashInstallationId(normalizedInstallationId),
  );

  await db.runTransaction(async (transaction) => {
    const [userSnapshot, installationSnapshot] = await Promise.all([
      transaction.get(userRef),
      transaction.get(installationRef),
    ]);

    const latestUserData = userSnapshot.exists ? userSnapshot.data() : userData ?? {};
    if (latestUserData?.trialUsed) {
      throw createError(409, 'Trial already used.', 'trial-already-used');
    }

    if (hasPremiumAccess(latestUserData)) {
      throw createError(409, 'Premium is already active.', 'premium-already-active');
    }

    if (installationSnapshot.exists) {
      throw createError(
        409,
        'This device has already used a free trial.',
        'trial-device-already-used',
      );
    }

    transaction.set(userRef, {
      trialStartDate: admin.firestore.FieldValue.serverTimestamp(),
      trialUsed: true,
      isPremium: true,
      planType: 'trial',
      premiumExpiryDate: null,
      trialInstallationIdHash: hashInstallationId(normalizedInstallationId),
      trialActivatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    transaction.set(installationRef, {
      uid: decodedToken.uid,
      email: decodedToken.email ?? null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

async function deleteUserAccount(authenticatedUser) {
  requireRecentSignIn(authenticatedUser.decodedToken);

  const uid = authenticatedUser.decodedToken.uid;
  const userRef = userCollection.doc(uid);
  const promptsSnapshot = await userRef.collection('prompts').get();

  let batch = db.batch();
  let operationCount = 0;
  for (const doc of promptsSnapshot.docs) {
    batch.delete(doc.ref);
    operationCount += 1;
    if (operationCount === 450) {
      await batch.commit();
      batch = db.batch();
      operationCount = 0;
    }
  }

  batch.delete(userRef);
  await batch.commit();

  await auth.deleteUser(uid);
}

export {
  FREE_DAILY_LIMIT,
  GUEST_DAILY_LIMIT,
  activateTrialForUser,
  checkEnhanceAccess,
  checkVariationAccess,
  createError,
  deleteUserAccount,
  getAuthenticatedUser,
  getClientIp,
  recordEnhanceSuccess,
};
