# Adhan Audio Setup Guide

## Overview
The prayer times widget now includes automatic adhan sound playback when prayer times are loaded. This guide explains how to set up proper adhan audio files.

## Current Implementation
- The app automatically plays adhan sound when prayer times are first loaded
- A manual play button (volume icon) is available for testing
- Uses device notification sound as a fallback

## Setting Up Real Adhan Audio

### 1. Create Assets Folder
Create the following folder structure in your project:
```
assets/
  audio/
    adhan.mp3
    adhan_fajr.mp3
    adhan_dhuhr.mp3
    adhan_asr.mp3
    adhan_maghrib.mp3
    adhan_isha.mp3
```

### 2. Update pubspec.yaml
Add the audio assets to your `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/audio/
```

### 3. Update AdhanAudioService
Modify `lib/services/adhan_audio_service.dart` to use your audio files:

```dart
// Replace the fallback code with:
await _audioPlayer!.play(AssetSource('audio/adhan.mp3'));

// Or for specific prayer times:
String audioFile = 'audio/adhan.mp3';
if (prayerName == 'Fajr') {
  audioFile = 'audio/adhan_fajr.mp3';
}
await _audioPlayer!.play(AssetSource(audioFile));
```

### 4. Audio File Requirements
- **Format**: MP3 (recommended) or WAV
- **Duration**: 10-30 seconds (typical adhan length)
- **Quality**: 128kbps or higher for good sound quality
- **Size**: Keep under 2MB per file for app size optimization

### 5. Legal Considerations
- Ensure you have rights to use the adhan audio
- Consider using royalty-free or properly licensed audio
- Some adhan recordings may have copyright restrictions

## Testing
1. Run `flutter pub get` after adding assets
2. The adhan will play automatically when prayer times load
3. Use the volume button to test manually
4. Check console logs for any audio errors

## Troubleshooting
- **No Sound**: Check device volume and audio permissions
- **File Not Found**: Verify asset path in pubspec.yaml
- **Permission Issues**: Ensure audio permissions are granted
- **Platform Issues**: Test on both Android and iOS

## Future Enhancements
- Different adhan styles (Hanafi, Shafi'i, etc.)
- Customizable adhan volume
- Adhan for specific prayer times
- User preference settings for adhan
- Background adhan playback
