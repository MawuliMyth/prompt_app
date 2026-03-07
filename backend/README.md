# Prompt App Backend

Node.js backend for the Flutter prompt refinement app, providing Whisper-based voice transcription and Claude prompt enhancement.

This is the active production backend used by the Flutter app. The legacy `functions/` directory is not the primary runtime path.

## Features

- **Voice Transcription**: Groq Whisper API (free tier, 10x faster than OpenAI)
- **Prompt Enhancement**: Claude API (Anthropic)
- **Server-side Access Control**: Firebase token verification, premium enforcement, guest/free quotas
- **Account Operations**: Secure trial activation and account deletion endpoints

## Prerequisites

1. **Groq API Key** - Get free at https://console.groq.com
2. **Claude API Key** - Get from https://console.anthropic.com
3. **Firebase Admin credentials** - Required for token verification and secure Firestore access

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Copy `.env.example` to `.env` and add your environment variables:
   ```bash
   cp .env.example .env
   ```

3. Set these required variables:
   - `GROQ_API_KEY`
   - `CLAUDE_API_KEY`
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_CLIENT_EMAIL`
   - `FIREBASE_PRIVATE_KEY`
   - `GUEST_USAGE_SALT`
   - `FRONTEND_URL`

4. Start the server:
   ```bash
   npm run dev
   ```

5. Run backend tests:
   ```bash
   npm test
   ```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check |
| `POST` | `/api/transcribe` | Upload audio file for transcription |
| `POST` | `/api/enhance` | Enhance a prompt with server-side quota enforcement |
| `POST` | `/api/variations` | Generate premium-only prompt variations |
| `POST` | `/api/trial/activate` | Activate a signed-in user's trial |
| `DELETE` | `/api/account` | Delete a signed-in user's account |

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

Signed-in requests should also send:
```
Authorization: Bearer <firebase-id-token>
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
    - `FIREBASE_PROJECT_ID` - Firebase project id
    - `FIREBASE_CLIENT_EMAIL` - Firebase service account email
    - `FIREBASE_PRIVATE_KEY` - Firebase service account private key
    - `GUEST_USAGE_SALT` - Random secret used to hash guest usage keys
    - `FRONTEND_URL` - Your production frontend URL (for CORS)

6. Deploy! Your backend will be available at `https://your-service-name.onrender.com`

## Manual Verification Checklist

- Guest users can enhance prompts and are blocked after 5 requests per day
- Signed-in free users can enhance prompts and are blocked after 10 requests per day
- Trial or premium users can access `/api/variations`
- Account deletion succeeds only after a recent sign-in
- `GET /health` returns `status: ok`

### Notes
- Render's free tier will spin down after inactivity (cold start ~30 seconds)
- Set `FRONTEND_URL` to your frontend's URL (e.g., your Flutter web app URL) for CORS to work properly
- The Firebase service-account private key must remain secret and should only live in local `.env` files or hosted secret env vars
