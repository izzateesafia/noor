# Privacy Policy Deployment Guide

## ✅ Privacy Policy HTML Created

The privacy policy HTML file has been created at:
- **File:** `web/privacy-policy.html`
- **Content:** Based on your `PolicyPage` widget content in Bahasa Malaysia

## 🚀 Deployment Steps

### Step 1: Build Flutter Web App

The privacy policy HTML file is in the `web` directory. When you build your Flutter web app, it will be copied to `build/web`:

```bash
flutter build web
```

### Step 2: Deploy to Firebase Hosting

Deploy the web app (including the privacy policy) to Firebase Hosting:

```bash
firebase deploy --only hosting
```

### Step 3: Verify Deployment

After deployment, your privacy policy will be available at:

**Primary URL:**
```
https://uwais-manage.web.app/privacy-policy.html
```

**Alternative URL:**
```
https://uwais-manage.firebaseapp.com/privacy-policy.html
```

### Step 4: Test the URL

Open the URL in your browser to verify:
1. The page loads correctly
2. Content is displayed properly
3. Styling looks good on mobile and desktop

## 📱 Add to App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app → **App Information**
3. Scroll to **Privacy Policy URL**
4. Enter: `https://uwais-manage.web.app/privacy-policy.html`
5. Click **Save**

## 🔄 Updating the Privacy Policy

If you need to update the privacy policy in the future:

1. Edit `web/privacy-policy.html`
2. Update the "Kemaskini terakhir" (Last Updated) date
3. Rebuild and redeploy:
   ```bash
   flutter build web
   firebase deploy --only hosting
   ```

## 📝 Notes

- The privacy policy is in Bahasa Malaysia (matching your app)
- The HTML file is mobile-responsive
- It includes all content from your `PolicyPage` widget:
  - Dasar Privasi (Privacy Policy)
  - Terma Penggunaan (Terms of Use)
  - Hubungi Kami (Contact Us)
- The file will be automatically included when you build the Flutter web app

## ✅ Checklist

- [x] Privacy policy HTML file created
- [x] Firebase hosting configuration updated
- [ ] Build Flutter web app (`flutter build web`)
- [ ] Deploy to Firebase Hosting (`firebase deploy --only hosting`)
- [ ] Verify URL works in browser
- [ ] Add URL to App Store Connect

## 🎯 Next Steps

1. **Build and deploy:**
   ```bash
   flutter build web
   firebase deploy --only hosting
   ```

2. **Add to App Store Connect:**
   - URL: `https://uwais-manage.web.app/privacy-policy.html`

3. **Continue with App Store submission checklist**

