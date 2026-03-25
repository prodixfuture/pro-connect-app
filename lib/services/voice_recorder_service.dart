import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

/// Voice recording service for audio messages
/// Handles recording, playback, and file management
class VoiceRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  Duration _recordDuration = Duration.zero;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  Duration get recordDuration => _recordDuration;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Request microphone permission
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting microphone permission: $e');
      }
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking microphone permission: $e');
      }
      return false;
    }
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Check permission
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          if (kDebugMode) {
            print('Microphone permission denied');
          }
          return false;
        }
      }

      // Check if already recording
      if (_isRecording) {
        if (kDebugMode) {
          print('Already recording');
        }
        return false;
      }

      // Get temporary directory for recording
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_message_$timestamp.m4a';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordDuration = Duration.zero;

      if (kDebugMode) {
        print('Recording started: $_currentRecordingPath');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting recording: $e');
      }
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        if (kDebugMode) {
          print('Not recording');
        }
        return null;
      }

      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path != null && await File(path).exists()) {
        if (kDebugMode) {
          print('Recording stopped: $path');
        }
        return path;
      } else {
        if (kDebugMode) {
          print('Recording file not found');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping recording: $e');
      }
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;
      }

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          if (kDebugMode) {
            print('Recording cancelled and deleted');
          }
        }
        _currentRecordingPath = null;
      }

      _recordDuration = Duration.zero;
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling recording: $e');
      }
    }
  }

  /// Play audio from file path
  Future<void> playAudio(String path) async {
    try {
      if (_isPlaying) {
        await stopPlayback();
      }

      await _audioPlayer.play(DeviceFileSource(path));
      _isPlaying = true;

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });

      if (kDebugMode) {
        print('Playing audio: $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing audio: $e');
      }
      _isPlaying = false;
    }
  }

  /// Stop audio playback
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      if (kDebugMode) {
        print('Playback stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping playback: $e');
      }
    }
  }

  /// Pause audio playback
  Future<void> pausePlayback() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
      if (kDebugMode) {
        print('Playback paused');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error pausing playback: $e');
      }
    }
  }

  /// Resume audio playback
  Future<void> resumePlayback() async {
    try {
      await _audioPlayer.resume();
      _isPlaying = true;
      if (kDebugMode) {
        print('Playback resumed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resuming playback: $e');
      }
    }
  }

  /// Get audio duration
  Future<Duration?> getAudioDuration(String path) async {
    try {
      await _audioPlayer.setSourceDeviceFile(path);
      final duration = await _audioPlayer.getDuration();
      return duration;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting audio duration: $e');
      }
      return null;
    }
  }

  /// Format duration for display (MM:SS)
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Get file size in KB
  Future<double> getFileSizeKB(String path) async {
    try {
      final file = File(path);
      final bytes = await file.length();
      return bytes / 1024; // Convert to KB
    } catch (e) {
      if (kDebugMode) {
        print('Error getting file size: $e');
      }
      return 0;
    }
  }

  /// Delete audio file
  Future<bool> deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print('Audio file deleted: $path');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting audio file: $e');
      }
      return false;
    }
  }

  /// Update recording duration (call this in a timer)
  void updateRecordDuration(Duration duration) {
    _recordDuration = duration;
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
      }
      if (_isPlaying) {
        await _audioPlayer.stop();
      }
      await _audioRecorder.dispose();
      await _audioPlayer.dispose();

      if (kDebugMode) {
        print('VoiceRecorderService disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing VoiceRecorderService: $e');
      }
    }
  }

  /// Check if recording is supported on this platform
  Future<bool> isRecordingSupported() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking recording support: $e');
      }
      return false;
    }
  }

  /// Get recording amplitude (for visual feedback)
  Stream<double> getAmplitudeStream() {
    // This would require additional implementation with the record package
    // For now, return a dummy stream
    return Stream.periodic(
      const Duration(milliseconds: 100),
      (count) => 0.5, // Placeholder amplitude value
    );
  }
}
