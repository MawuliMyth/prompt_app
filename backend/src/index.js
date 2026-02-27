import express from 'express';
import multer from 'multer';
import cors from 'cors';
import dotenv from 'dotenv';
import { transcribeAudio } from './services/groq.js';
import { enhancePrompt } from './services/claude.js';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Configure multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 25 * 1024 * 1024, // 25MB max file size (Groq limit)
  },
  fileFilter: (req, file, cb) => {
    // Accept audio files
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
      'video/webm' // Some browsers send webm audio as video/webm
    ];

    if (allowedMimes.includes(file.mimetype) ||
        file.originalname.match(/\.(webm|mp3|mp4|m4a|wav|ogg|oga|mpeg|aac|flac)$/i)) {
      cb(null, true);
    } else {
      cb(new Error(`Invalid file type: ${file.mimetype}. Only audio files are allowed.`));
    }
  }
});

// CORS configuration
const allowedOrigins = [
  'http://localhost:5000',
  'http://localhost:3000',
  process.env.FRONTEND_URL
].filter(Boolean);

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps or curl)
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Parse JSON bodies
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Transcription endpoint
app.post('/api/transcribe', upload.single('audio'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'No audio file provided'
      });
    }

    console.log(`Transcribing audio: ${req.file.originalname}, size: ${req.file.size} bytes`);

    const text = await transcribeAudio(req.file.buffer, req.file.originalname);

    console.log(`Transcription complete: "${text.substring(0, 100)}..."`);

    res.json({
      success: true,
      text: text
    });
  } catch (error) {
    console.error('Transcription error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to transcribe audio'
    });
  }
});

// Prompt enhancement endpoint
app.post('/api/enhance', async (req, res) => {
  try {
    const { prompt, category } = req.body;

    if (!prompt || prompt.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Prompt text is required'
      });
    }

    console.log(`Enhancing prompt for category: ${category || 'General'}`);

    const enhancedPrompt = await enhancePrompt(prompt, category || 'General');

    console.log(`Enhancement complete`);

    res.json({
      success: true,
      enhancedPrompt: enhancedPrompt
    });
  } catch (error) {
    console.error('Enhancement error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to enhance prompt'
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        error: 'File too large. Maximum size is 25MB.'
      });
    }
    return res.status(400).json({
      success: false,
      error: error.message
    });
  }

  console.error('Unhandled error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Transcribe endpoint: POST http://localhost:${PORT}/api/transcribe`);
  console.log(`Enhance endpoint: POST http://localhost:${PORT}/api/enhance`);
});
