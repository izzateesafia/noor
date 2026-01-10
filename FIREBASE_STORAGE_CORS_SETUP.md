# Firebase Storage CORS Configuration

## Overview
If video thumbnails or images are not loading on the web app, it may be due to CORS (Cross-Origin Resource Sharing) restrictions. Firebase Storage requires CORS to be configured to allow web browsers to load images.

## How to Configure CORS for Firebase Storage

### Method 1: Using gsutil (Recommended)

1. **Install Google Cloud SDK** (if not already installed):
   ```bash
   # macOS
   brew install google-cloud-sdk
   
   # Or download from: https://cloud.google.com/sdk/docs/install
   ```

2. **Authenticate with Google Cloud**:
   ```bash
   gcloud auth login
   ```

3. **Set your project**:
   ```bash
   gcloud config set project uwais-manage
   ```

4. **Create a CORS configuration file** (`cors.json`):
   ```json
   [
     {
       "origin": ["*"],
       "method": ["GET", "HEAD"],
       "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
       "maxAgeSeconds": 3600
     }
   ]
   ```

   For production, restrict origins:
   ```json
   [
     {
       "origin": [
         "https://uwais-manage.web.app",
         "https://uwais-manage.firebaseapp.com",
         "http://localhost:*"
       ],
       "method": ["GET", "HEAD"],
       "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
       "maxAgeSeconds": 3600
     }
   ]
   ```

5. **Apply CORS configuration**:
   ```bash
   gsutil cors set cors.json gs://uwais-manage.appspot.com
   ```

6. **Verify CORS configuration**:
   ```bash
   gsutil cors get gs://uwais-manage.appspot.com
   ```

### Method 2: Using Firebase Console (Limited)

Firebase Console doesn't directly support CORS configuration for Storage. You must use gsutil (Method 1) or the Google Cloud Console.

### Method 3: Using Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: `uwais-manage`
3. Navigate to **Cloud Storage** → **Buckets**
4. Click on your bucket: `uwais-manage.appspot.com`
5. Go to **Configuration** tab
6. Scroll to **CORS configuration**
7. Click **Edit CORS configuration**
8. Add the CORS rules (same JSON as in Method 1)
9. Save

## Troubleshooting

### Check if CORS is the issue:
1. Open browser Developer Tools (F12)
2. Go to **Network** tab
3. Try loading a thumbnail
4. Look for CORS errors in the console:
   - `Access to image at '...' from origin '...' has been blocked by CORS policy`
   - `No 'Access-Control-Allow-Origin' header is present`

### Common Issues:

1. **CORS not configured**: Follow Method 1 above
2. **Wrong bucket**: Ensure you're configuring the correct bucket (`uwais-manage.appspot.com`)
3. **Cache issues**: Clear browser cache after configuring CORS
4. **Wrong origin**: Ensure your web app's origin is in the CORS allowed origins list

## Testing

After configuring CORS:
1. Clear browser cache
2. Rebuild web app: `flutter build web --release`
3. Deploy: `firebase deploy --only hosting`
4. Test thumbnail loading in browser
5. Check browser console for any remaining errors

## Security Note

For production, **do NOT use `"origin": ["*"]`**. Instead, specify your exact domains:
- `https://uwais-manage.web.app`
- `https://uwais-manage.firebaseapp.com`
- `http://localhost:*` (for local development only)

