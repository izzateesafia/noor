# Firebase Storage CORS Setup Guide

This guide explains how to configure CORS (Cross-Origin Resource Sharing) for Firebase Storage to enable image loading on Flutter Web.

## Why CORS is Needed

Flutter Web runs in a browser, which enforces CORS policies. Without proper CORS configuration, Firebase Storage images will fail to load on web (they work fine on mobile because mobile SDKs don't enforce CORS).

## Prerequisites

1. **Google Cloud SDK** (`gsutil` command)
   - Install from: https://cloud.google.com/sdk/docs/install
   - Or install via Homebrew (macOS): `brew install google-cloud-sdk`

2. **Firebase Authentication**
   - Run: `gcloud auth login`
   - Or: `firebase login`

## Step 1: Verify Project

Your Firebase project ID is: `uwais-manage`

Your Storage bucket is: `uwais-manage.firebasestorage.app`

**Note:** Firebase uses the newer bucket naming convention (`project-id.firebasestorage.app`). If this doesn't work, try the older format (`project-id.appspot.com`).

## Step 2: Apply CORS Configuration

### Option A: Using the Setup Script (Recommended)

Run the automated setup script:

```bash
./setup_cors.sh
```

This script will:
- Check if `gsutil` is available
- Verify authentication
- Set the project
- Apply CORS configuration
- Verify the configuration

### Option B: Manual Setup

Run the following command from the project root:

```bash
gsutil cors set cors.json gs://uwais-manage.firebasestorage.app
```

**Note:** If you get a "bucket not found" error, try the older bucket name:
```bash
gsutil cors set cors.json gs://uwais-manage.appspot.com
```

## Step 3: Verify CORS is Applied

Check that CORS was set correctly:

```bash
gsutil cors get gs://uwais-manage.firebasestorage.app
```

Or if using the older bucket name:
```bash
gsutil cors get gs://uwais-manage.appspot.com
```

You should see output similar to:

```json
[
  {
    "origin": ["*"],
    "method": ["GET"],
    "maxAgeSeconds": 3600
  }
]
```

## Step 4: Test on Web

1. Deploy or run your Flutter web app
2. Open browser DevTools (F12)
3. Check Console tab for CORS errors (should be none)
4. Verify images load correctly:
   - Video thumbnails
   - Ad images
   - News images
   - Hadith images
   - Dua images
   - Class images

## Restricting Origins (Optional - For Production)

For better security, you can restrict CORS to specific domains. Update `cors.json`:

```json
[
  {
    "origin": [
      "https://uwais-manage.web.app",
      "https://uwais-manage.firebaseapp.com",
      "http://localhost"
    ],
    "method": ["GET"],
    "maxAgeSeconds": 3600
  }
]
```

Then re-apply:

```bash
gsutil cors set cors.json gs://uwais-manage.firebasestorage.app
```

## Troubleshooting

### Error: "Command 'gsutil' not found"
- Install Google Cloud SDK (see Prerequisites)

### Error: "Access Denied"
- Run `gcloud auth login` to authenticate
- Ensure you have Storage Admin permissions on the Firebase project

### Images Still Don't Load
1. Check browser console for specific error messages
2. Verify storage rules allow read access (check `storage.rules`)
3. Ensure URLs are HTTPS (not `gs://` paths)
4. Clear browser cache and hard refresh (Cmd+Shift+R / Ctrl+Shift+R)

## Notes

- CORS configuration is a one-time setup per Firebase Storage bucket
- Changes take effect immediately after applying
- The `maxAgeSeconds: 3600` means browsers cache CORS preflight responses for 1 hour

