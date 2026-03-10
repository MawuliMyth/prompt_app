#!/bin/bash
echo "Building release APK..."
flutter build apk --release

echo "Uploading to Firebase App Distribution..."
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app 1:436678880838:android:785f430b0bcaeab2a62447 \
  --groups "beta-testers" \
  --release-notes "Beta version for testing. Please test: voice input, prompt enhancement, history, favourites and settings."

echo "Done! Testers will receive email invitations."
