# FindX Environment Variables

This document lists all environment variables required to run FindX.

## 1. Gemini API Key (Required)

**File:** `frontend/.env`

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

**Get your key:** https://aistudio.google.com/app/apikey

---

## 2. Firebase Configuration (Required)

### Android: `frontend/android/app/google-services.json`

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → Project Settings → General
3. Scroll to "Your apps" → Android app
4. Click "google-services.json" to download
5. Place in `frontend/android/app/`

### iOS: `frontend/ios/Runner/GoogleService-Info.plist`

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → Project Settings → General
3. Scroll to "Your apps" → iOS app
4. Click "GoogleService-Info.plist" to download
5. Place in `frontend/ios/Runner/`

---

## 3. Dashboard Environment (Optional)

**File:** `dashboard/.env.local`

```env
NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id
```

---

## 4. Google Maps API Key (Required for Maps)

**File:** `frontend/android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

**Get your key:** https://console.cloud.google.com/apis/credentials

---

## Security Notes

⚠️ **NEVER commit these files to Git:**
- `google-services.json`
- `GoogleService-Info.plist`
- `firebase_options.dart`
- `.env`
- `.env.local`

These are already added to `.gitignore`. Use the `.example` templates as reference.
