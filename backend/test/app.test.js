import test from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import { createApp } from '../src/app.js';

function buildError(status, message, code) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function buildApp(overrides = {}) {
  const noopRateLimiter = () => (req, res, next) => next();

  return createApp({
    transcribeAudio: async () => 'transcribed text',
    enhancePrompt: async (prompt, category, isPremium, tone, persona) =>
      `${prompt}|${category}|${isPremium}|${tone}|${persona}`,
    generateVariations: async () => ['one', 'two', 'three'],
    getAppConfig: () => ({
      categories: [{ id: 'general', label: 'General' }],
      tones: [],
      templateCategories: [],
      templates: [],
      homeFeatures: [],
      visualAssets: [],
    }),
    activateTrialForUser: async () => {},
    checkEnhanceAccess: async () => ({
      type: 'guest',
      hasPremium: false,
    }),
    checkVariationAccess: async () => ({
      decodedToken: { uid: 'user-123' },
    }),
    createError: buildError,
    deleteUserAccount: async () => {},
    getAuthenticatedUser: async () => ({
      decodedToken: { uid: 'user-123' },
    }),
    recordEnhanceSuccess: async () => {},
    createRateLimiter: noopRateLimiter,
    allowedOrigins: ['http://localhost:3000'],
    ...overrides,
  });
}

test('health endpoint returns ok', async () => {
  const app = buildApp();

  const response = await request(app).get('/health').expect(200);

  assert.equal(response.body.status, 'ok');
  assert.ok(response.body.timestamp);
});

test('app config endpoint returns config payload', async () => {
  const app = buildApp();

  const response = await request(app).get('/api/app-config').expect(200);

  assert.equal(response.body.success, true);
  assert.equal(response.body.config.categories[0].id, 'general');
});

test('enhance rejects empty prompt', async () => {
  const app = buildApp();

  const response = await request(app)
    .post('/api/enhance')
    .send({ prompt: '   ' })
    .expect(400);

  assert.equal(response.body.error, 'Prompt text is required');
});

test('enhance returns handled quota errors', async () => {
  const app = buildApp({
    checkEnhanceAccess: async () => {
      throw buildError(429, 'You have reached today\'s free prompt limit.', 'daily-limit-reached');
    },
  });

  const response = await request(app)
    .post('/api/enhance')
    .send({ prompt: 'hello', category: 'General' })
    .expect(429);

  assert.equal(response.body.code, 'daily-limit-reached');
  assert.equal(response.body.error, 'You have reached today\'s free prompt limit.');
});

test('enhance passes server-side premium access to the model service', async () => {
  let capturedIsPremium = null;
  const app = buildApp({
    checkEnhanceAccess: async () => ({
      type: 'user',
      hasPremium: true,
    }),
    enhancePrompt: async (prompt, category, isPremium, tone, persona) => {
      capturedIsPremium = isPremium;
      return `${prompt}:${category}:${tone}:${persona}`;
    },
  });

  const response = await request(app)
    .post('/api/enhance')
    .send({
      prompt: 'hello',
      category: 'Coding',
      tone: 'Technical',
      persona: 'Engineer',
      isPremium: false,
    })
    .expect(200);

  assert.equal(capturedIsPremium, true);
  assert.equal(response.body.success, true);
});

test('variations require premium access', async () => {
  const app = buildApp({
    checkVariationAccess: async () => {
      throw buildError(403, 'Prompt variations require premium access.', 'premium-required');
    },
  });

  const response = await request(app)
    .post('/api/variations')
    .send({ prompt: 'hello', category: 'General' })
    .expect(403);

  assert.equal(response.body.code, 'premium-required');
});

test('trial activation requires authentication', async () => {
  const app = buildApp({
    getAuthenticatedUser: async () => null,
  });

  const response = await request(app).post('/api/trial/activate').expect(401);

  assert.equal(response.body.code, 'auth-required');
});

test('trial activation forwards the installation id', async () => {
  let capturedInstallationId = null;
  const app = buildApp({
    activateTrialForUser: async (authenticatedUser, installationId) => {
      assert.equal(authenticatedUser.decodedToken.uid, 'user-123');
      capturedInstallationId = installationId;
    },
  });

  const response = await request(app)
    .post('/api/trial/activate')
    .send({ installationId: 'install-1234567890abcdef' })
    .expect(200);

  assert.equal(response.body.success, true);
  assert.equal(capturedInstallationId, 'install-1234567890abcdef');
});

test('trial activation surfaces invalid installation id errors', async () => {
  const app = buildApp({
    activateTrialForUser: async () => {
      throw buildError(400, 'A valid installation ID is required.', 'installation-required');
    },
  });

  const response = await request(app)
    .post('/api/trial/activate')
    .send({ installationId: 'bad-id' })
    .expect(400);

  assert.equal(response.body.code, 'installation-required');
});

test('trial activation surfaces email verification errors', async () => {
  const app = buildApp({
    activateTrialForUser: async () => {
      throw buildError(
        403,
        'Verify your email before starting a free trial.',
        'email-verification-required',
      );
    },
  });

  const response = await request(app)
    .post('/api/trial/activate')
    .send({ installationId: 'install-1234567890abcdef' })
    .expect(403);

  assert.equal(response.body.code, 'email-verification-required');
});

test('trial activation surfaces reused device errors', async () => {
  const app = buildApp({
    activateTrialForUser: async () => {
      throw buildError(
        409,
        'This device has already used a free trial.',
        'trial-device-already-used',
      );
    },
  });

  const response = await request(app)
    .post('/api/trial/activate')
    .send({ installationId: 'install-1234567890abcdef' })
    .expect(409);

  assert.equal(response.body.code, 'trial-device-already-used');
});

test('account deletion surfaces recent-login requirement', async () => {
  const app = buildApp({
    deleteUserAccount: async () => {
      throw buildError(401, 'Please sign in again before continuing.', 'requires-recent-login');
    },
  });

  const response = await request(app).delete('/api/account').expect(401);

  assert.equal(response.body.code, 'requires-recent-login');
});

test('transcribe requires audio upload', async () => {
  const app = buildApp();

  const response = await request(app).post('/api/transcribe').expect(400);

  assert.equal(response.body.error, 'No audio file provided');
});
