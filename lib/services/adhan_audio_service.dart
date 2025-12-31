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
          print('Playing azan from assets/audio/azan.mp3');
        }
      } catch (assetError) {
        if (kDebugMode) {
          print('Could not play azan from assets, using fallback: $assetError');
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
        print('Azan audio started playing');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing azan audio: $e');
      }
      // Fallback: just log the error without crashing
    }
  }

  /// Play specific azan for a particular prayer time
  Future<void> playAdhanForPrayer(String prayerName) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] AdhanAudioService: playAdhanForPrayer called with $prayerName');
    
    try {
      // Stop any currently playing audio
      await stopAdhan();
      print('[$timestamp] AdhanAudioService: Stopped any existing audio');
      
      // Create new audio player
      _audioPlayer = AudioPlayer();
      print('[$timestamp] AdhanAudioService: Created new AudioPlayer');
      
      // Set audio session for better compatibility
      await _audioPlayer!.setReleaseMode(ReleaseMode.stop);
      print('[$timestamp] AdhanAudioService: Set release mode to stop');
      
      // Determine which azan file to play based on prayer
      String audioFile = 'audio/azan.mp3'; // Default azan for most prayers
      
      // Only Fajr uses the special azan_fajr.mp3
      if (prayerName.toLowerCase() == 'fajr') {
        audioFile = 'audio/azan_fajr.mp3';
      }
      
      print('[$timestamp] AdhanAudioService: Attempting to play $audioFile for prayer $prayerName');
      
      // Verify audio file exists by attempting to play it
      // Play the appropriate azan
      try {
        await _audioPlayer!.play(AssetSource(audioFile));
        print('[$timestamp] AdhanAudioService: ✅ Successfully started playing $audioFile');
        
        if (kDebugMode) {
          print('[$timestamp] AdhanAudioService: Playing $audioFile for $prayerName');
        }
      } catch (assetError) {
        print('[$timestamp] AdhanAudioService: ❌ Error playing $audioFile: $assetError');
        if (kDebugMode) {
          print('[$timestamp] AdhanAudioService: Could not play $audioFile, using default azan: $assetError');
        }
        
        // Fallback to default azan
        try {
          print('[$timestamp] AdhanAudioService: Trying fallback to default azan (audio/azan.mp3)');
          await _audioPlayer!.play(AssetSource('audio/azan.mp3'));
          print('[$timestamp] AdhanAudioService: ✅ Fallback azan started successfully');
        } catch (defaultError) {
          print('[$timestamp] AdhanAudioService: ❌ Fallback azan also failed: $defaultError');
          if (kDebugMode) {
            print('[$timestamp] AdhanAudioService: Could not play default azan either: $defaultError');
            print('[$timestamp] AdhanAudioService: Audio files may be missing from assets/audio/');
          }
          await _createSimpleAdhanTone();
        }
      }
      
      _isPlaying = true;
      print('[$timestamp] AdhanAudioService: Set _isPlaying to true');
      
      // Auto-stop after 15 seconds (typical azan duration)
      Future.delayed(const Duration(seconds: 15), () {
        final stopTimestamp = DateTime.now().toIso8601String();
        print('[$stopTimestamp] AdhanAudioService: Auto-stopping after 15 seconds');
        stopAdhan();
      });
      
      if (kDebugMode) {
        print('[$timestamp] AdhanAudioService: ✅ Azan audio for $prayerName started playing successfully');
      }
    } catch (e, stackTrace) {
      final errorTimestamp = DateTime.now().toIso8601String();
      print('[$errorTimestamp] AdhanAudioService: ❌ Error in playAdhanForPrayer: $e');
      if (kDebugMode) {
        print('[$errorTimestamp] AdhanAudioService: Stack trace: $stackTrace');
        print('[$errorTimestamp] AdhanAudioService: Error playing azan audio for $prayerName: $e');
      }
    }
  }

  /// Create a simple azan-like tone using frequency
  Future<void> _createSimpleAdhanTone() async {
    try {
      // This is a placeholder - in a real app, you'd use actual azan audio
      // For now, we'll just log that we're using fallback
      if (kDebugMode) {
        print('Using fallback azan tone (silent)');
      }
      
      // In a real implementation, you could use:
      // - A simple beep sound
      // - A downloaded azan file
      // - Text-to-speech for azan
      
    } catch (e) {
      if (kDebugMode) {
        print('Error creating fallback azan tone: $e');
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
            print('AdhanAudioService: Stopped playing audio');
          }
        }
        await _audioPlayer!.dispose();
        _audioPlayer = null;
        _isPlaying = false;
        
        if (kDebugMode) {
          print('AdhanAudioService: Audio player disposed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AdhanAudioService: Error stopping azan audio: $e');
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
