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
