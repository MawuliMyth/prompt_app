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
    enhancePrompt: async (prompt, category, isPremium, tone, persona, aiTool) =>
      `${prompt}|${category}|${isPremium}|${tone}|${persona}|${aiTool}`,
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
    verifyGoogleSubscription: async ({ productId }) => ({
      active: true,
      productId,
      planType: 'monthly',
      expiryTime: '2026-09-16T00:00:00.000Z',
    }),
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
    requireAdmin: async () => ({
      decodedToken: { uid: 'admin-1', email: 'admin@example.com' },
    }),
    createRateLimiter: noopRateLimiter,
    getSystemPrompts: async () => ({
      enhance: {
        role: 'role',
        task: 'task',
        personaTemplate: 'User context: {{persona}}.',
        rules: ['Rule 1', 'Rule 2'],
        categoryLineTemplate: 'For the category "{{category}}": {{instruction}}',
        toneLineTemplate: 'Tone requirement: {{toneInstruction}}',
        closingInstruction: 'Transform it.',
      },
      variations: {
        intro: 'intro',
        styles: ['formal', 'creative', 'concise'],
        categoryLineTemplate: 'For the category "{{category}}": {{instruction}}',
        outputInstruction: 'Return JSON only.',
        exampleOutput: '["one","two","three"]',
      },
    }),
    saveSystemPrompts: async (payload) => payload,
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

test('system prompt editor page is served', async () => {
  const app = buildApp();

  const response = await request(app).get('/system-prompts').expect(200);

  assert.match(response.text, /System prompt editor/i);
  assert.match(response.text, /Run enhance test/i);
});

test('privacy policy page is served from the backend', async () => {
  const app = buildApp();

  const response = await request(app).get('/privacy').expect(200);

  assert.match(response.text, /Privacy Policy/i);
  assert.match(response.text, /Prompt App/i);
});

test('terms page is served from the backend', async () => {
  const app = buildApp();

  const response = await request(app).get('/terms').expect(200);

  assert.match(response.text, /Terms and Conditions/i);
  assert.match(response.text, /Prompt App/i);
});

test('delete account page is served from the backend', async () => {
  const app = buildApp();

  const response = await request(app).get('/delete-account').expect(200);

  assert.match(response.text, /Delete Your Account/i);
  assert.match(response.text, /Prompt App/i);
});

test('system prompts endpoint returns prompt payload', async () => {
  const app = buildApp();

  const response = await request(app).get('/api/system-prompts').expect(200);

  assert.equal(response.body.success, true);
  assert.equal(response.body.prompts.enhance.role, 'role');
});

test('system prompts can be updated', async () => {
  let savedPayload = null;
  const app = buildApp({
    saveSystemPrompts: async (payload) => {
      savedPayload = payload;
      return payload;
    },
  });

  const payload = {
    enhance: {
      role: 'new role',
      task: 'new task',
      personaTemplate: 'User context: {{persona}}.',
      rules: ['Only answer', 'Keep intent'],
      categoryLineTemplate: 'For the category "{{category}}": {{instruction}}',
      toneLineTemplate: 'Tone requirement: {{toneInstruction}}',
      closingInstruction: 'Rewrite it.',
    },
    variations: {
      intro: 'Create three versions.',
      styles: ['FORMAL', 'CREATIVE', 'CONCISE'],
      categoryLineTemplate: 'For the category "{{category}}": {{instruction}}',
      outputInstruction: 'Return JSON.',
      exampleOutput: '["a","b","c"]',
    },
  };

  const response = await request(app)
    .put('/api/system-prompts')
    .send(payload)
    .expect(200);

  assert.deepEqual(savedPayload, payload);
  assert.equal(response.body.prompts.enhance.task, 'new task');
});

test('system prompts GET requires admin access', async () => {
  const app = buildApp({
    requireAdmin: async () => {
      throw buildError(403, 'Admin access required.', 'admin-required');
    },
  });

  const response = await request(app).get('/api/system-prompts').expect(403);

  assert.equal(response.body.code, 'admin-required');
});

test('system prompts PUT requires admin access', async () => {
  const app = buildApp({
    requireAdmin: async () => {
      throw buildError(401, 'Please sign in as an admin to continue.', 'auth-required');
    },
  });

  const response = await request(app)
    .put('/api/system-prompts')
    .send({})
    .expect(401);

  assert.equal(response.body.code, 'auth-required');
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
    enhancePrompt: async (prompt, category, isPremium, tone, persona, aiTool) => {
      capturedIsPremium = isPremium;
      return `${prompt}:${category}:${tone}:${persona}:${aiTool}`;
    },
  });

  const response = await request(app)
    .post('/api/enhance')
    .send({
      prompt: 'hello',
        category: 'Coding',
        tone: 'Technical',
        persona: 'Engineer',
        aiTool: 'Claude Code',
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

test('subscription verification requires authentication', async () => {
  const app = buildApp({ getAuthenticatedUser: async () => null });

  const response = await request(app)
    .post('/api/subscriptions/google/verify')
    .send({
      productId: 'prompt_premium_monthly',
      purchaseToken: 'valid-looking-purchase-token',
    })
    .expect(401);

  assert.equal(response.body.code, 'auth-required');
});

test('subscription verification returns the verified entitlement', async () => {
  const app = buildApp();

  const response = await request(app)
    .post('/api/subscriptions/google/verify')
    .send({
      productId: 'prompt_premium_monthly',
      purchaseToken: 'valid-looking-purchase-token',
    })
    .expect(200);

  assert.equal(response.body.active, true);
  assert.equal(response.body.planType, 'monthly');
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

test('transcribe enforces the same access check as enhance', async () => {
  const app = buildApp({
    checkEnhanceAccess: async () => {
      throw buildError(429, 'You have reached the guest daily limit. Sign in for more prompts.', 'guest-limit-reached');
    },
  });

  const response = await request(app)
    .post('/api/transcribe')
    .attach('audio', Buffer.from('fake-audio-bytes'), 'clip.webm')
    .expect(429);

  assert.equal(response.body.code, 'guest-limit-reached');
});
