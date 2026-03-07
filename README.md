# Prompt App

A Flutter mobile app for enhancing AI prompts with voice transcription, AI-powered optimization, and quota management.

## Features

- **Voice-to-Text**: Record your ideas and have them automatically transcribed
- **AI Prompt Enhancement**: Transform rough ideas into optimized prompts using Claude
- **Categories**: General, Image Generation, Coding, Writing, Business
- **Tone Selection**: Professional, Creative, Casual, Persuasive, Technical (Premium)
- **User Authentication**: Firebase Auth (Google, Apple, Email/Password)
- **Quota System**: Free users get 5 prompts/day, Premium users get unlimited
- **History & Favorites**: Save and organize your enhanced prompts
- **Templates**: Pre-built prompt templates for common use cases
- **Analytics**: Track your prompt usage and patterns

## Project Structure

```
lib/
├── core/           # Theme, constants, widgets, utilities
├── data/          # Models, repositories, services
├── providers/     # State management (Provider)
├── screens/       # UI screens (Home, History, Settings, etc.)
└── main.dart      # App entry point

backend/           # Node.js Express API
├── src/
│   ├── config/    # Firebase Admin setup
│   ├── middleware/# Rate limiting
│   ├── services/  # AI services (Claude, Groq), access control
│   └── app.js     # Express routes
```

## Getting Started

### Prerequisites

- Flutter SDK ^3.11.0
- Node.js (for backend)
- Firebase project with Auth and Firestore enabled

### Backend Setup

1. Navigate to `backend/`
2. Copy `.env.example` to `.env` and fill in your values:
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_PRIVATE_KEY`
   - `FIREBASE_CLIENT_EMAIL`
   - `CLAUDE_API_KEY`
   - `GROQ_API_KEY`
3. Install dependencies: `npm install`
4. Run locally: `npm run dev`

### Flutter Setup

```bash
# Install dependencies
flutter pub get

# Run code analysis
flutter analyze

# Run the app
flutter run
```

## Environment Variables

### Backend (.env)

| Variable | Description |
|----------|-------------|
| `PORT` | Server port (default: 3000) |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_PRIVATE_KEY` | Firebase service account private key |
| `FIREBASE_CLIENT_EMAIL` | Firebase service account email |
| `CLAUDE_API_KEY` | Anthropic Claude API key |
| `GROQ_API_KEY` | Groq API key (optional) |

## Security Notes

- Never commit `.env` files or Firebase service account keys
- Quota enforcement is handled by the backend, not just the client
- Update `firestore.rules` when changing Firestore access rules
