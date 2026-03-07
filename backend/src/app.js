import express from 'express';
import multer from 'multer';
import cors from 'cors';

function createApp({
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
  allowedOrigins = [
    'http://localhost:5000',
    'http://localhost:3000',
    process.env.FRONTEND_URL,
  ].filter(Boolean),
}) {
  const app = express();

  const storage = multer.memoryStorage();
  const upload = multer({
    storage,
    limits: {
      fileSize: 25 * 1024 * 1024,
    },
    fileFilter: (req, file, cb) => {
      const allowedMimes = [
        'audio/webm',
        'audio/mp3',
        'audio/mpeg',
        'audio/mp4',
        'audio/m4a',
        'audio/x-m4a',
        'audio/wav',
        'audio/ogg',
        'audio/oga',
        'audio/aac',
        'audio/flac',
        'video/webm',
      ];

      if (
        allowedMimes.includes(file.mimetype) ||
        file.originalname.match(/\.(webm|mp3|mp4|m4a|wav|ogg|oga|mpeg|aac|flac)$/i)
      ) {
        cb(null, true);
      } else {
        cb(
          new Error(
            `Invalid file type: ${file.mimetype}. Only audio files are allowed.`,
          ),
        );
      }
    },
  });

  const transcribeRateLimit = createRateLimiter({
    keyPrefix: 'transcribe',
    windowMs: 15 * 60 * 1000,
    maxRequests: 10,
  });
  const enhanceRateLimit = createRateLimiter({
    keyPrefix: 'enhance',
    windowMs: 15 * 60 * 1000,
    maxRequests: 20,
  });
  const variationRateLimit = createRateLimiter({
    keyPrefix: 'variations',
    windowMs: 15 * 60 * 1000,
    maxRequests: 10,
  });
  const accountRateLimit = createRateLimiter({
    keyPrefix: 'account',
    windowMs: 60 * 60 * 1000,
    maxRequests: 10,
  });

  app.use(
    cors({
      origin: (origin, callback) => {
        if (!origin) return callback(null, true);
        if (allowedOrigins.includes(origin)) {
          callback(null, true);
        } else {
          callback(new Error('Not allowed by CORS'));
        }
      },
      credentials: true,
      methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
    }),
  );

  app.use(express.json());

  app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  app.post(
    '/api/transcribe',
    transcribeRateLimit,
    upload.single('audio'),
    async (req, res, next) => {
      try {
        if (!req.file) {
          return res.status(400).json({
            success: false,
            error: 'No audio file provided',
          });
        }

        console.log(
          `Transcribing audio: ${req.file.originalname}, size: ${req.file.size} bytes`,
        );

        const text = await transcribeAudio(req.file.buffer, req.file.originalname);

        console.log(`Transcription complete (${text.length} chars)`);

        res.json({
          success: true,
          text,
        });
      } catch (error) {
        next(error);
      }
    },
  );

  app.post('/api/enhance', enhanceRateLimit, async (req, res, next) => {
    try {
      const { prompt, category, tone, persona } = req.body;

      if (!prompt || prompt.trim().length === 0) {
        return res.status(400).json({
          success: false,
          error: 'Prompt text is required',
        });
      }

      const accessContext = await checkEnhanceAccess(req);
      console.log(
        `Enhancing prompt for category: ${category || 'General'}, authType: ${accessContext.type}, hasPremium: ${accessContext.hasPremium === true}, tone: ${tone || 'Auto'}`,
      );

      const enhancedPrompt = await enhancePrompt(
        prompt,
        category || 'General',
        accessContext.hasPremium === true,
        tone || 'Auto',
        persona || null,
      );

      await recordEnhanceSuccess(accessContext);

      res.json({
        success: true,
        enhancedPrompt,
      });
    } catch (error) {
      next(error);
    }
  });

  app.post('/api/variations', variationRateLimit, async (req, res, next) => {
    try {
      const { prompt, category } = req.body;

      if (!prompt || prompt.trim().length === 0) {
        return res.status(400).json({
          success: false,
          error: 'Prompt text is required',
        });
      }

      const authenticatedUser = await checkVariationAccess(req);
      console.log(
        `Generating variations for category: ${category || 'General'}, user: ${authenticatedUser.decodedToken.uid}`,
      );

      const variations = await generateVariations(prompt, category || 'General', true);

      res.json({
        success: true,
        variations,
      });
    } catch (error) {
      next(error);
    }
  });

  app.post('/api/trial/activate', accountRateLimit, async (req, res, next) => {
    try {
      const authenticatedUser = await getAuthenticatedUser(req);
      if (!authenticatedUser) {
        throw createError(401, 'Please sign in to start a trial.', 'auth-required');
      }

      await activateTrialForUser(authenticatedUser);

      res.json({
        success: true,
        message: 'Trial activated successfully.',
      });
    } catch (error) {
      next(error);
    }
  });

  app.delete('/api/account', accountRateLimit, async (req, res, next) => {
    try {
      const authenticatedUser = await getAuthenticatedUser(req);
      if (!authenticatedUser) {
        throw createError(
          401,
          'Please sign in again before deleting your account.',
          'auth-required',
        );
      }

      await deleteUserAccount(authenticatedUser);

      res.json({
        success: true,
        message: 'Account deleted successfully.',
      });
    } catch (error) {
      next(error);
    }
  });

  app.use((error, req, res, next) => {
    if (error.status) {
      console.warn(
        'Handled request error:',
        error.code || 'request-error',
        error.message,
      );
      return res.status(error.status).json({
        success: false,
        error: error.message,
        code: error.code || 'request-error',
      });
    }

    if (error instanceof multer.MulterError) {
      if (error.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({
          success: false,
          error: 'File too large. Maximum size is 25MB.',
        });
      }

      return res.status(400).json({
        success: false,
        error: error.message,
      });
    }

    console.error('Unhandled error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  });

  return app;
}

export { createApp };
