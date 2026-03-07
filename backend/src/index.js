import dotenv from 'dotenv';
import { createApp } from './app.js';
import { transcribeAudio } from './services/groq.js';
import { enhancePrompt, generateVariations } from './services/claude.js';
import {
  activateTrialForUser,
  checkEnhanceAccess,
  checkVariationAccess,
  createError,
  deleteUserAccount,
  getAuthenticatedUser,
  recordEnhanceSuccess,
} from './services/accessControl.js';
import { createRateLimiter } from './middleware/rateLimiter.js';

dotenv.config();

const PORT = process.env.PORT || 3001;

const app = createApp({
  transcribeAudio,
  enhancePrompt,
  generateVariations,
  activateTrialForUser,
  checkEnhanceAccess,
  checkVariationAccess,
  createError,
  deleteUserAccount,
  getAuthenticatedUser,
  recordEnhanceSuccess,
  createRateLimiter,
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Transcribe endpoint: POST http://localhost:${PORT}/api/transcribe`);
  console.log(`Enhance endpoint: POST http://localhost:${PORT}/api/enhance`);
});
