# promt_app

Flutter app for prompt enhancement with voice transcription, Firebase auth, quota enforcement, and a Node.js backend.

## Project Structure

- `lib/` - Flutter application code
- `backend/` - Active Express backend used by the app in development and production
- `functions/` - Legacy Firebase Functions prototype kept for reference only

## Backend

The active API lives in `backend/`.

See `backend/README.md` for:
- environment variables
- local startup
- backend tests
- Render deployment steps
- manual verification checklist

## Flutter

Common commands:

```bash
flutter pub get
flutter analyze
flutter run
```

## Security Notes

- Do not commit real `.env` files or Firebase service-account keys
- Premium access and free/guest quotas are enforced by the backend, not just the client
- Deploy `firestore.rules` whenever Firestore access rules change
