# 📱 Mobile App Deployment

## Android (Google Play Store)
```bash
# 1. Build release
flutter build appbundle --release

# 2. Upload to Google Play Console
# - Go to play.google.com/console
# - Create new app or update existing
# - Upload the .aab file
# - Fill store listing
# - Submit for review
```

## iOS (App Store)
```bash
# 1. Build release
flutter build ios --release

# 2. Upload to App Store Connect
# - Go to appstoreconnect.apple.com
# - Create new app or update existing
# - Upload the .ipa file
# - Fill app metadata
# - Submit for review
```

## Required Files
```
android/app/build.gradle    # Android config
ios/Runner/Info.plist   # iOS config
assets/app_icon.png      # App icon (512x512)
assets/splash.png        # Splash screen
privacy_policy.html       # Privacy policy
```

## Quick Test
```bash
# Test on device
flutter run

# Build for testing
flutter build apk --debug
flutter build ios --debug
```

## One Command Deploy
```bash
# Android
flutter build appbundle --release

# iOS  
flutter build ios --release
```

## 🎉 Done!
Your RAG app is now ready for the app stores!
