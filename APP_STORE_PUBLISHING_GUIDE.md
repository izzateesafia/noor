# Complete Guide: Publishing Daily Quran to App Store

## 📋 Prerequisites Checklist

Before starting, ensure you have:
- [x] Apple Developer Account ($99/year) - [Sign up here](https://developer.apple.com/programs/)
- [x] Xcode installed (latest version recommended)
- [x] macOS with Command Line Tools
- [x] App Store Connect access
- [x] Privacy Policy URL ready: `https://uwais-manage.web.app/privacy-policy.html`

---

## Step 1: Prepare Your App

### 1.1 Increment Version Number

**Current version:** `1.2.0+5`

For App Store submission, increment the build number:

```yaml
# In pubspec.yaml, line 19
version: 1.2.0+6  # Increment the +6 for each submission
```

**Note:** 
- `1.2.0` = Version (CFBundleShortVersionString) - shown to users
- `6` = Build number (CFBundleVersion) - must increment for each submission

### 1.2 Verify Bundle Identifier

Your bundle ID is: `com.hexahelix.dq`

This should match in:
- ✅ Xcode project settings
- ⚠️ App Store Connect (you'll create this)
- ✅ Apple Developer Portal

### 1.3 Clean and Prepare Build

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Update iOS pods
cd ios
pod install
pod update
cd ..
```

---

## Step 2: Configure Xcode Project

### 2.1 Open Project in Xcode

```bash
cd ios
open Runner.xcworkspace  # Important: Use .xcworkspace, not .xcodeproj
```

### 2.2 Configure Signing & Capabilities

1. In Xcode, select **Runner** in the Project Navigator (left sidebar)
2. Select the **Runner** target (under TARGETS)
3. Click **Signing & Capabilities** tab
4. Ensure:
   - ✅ **Team** is selected (your Apple Developer account)
   - ✅ **Automatically manage signing** is checked
   - ✅ **Bundle Identifier** is `com.hexahelix.dq`
   - ✅ **Provisioning Profile** is automatically generated

### 2.3 Set Build Configuration

1. Click **Product** → **Scheme** → **Edit Scheme...**
2. Ensure:
   - **Run** → Build Configuration: **Debug**
   - **Archive** → Build Configuration: **Release**
3. Click **Close**

### 2.4 Verify Deployment Target

1. In **Signing & Capabilities** tab
2. Check **iOS Deployment Target**: Should be **14.0** or higher
3. Your current target: **14.0** ✅

---

## Step 3: Build for App Store

### Option A: Using Xcode (Recommended)

1. **Clean Build Folder:**
   - Press `Shift + Cmd + K` or
   - **Product** → **Clean Build Folder**

2. **Archive:**
   - **Product** → **Archive**
   - Wait for archive to complete (5-10 minutes)
   - Xcode Organizer window opens automatically

3. **Verify Archive:**
   - Check that your archive appears in the Organizer
   - Verify version and build number are correct

### Option B: Using Flutter CLI

```bash
# Build iOS release
flutter build ipa --release

# This creates: build/ios/ipa/daily_quran.ipa
```

**Note:** You'll still need Xcode to upload the IPA to App Store Connect.

---

## Step 4: App Store Connect Setup

### 4.1 Access App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple Developer account
3. Click **My Apps**

### 4.2 Create New App

1. Click the **+** button (top left) → **New App**

2. Fill in the form:
   - **Platform:** iOS
   - **Name:** Daily Quran
   - **Primary Language:** English (or your preference)
   - **Bundle ID:** Select `com.hexahelix.dq` (or create if not exists)
   - **SKU:** `daily-quran-001` (unique identifier, can be anything)
   - **User Access:** Full Access

3. Click **Create**

### 4.3 App Information

1. In your app's page, click **App Information** (left sidebar)

2. Fill in:
   - **Category:**
     - Primary: **Reference** or **Education** or **Lifestyle**
     - Secondary: (optional)
   - **Privacy Policy URL:** `https://uwais-manage.web.app/privacy-policy.html` ✅
   - **Support URL:** (your website or support email)
   - **Marketing URL:** (optional)

3. Click **Save**

### 4.4 App Store Listing

1. Click **1.0 Prepare for Submission** (or version number)

2. **App Store Listing:**
   - **Name:** Daily Quran (up to 30 characters)
   - **Subtitle:** (optional, up to 30 characters)
     - Example: "Your daily companion for Quran"
   - **Promotional Text:** (optional, up to 170 characters)
     - Example: "Read Quran daily, track prayers, and learn Islamic content"
   - **Description:** (up to 4000 characters)
     ```
     Daily Quran adalah aplikasi lengkap untuk pembacaan Al-Quran harian dan kandungan Islamik.
     
     Ciri-ciri utama:
     • Bacaan Al-Quran dengan terjemahan Bahasa Indonesia dan Bahasa Inggeris
     • Waktu solat yang tepat berdasarkan lokasi anda
     • Azan automatik untuk setiap waktu solat
     • Kandungan Islamik: Hadith, Doa, Berita Terkini
     • Video pembelajaran dan siaran langsung
     • Kelas pembelajaran dengan pendaftaran mudah
     • Tracker harian untuk kemajuan pembelajaran
     
     Aplikasi ini direka untuk membantu anda menjadikan Al-Quran sebagai sebahagian daripada rutin harian anda.
     ```
   - **Keywords:** (up to 100 characters, comma-separated)
     ```
     Quran, Islam, Prayer, Daily, Islamic, Hadith, Dua, Solat, Al-Quran, Terjemahan
     ```
   - **Support URL:** (your support website or email)
   - **Marketing URL:** (optional)

3. **App Privacy:**
   - Click **App Privacy**
   - Answer questions about data collection:
     - **Location Data:** Yes (for prayer times and Qiblah)
     - **User Content:** Yes (profile pictures, class enrollment)
     - **Identifiers:** Yes (user account)
     - **Usage Data:** Yes (app analytics)
   - Fill in details for each data type
   - Click **Save**

### 4.5 Screenshots (Required)

You need screenshots for different device sizes:

**Required Sizes:**
- **iPhone 6.7"** (iPhone 14 Pro Max, 15 Pro Max): 1290 x 2796 pixels
- **iPhone 6.5"** (iPhone 11 Pro Max, XS Max): 1242 x 2688 pixels
- **iPhone 5.5"** (iPhone 8 Plus): 1242 x 2208 pixels

**How to Create Screenshots:**

**Option 1: Using Simulator**
```bash
# Open iOS Simulator
open -a Simulator

# Run your app
flutter run

# Take screenshots:
# - Cmd + S (saves to Desktop)
# Or use: File → New Screen Recording
```

**Option 2: Using Physical Device**
1. Run app on iPhone
2. Take screenshots: Power + Volume Up
3. Screenshots saved to Photos app
4. Export to computer

**Option 3: Using Xcode**
1. Open app in Xcode
2. Run on simulator
3. **Device** → **Screenshots** → **New Screenshot**

**Upload Screenshots:**
1. In App Store Connect → **1.0 Prepare for Submission**
2. Scroll to **Screenshots**
3. Drag and drop screenshots for each device size
4. Add at least 1 screenshot per required size (up to 10 per size)

### 4.6 App Icon

- **Size:** 1024 x 1024 pixels
- **Format:** PNG or JPEG
- **No transparency**
- **No rounded corners** (Apple adds them automatically)

**Your icon:** ✅ Already configured at `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`

**Upload:**
1. In App Store Connect → **App Information**
2. Scroll to **App Icon**
3. Upload your 1024x1024 icon

---

## Step 5: Upload Build to App Store Connect

### Option A: Using Xcode Organizer (Recommended)

1. **After archiving** (Step 3), Xcode Organizer opens automatically

2. **Distribute App:**
   - Select your archive
   - Click **Distribute App**
   - Choose **App Store Connect**
   - Click **Next**

3. **Distribution Options:**
   - Select **Upload**
   - Click **Next**

4. **Distribution Method:**
   - Select **Automatically manage signing**
   - Click **Next**

5. **Review:**
   - Review app information
   - Click **Upload**

6. **Wait for Processing:**
   - Upload takes 5-15 minutes
   - Processing takes 10-30 minutes
   - You'll receive email when ready

### Option B: Using Transporter App

1. **Download Transporter:**
   - From Mac App Store
   - Search "Transporter"

2. **Open Transporter:**
   - Drag your `.ipa` file into Transporter
   - Click **Deliver**
   - Wait for upload and processing

### Option C: Using Command Line

```bash
# Upload IPA using altool
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/daily_quran.ipa \
  --username "your-apple-id@email.com" \
  --password "app-specific-password"
```

**Note:** You need to create an App-Specific Password:
1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in → **Security** → **App-Specific Passwords**
3. Generate new password
4. Use this password (not your Apple ID password)

---

## Step 6: Submit for Review

### 6.1 Wait for Build Processing

1. Go to App Store Connect → **My Apps** → **Daily Quran**
2. Click **1.0 Prepare for Submission**
3. Check **Build** section
4. Wait for status: **Processing** → **Ready to Submit**

### 6.2 Select Build

1. In **Build** section, click **+** or **Select a build before you submit your app**
2. Select your processed build
3. Click **Done**

### 6.3 Complete App Review Information

1. Scroll to **App Review Information**

2. Fill in:
   - **Contact Information:**
     - First Name
     - Last Name
     - Phone Number
     - Email
   - **Demo Account:** (if your app requires login)
     - Username
     - Password
     - Notes (optional)
   - **Notes:** (optional, for reviewers)
     ```
     This app provides daily Quran reading and Islamic content.
     Users can sign in with Google to access personalized features.
     All content is in Bahasa Malaysia.
     ```

3. **Version Information:**
   - **What's New in This Version:** (for first version, describe your app)
     ```
     Initial release of Daily Quran app.
     
     Features:
     - Daily Quran reading with translations
     - Accurate prayer times based on location
     - Automatic azan notifications
     - Islamic content: Hadith, Dua, News
     - Video learning and live streams
     - Class enrollment
     - Daily progress tracking
     ```

### 6.4 Export Compliance

1. Scroll to **Export Compliance**

2. Answer questions:
   - **Does your app use encryption?**
     - If yes: Select **Yes** and provide compliance documentation
     - If no: Select **No**
   - **Does your app use, contain, or incorporate cryptography?**
     - Usually **No** for most apps
     - If using HTTPS/Firebase: Usually **No** (exempt)

3. **Content Rights:**
   - If using third-party content, confirm you have rights
   - For Quran content: Usually you have rights if using public domain translations

### 6.5 Advertising Identifier (IDFA)

1. If your app uses advertising:
   - Answer questions about IDFA usage
   - Most apps: **No**

### 6.6 Submit for Review

1. Review all information
2. Ensure all required fields are filled:
   - ✅ Screenshots uploaded
   - ✅ App description written
   - ✅ Privacy Policy URL added
   - ✅ Build selected
   - ✅ Contact information filled

3. Click **Submit for Review** (top right)

4. Confirm submission

---

## Step 7: Review Process

### 7.1 Review Timeline

- **Initial Review:** 24-48 hours typically
- **Re-review:** 24-48 hours after fixes

### 7.2 Status Updates

You'll receive email updates:
- **Waiting for Review**
- **In Review**
- **Pending Developer Release** (if you set manual release)
- **Ready for Sale** (approved and live)
- **Rejected** (needs fixes)

### 7.3 Check Status

1. Go to App Store Connect → **My Apps** → **Daily Quran**
2. Check **App Store** tab for status
3. Click **Activity** tab for detailed history

### 7.4 If Rejected

1. Read rejection reason carefully
2. Fix issues
3. Update version/build number
4. Upload new build
5. Resubmit

---

## Step 8: After Approval

### 8.1 Release Options

When approved, you can:
- **Automatic Release:** App goes live immediately
- **Manual Release:** You control when to release

### 8.2 App Goes Live

- App appears in App Store within 24 hours
- Searchable by name and keywords
- Available for download

### 8.3 Monitor

- Check **Analytics** in App Store Connect
- Monitor **Reviews and Ratings**
- Respond to user feedback

### 8.4 Apple Pay / PassKit Reference

1. Apple Pay can be triggered from the **Classes → Class Detail → Bayar** flow. Tap any available class, then choose **Pembayaran Kelas** to surface the payment bottom sheet.
2. The toggle between **Apple Pay** and **Kad** is defined in `lib/class_payment_page.dart` (see `_buildToggleButton`, `_buildOnPayButton`, and `_processPayment`), which updates `PaymentBloc` to drive the UI.
3. The payment logic itself lives in `lib/blocs/payment/payment_bloc.dart`. When Apple Pay is selected, the bloc calls `Stripe.instance.confirmPlatformPayPaymentIntent` with `PlatformPayConfirmParams.applePay`, so App Review can observe the PassKit sheet.
4. The bundle contains the `com.apple.developer.in-app-payments` entitlement (`ios/Runner/Runner.entitlements`), which ties the PassKit capability to this flow. Mentioning these paths in the App Review notes helps the reviewer verify the functionality.

---

## 📝 Quick Reference Checklist

### Before Submission:
- [ ] Version number incremented (`1.2.0+6`)
- [ ] App tested on physical device
- [ ] All features working
- [ ] No console errors
- [ ] Screenshots prepared (at least 1 per required size)
- [ ] App description written
- [ ] Keywords added
- [ ] Privacy Policy URL added
- [ ] Support URL added
- [ ] App icon (1024x1024) ready
- [ ] Build archived/created
- [ ] App created in App Store Connect
- [ ] Build uploaded and processed

### Submission:
- [ ] Build selected in App Store Connect
- [ ] App Review Information filled
- [ ] Export Compliance answered
- [ ] All required fields completed
- [ ] Submitted for Review

---

## 🚨 Common Issues & Solutions

### Issue: "No eligible builds"
**Solution:** Wait for build processing to complete (10-30 minutes)

### Issue: "Missing compliance information"
**Solution:** Answer Export Compliance questions

### Issue: "Missing screenshots"
**Solution:** Upload at least 1 screenshot per required device size

### Issue: "Invalid bundle identifier"
**Solution:** Ensure bundle ID matches exactly: `com.hexahelix.dq`

### Issue: "Code signing errors"
**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### Issue: "Build upload fails"
**Solution:**
- Check internet connection
- Verify Apple Developer account is active
- Ensure certificates are valid
- Try using Xcode Organizer instead of command line

---

## 📞 Support Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Apple Developer Forums](https://developer.apple.com/forums/)

---

## 🎯 Your Current Status

✅ **Ready:**
- Bundle ID configured
- App icons ready
- Signing configured
- Privacy Policy URL ready
- Code quality verified

⚠️ **To Do:**
- Increment version number
- Prepare screenshots
- Write app description
- Create app in App Store Connect
- Build and upload
- Submit for review

---

**Good luck with your App Store submission! 🚀**

