# Quick Start: App Store Publishing

## 🚀 Fast Track (5 Steps)

### Step 1: Increment Version ✅
**Done!** Version updated to `1.2.0+6`

### Step 2: Build & Archive
```bash
# Open in Xcode
cd ios
open Runner.xcworkspace

# In Xcode:
# 1. Product → Clean Build Folder (Shift+Cmd+K)
# 2. Product → Archive
# 3. Wait for archive to complete
```

### Step 3: Create App in App Store Connect
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **+** → **New App**
3. Fill in:
   - Name: **Daily Quran**
   - Bundle ID: **com.hexahelix.dq**
   - SKU: **daily-quran-001**
4. Click **Create**

### Step 4: Upload Build
1. In Xcode Organizer (after archiving):
   - Click **Distribute App**
   - Choose **App Store Connect**
   - Select **Upload**
   - Follow prompts
2. Wait for processing (10-30 minutes)

### Step 5: Submit for Review
1. In App Store Connect → **Daily Quran** → **1.0 Prepare for Submission**
2. Fill in:
   - **Description** (see guide for example)
   - **Keywords:** `Quran, Islam, Prayer, Daily, Islamic, Hadith, Dua`
   - **Privacy Policy URL:** `https://uwais-manage.web.app/privacy-policy.html`
   - **Screenshots** (at least 1 per device size)
   - **App Review Information** (contact details)
3. Select your processed build
4. Click **Submit for Review**

---

## 📋 What You Need

### Required:
- ✅ Version number incremented
- ✅ Privacy Policy URL ready
- ⚠️ Screenshots (prepare these)
- ⚠️ App description (write this)
- ⚠️ Keywords (add these)

### Screenshot Sizes Needed:
- iPhone 6.7": 1290 x 2796 pixels
- iPhone 6.5": 1242 x 2688 pixels  
- iPhone 5.5": 1242 x 2208 pixels

### How to Get Screenshots:
```bash
# Run app in simulator
flutter run

# In Simulator: Cmd + S (saves to Desktop)
# Or: File → New Screen Recording
```

---

## 📖 Full Guide

See `APP_STORE_PUBLISHING_GUIDE.md` for complete step-by-step instructions.

---

## ⏱️ Timeline

- **Build & Upload:** 15-30 minutes
- **Processing:** 10-30 minutes
- **Review:** 24-48 hours
- **Total:** ~2-3 days from submission to approval

---

## 🎯 Current Status

✅ Ready to build and submit!
- Version: `1.2.0+6` ✅
- Bundle ID: `com.hexahelix.dq` ✅
- Privacy Policy: Ready ✅
- Signing: Configured ✅

⚠️ Still need:
- Screenshots
- App description
- App Store Connect setup

---

**Next:** Open Xcode and start archiving! 🚀

