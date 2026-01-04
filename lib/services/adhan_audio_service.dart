import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AdhanAudioService {
  static final AdhanAudioService _instance = AdhanAudioService._internal();
  factory AdhanAudioService() => _instance;
  AdhanAudioService._internal();

  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;

  /// Play azan sound when prayer times are loaded
  Future<void> playAdhan() async {
    try {
      // Stop any currently playing audio
      await stopAdhan();
      
      // Create new audio player
      _audioPlayer = AudioPlayer();
      
      // Set audio session for better compatibility
      await _audioPlayer!.setReleaseMode(ReleaseMode.stop);
      
      // Play default azan from assets
      try {
        await _audioPlayer!.play(AssetSource('audio/azan.mp3'));
        
        if (kDebugMode) {
        }
      } catch (assetError) {
        if (kDebugMode) {
        }
        
        // Fallback: create a simple beep sound using frequency
        // This is a basic implementation - you should replace with actual azan audio
        await _createSimpleAdhanTone();
      }
      
      _isPlaying = true;
      
      // Auto-stop after 15 seconds (typical azan duration)
      Future.delayed(const Duration(seconds: 15), () {
        stopAdhan();
      });
      
      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
      // Fallback: just log the error without crashing
    }
  }

  /// Play specific azan for a particular prayer time
  Future<void> playAdhanForPrayer(String prayerName) async {
    final timestamp = DateTime.now().toIso8601String();
    
    try {
      // Stop any currently playing audio
      await stopAdhan();
      
      // Create new audio player
      _audioPlayer = AudioPlayer();
      
      // Set audio session for better compatibility
      await _audioPlayer!.setReleaseMode(ReleaseMode.stop);
      
      // Determine which azan file to play based on prayer
      String audioFile = 'audio/azan.mp3'; // Default azan for most prayers
      
      // Only Fajr uses the special azan_fajr.mp3
      if (prayerName.toLowerCase() == 'fajr') {
        audioFile = 'audio/azan_fajr.mp3';
      }
      
      
      // Verify audio file exists by attempting to play it
      // Play the appropriate azan
      try {
        await _audioPlayer!.play(AssetSource(audioFile));
        
        if (kDebugMode) {
        }
      } catch (assetError) {
        if (kDebugMode) {
        }
        
        // Fallback to default azan
        try {
          await _audioPlayer!.play(AssetSource('audio/azan.mp3'));
        } catch (defaultError) {
          if (kDebugMode) {
          }
          await _createSimpleAdhanTone();
        }
      }
      
      _isPlaying = true;
      
      // Auto-stop after 15 seconds (typical azan duration)
      Future.delayed(const Duration(seconds: 15), () {
        final stopTimestamp = DateTime.now().toIso8601String();
        stopAdhan();
      });
      
      if (kDebugMode) {
      }
    } catch (e, stackTrace) {
      final errorTimestamp = DateTime.now().toIso8601String();
      if (kDebugMode) {
      }
    }
  }

  /// Create a simple azan-like tone using frequency
  Future<void> _createSimpleAdhanTone() async {
    try {
      // This is a placeholder - in a real app, you'd use actual azan audio
      // For now, we'll just log that we're using fallback
      if (kDebugMode) {
      }
      
      // In a real implementation, you could use:
      // - A simple beep sound
      // - A downloaded azan file
      // - Text-to-speech for azan
      
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Stop azan audio
  Future<void> stopAdhan() async {
    try {
      if (_audioPlayer != null) {
        if (_isPlaying) {
          await _audioPlayer!.stop();
          if (kDebugMode) {
          }
        }
        await _audioPlayer!.dispose();
        _audioPlayer = null;
        _isPlaying = false;
        
        if (kDebugMode) {
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Check if azan is currently playing
  bool get isPlaying => _isPlaying;

  /// Dispose resources
  void dispose() {
    stopAdhan();
  }
}
