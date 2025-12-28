# Android Lock Screen Notification Implementation

## Overview

This implementation provides a lock-screen "widget-like" experience using Android notifications, fully compatible with Android 8-14. Instead of using deprecated lock-screen widgets (removed in Android 5+), we use persistent, high-priority notifications that appear on the lock screen.

## Why Notifications Instead of Widgets?

1. **Classic lock-screen widgets were deprecated** in Android 5.0+ and completely removed
2. **Modern Android (8+)** uses notification-based lock screen content as the official approach
3. **Notifications work consistently** across all Android versions (8-14) and OEMs (Samsung, Xiaomi, etc.)
4. **No special permissions** or OEM-specific hacks required
5. **Official Android API** - supported and maintained by Google

## Architecture

```
┌─────────────────────────────────────────┐
│         LockScreenNotificationService    │
│  - Initializes notification plugin       │
│  - Creates high-priority channel         │
│  - Shows/updates persistent notification│
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│    Android Notification System          │
│  - Displays on lock screen              │
│  - Persistent (ongoing: true)           │
│  - Public visibility                    │
└─────────────────────────────────────────┘
```

## Implementation Details

### 1. Android Configuration

**AndroidManifest.xml** has been updated with:

```xml
<application
    android:showWhenLocked="true"
    android:turnScreenOn="true">
```

- `android:showWhenLocked="true"`: Allows app content to be shown when device is locked
- `android:turnScreenOn="true"`: Allows app to turn screen on (for notification visibility)

**Permissions** (already present):
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 2. Notification Channel

Created a dedicated channel with:
- **ID**: `lock_screen_quran_channel`
- **Importance**: `max` (highest priority)
- **Visibility**: `public` (content visible on lock screen, not hidden by privacy)
- **Category**: `service` (indicates persistent service notification)
- **Ongoing**: `true` (persistent, cannot be swiped away)

### 3. Service Implementation

**File**: `lib/services/lock_screen_notification_service.dart`

Key features:
- Singleton pattern for easy access
- Automatic permission handling (Android 13+)
- Support for Arabic text (RTL)
- BigTextStyle for expanded content
- Persistent notifications that survive app kill

### 4. Usage Examples

#### Basic Usage

```dart
import 'services/lock_screen_notification_service.dart';

// Show notification
await LockScreenNotificationService().showLockScreenNotification(
  title: 'Quran Reminder',
  body: 'Translation text here',
  expandedText: 'Arabic verse\n\nTranslation\n\nSurah name',
);

// Update notification
await LockScreenNotificationService().updateLockScreenNotification(
  title: 'New Title',
  body: 'New body',
);

// Dismiss notification
await LockScreenNotificationService().dismissLockScreenNotification();
```

#### Integration with Daily Verse

See `lib/services/lock_screen_notification_example.dart` for complete examples including:
- Showing daily Quran verses
- Updating verses periodically
- Scheduling updates

## File Structure

```
lib/
├── services/
│   ├── lock_screen_notification_service.dart      # Main service
│   └── lock_screen_notification_example.dart      # Usage examples
├── main.dart                                      # Service initialization
└── ...

android/app/src/main/
├── AndroidManifest.xml                            # Updated with lock screen config
└── ...
```

## Key Methods

### `initialize()`
Initializes the service, requests permissions, and creates the notification channel. Called once in `main.dart`.

### `showLockScreenNotification()`
Shows or updates the lock screen notification with:
- `title`: Notification title
- `body`: Main notification text
- `expandedText`: Optional expanded text (for BigTextStyle)
- `openAppOnTap`: Whether tapping opens the app (default: true)

### `updateLockScreenNotification()`
Updates existing notification content (more efficient than showing new).

### `dismissLockScreenNotification()`
Removes the notification from lock screen.

### `isNotificationShowing()`
Checks if notification is currently active.

## Runtime Behavior

The notification:
- ✅ Appears on lock screen even when device is locked
- ✅ Persists until manually dismissed or updated
- ✅ Survives app being killed
- ✅ Opens app when tapped
- ✅ Supports Arabic text with proper RTL rendering
- ✅ Works on Android 8-14
- ✅ Compatible with all OEMs (Samsung, Xiaomi, etc.)

## Testing

1. **Request Permission**: On first run, Android 13+ will request notification permission
2. **Show Notification**: Call `showLockScreenNotification()` with test data
3. **Lock Device**: Lock your device and verify notification appears
4. **Test Persistence**: Kill the app and verify notification remains
5. **Test Tap**: Tap notification to verify app opens

## Best Practices

1. **Initialize Early**: Initialize in `main()` before `runApp()`
2. **Request Permission**: Service automatically requests permission, but user can deny
3. **Update, Don't Replace**: Use `updateLockScreenNotification()` for frequent updates
4. **Provide Expanded Text**: Use `expandedText` for long Arabic verses
5. **Handle Errors**: Wrap calls in try-catch for production

## Limitations

1. **User Can Dismiss**: Users can dismiss the notification (though `ongoing: true` prevents swipe)
2. **Battery Optimization**: Some OEMs may restrict notifications if battery optimization is enabled
3. **Privacy Settings**: Users can hide notification content in privacy settings (though we use `public` visibility)
4. **Android Version**: Requires Android 8.0+ (API 26+) for notification channels

## Future Enhancements

- Schedule daily verse updates automatically
- Support multiple notification styles
- Add action buttons (e.g., "Read Full Surah")
- Integrate with prayer times for automatic updates
- Support custom notification layouts

## Troubleshooting

**Notification not appearing on lock screen:**
1. Check notification permission is granted
2. Verify notification channel importance is `max`
3. Check device lock screen settings allow notifications
4. Ensure `android:showWhenLocked="true"` is in manifest

**Notification disappears:**
1. Check if battery optimization is enabled for the app
2. Verify `ongoing: true` is set in notification details
3. Check if user manually dismissed it

**Arabic text not rendering correctly:**
1. Ensure `htmlFormatBigText: false` (plain text supports Arabic)
2. Verify device supports RTL text rendering
3. Check font support for Arabic characters

## References

- [Android Notification Channels](https://developer.android.com/training/notify-user/channels)
- [Lock Screen Visibility](https://developer.android.com/training/notify-user/build-notification#lockscreen)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

