# Lock Screen Widget Setup Guide

This guide explains how to set up lock screen widgets for prayer times on both iOS and Android.

## Overview

The app now supports lock screen widgets that display prayer times. The widgets automatically update when prayer times are fetched in the app.

## Android Setup

The Android widget is already configured and ready to use. Users can add it by:

1. Long-press on the home screen or lock screen
2. Select "Widgets"
3. Find "Daily Quran" or "Prayer Times Widget"
4. Drag it to the desired location

The widget will automatically update every 30 minutes and whenever prayer times are updated in the app.

## iOS Setup

iOS widgets require additional setup in Xcode. Follow these steps:

### Step 1: Create Widget Extension Target

1. Open `ios/Runner.xcworkspace` in Xcode
2. Go to **File** → **New** → **Target...**
3. Select **Widget Extension** and click **Next**
4. Configure:
   - **Product Name**: `PrayerTimesWidget`
   - **Organization Identifier**: `com.hexahelix.dq` (or your identifier)
   - **Language**: Swift
   - **Include Configuration Intent**: Unchecked (we're using static configuration)
5. Click **Finish**
6. When prompted, click **Activate** to add the scheme

### Step 2: Add Widget Files

The widget Swift files have been created in `ios/PrayerTimesWidget/`. You need to:

1. In Xcode, right-click on the `PrayerTimesWidget` target folder
2. Select **Add Files to "PrayerTimesWidget"...**
3. Navigate to `ios/PrayerTimesWidget/PrayerTimesWidget.swift`
4. Make sure **Copy items if needed** is checked
5. Ensure **PrayerTimesWidget** target is selected
6. Click **Add**

### Step 3: Configure App Groups

App Groups are required to share data between the main app and the widget:

1. Select the **Runner** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** and add: `group.com.hexahelix.dq`
6. Repeat for the **PrayerTimesWidget** target

### Step 4: Update Widget Info.plist

1. In the `PrayerTimesWidget` target, locate `Info.plist`
2. Replace its contents with the one from `ios/PrayerTimesWidget/Info.plist` (already created)

### Step 5: Set Deployment Target

1. Select the **PrayerTimesWidget** target
2. Go to **General** tab
3. Set **iOS Deployment Target** to **16.0** or higher (required for lock screen widgets)

### Step 6: Build and Test

1. Select the **PrayerTimesWidget** scheme
2. Build and run on a physical device (iOS 16+)
3. Long-press on the lock screen
4. Tap **Customize**
5. Add the **Prayer Times Widget**

## How It Works

1. **Flutter Side**: When prayer times are fetched, `PrayerTimesCubit` automatically calls `WidgetDataService.updatePrayerTimes()`

2. **Platform Channels**: The service communicates with native code via method channels:
   - iOS: Updates App Group UserDefaults and reloads widget timeline
   - Android: Updates SharedPreferences and refreshes all widget instances

3. **Widget Updates**:
   - iOS: Widgets update via WidgetKit timeline
   - Android: Widgets update every 30 minutes and on-demand

## Testing

To test the widgets:

1. **Android**: 
   - Add widget to home screen
   - Open app and navigate to dashboard (prayer times will load)
   - Widget should update automatically

2. **iOS**:
   - Add widget to lock screen
   - Open app and navigate to dashboard
   - Lock device and check widget shows updated prayer times

## Troubleshooting

### iOS Widget Not Showing
- Ensure App Groups are configured for both targets
- Check that deployment target is iOS 16.0+
- Verify widget extension is included in build scheme
- Test on physical device (widgets don't work in simulator)

### Android Widget Not Updating
- Check that widget is properly registered in AndroidManifest.xml
- Verify SharedPreferences are being updated (check logs)
- Try removing and re-adding the widget

### Data Not Syncing
- iOS: Verify App Group identifier matches in both targets
- Android: Check SharedPreferences key names match
- Ensure platform channel method names are correct

## Notes

- iOS widgets require iOS 16.0 or later
- Android widgets work on all Android versions that support widgets
- Widgets update automatically when prayer times are fetched in the app
- The next prayer is calculated based on current time


