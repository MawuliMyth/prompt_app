# Prompt App Backend

Node.js backend for the Flutter prompt refinement app, providing Whisper-based voice transcription and Claude prompt enhancement.

## Features

- **Voice Transcription**: Groq Whisper API (free tier, 10x faster than OpenAI)
- **Prompt Enhancement**: Claude API (Anthropic)

## Prerequisites

1. **Groq API Key** - Get free at https://console.groq.com
2. **Claude API Key** - Get from https://console.anthropic.com

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Copy `.env.example` to `.env` and add your API keys:
   ```bash
   cp .env.example .env
   ```

3. Start the server:
   ```bash
   npm run dev
   ```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check |
| `POST` | `/api/transcribe` | Upload audio file for transcription |
| `POST` | `/api/enhance` | Enhance a prompt with Claude |

### POST /api/transcribe

Upload audio file (multipart/form-data):
```
curl -X POST http://localhost:3001/api/transcribe \
  -F "audio=@recording.webm"
```

Response:
```json
{
  "success": true,
  "text": "transcribed text here"
}
```

### POST /api/enhance

Send prompt for enhancement:
```
curl -X POST http://localhost:3001/api/enhance \
  -H "Content-Type: application/json" \
  -d '{"prompt": "rough prompt text", "category": "General"}'
```

Response:
```json
{
  "success": true,
  "enhancedPrompt": "enhanced text here"
}
```

## Deploying to Render

1. Push your code to a Git repository (GitHub, GitLab, etc.)

2. Go to [Render Dashboard](https://dashboard.render.com) and create a new **Web Service**

3. Connect your repository and select the `backend` directory (or root if this is the root)

4. Render will auto-detect the `render.yaml` file, or manually configure:
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`

5. Add environment variables in Render's dashboard:
   - `GROQ_API_KEY` - Your Groq API key
   - `CLAUDE_API_KEY` - Your Claude API key
   - `FRONTEND_URL` - Your production frontend URL (for CORS)

6. Deploy! Your backend will be available at `https://your-service-name.onrender.com`

### Notes
- Render's free tier will spin down after inactivity (cold start ~30 seconds)
- Set `FRONTEND_URL` to your frontend's URL (e.g., your Flutter web app URL) for CORS to work properly
