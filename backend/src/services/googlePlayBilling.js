import crypto from 'node:crypto';
import { GoogleAuth } from 'google-auth-library';
import { db, FieldValue } from '../config/firebaseAdmin.js';

const PACKAGE_NAME = 'com.josephmensah.promptapp';
const PRODUCT_PLANS = new Map([
  ['prompt_premium_monthly', 'monthly'],
  ['prompt_premium_yearly', 'yearly'],
]);
const ENTITLED_STATES = new Set([
  'SUBSCRIPTION_STATE_ACTIVE',
  'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
  'SUBSCRIPTION_STATE_CANCELED',
]);

const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/androidpublisher'],
});

async function playApiRequest(path, { method = 'GET', body } = {}) {
  const accessToken = await auth.getAccessToken();
  const response = await fetch(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/${path}`,
    {
      method,
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    },
  );
  if (!response.ok) {
    const payload = await response.json().catch(() => ({}));
    const error = new Error(
      payload?.error?.message || 'Google Play purchase verification failed.',
    );
    error.status = response.status >= 500 ? 502 : 400;
    error.code = 'google-play-verification-failed';
    throw error;
  }
  if (response.status === 204) return {};
  return response.json();
}

function purchaseTokenId(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

async function verifyGoogleSubscription({ authenticatedUser, productId, purchaseToken }) {
  if (!PRODUCT_PLANS.has(productId)) {
    const error = new Error('Unknown subscription product.');
    error.status = 400;
    error.code = 'invalid-product';
    throw error;
  }
  if (typeof purchaseToken !== 'string' || purchaseToken.length < 20) {
    const error = new Error('A valid Google Play purchase token is required.');
    error.status = 400;
    error.code = 'invalid-purchase-token';
    throw error;
  }

  const purchase = await playApiRequest(
    `applications/${encodeURIComponent(PACKAGE_NAME)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`,
  );
  const matchingLineItem = purchase.lineItems?.find(
    (item) => item.productId === productId,
  );
  const expiryDate = matchingLineItem?.expiryTime
    ? new Date(matchingLineItem.expiryTime)
    : null;
  const active = Boolean(
    matchingLineItem &&
      expiryDate &&
      expiryDate.getTime() > Date.now() &&
      ENTITLED_STATES.has(purchase.subscriptionState),
  );

  const uid = authenticatedUser.decodedToken.uid;
  const tokenRef = db.collection('googlePlayPurchases').doc(
    purchaseTokenId(purchaseToken),
  );
  const userRef = authenticatedUser.userRef;

  await db.runTransaction(async (transaction) => {
    const tokenSnapshot = await transaction.get(tokenRef);
    const userSnapshot = await transaction.get(userRef);
    const existingUid = tokenSnapshot.data()?.uid;
    if (existingUid && existingUid !== uid) {
      const error = new Error('This purchase belongs to another account.');
      error.status = 409;
      error.code = 'purchase-already-linked';
      throw error;
    }

    transaction.set(tokenRef, {
      uid,
      productId,
      subscriptionState: purchase.subscriptionState ?? null,
      expiryDate,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    const tokenHash = purchaseTokenId(purchaseToken);
    if (active) {
      transaction.set(userRef, {
        isPremium: true,
        planType: PRODUCT_PLANS.get(productId),
        premiumExpiryDate: expiryDate,
        googlePlayProductId: productId,
        googlePlayPurchaseTokenHash: tokenHash,
        subscriptionUpdatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    } else {
      // An account can have an expired old token and a newer active token.
      // Only revoke access when the inactive token is the entitlement that is
      // currently linked, preventing restore order from revoking a renewal.
      const currentTokenHash = userSnapshot.data()?.googlePlayPurchaseTokenHash;
      if (!currentTokenHash || currentTokenHash === tokenHash) {
        transaction.set(userRef, {
          isPremium: false,
          planType: 'free',
          premiumExpiryDate: expiryDate,
          subscriptionUpdatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
    }
  });

  // Acknowledge only initial purchases that Google still marks unacknowledged.
  // Renewals do not require a second acknowledgement.
  if (active && purchase.acknowledgementState === 'ACKNOWLEDGEMENT_STATE_PENDING') {
    await playApiRequest(
      `applications/${encodeURIComponent(PACKAGE_NAME)}/purchases/subscriptions/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`,
      { method: 'POST', body: {} },
    );
  }

  return {
    active,
    productId,
    planType: active ? PRODUCT_PLANS.get(productId) : 'free',
    expiryTime: expiryDate?.toISOString() ?? null,
  };
}

export { verifyGoogleSubscription };
