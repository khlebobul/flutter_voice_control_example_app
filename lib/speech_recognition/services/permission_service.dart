import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class MicrophonePermissionService {
  static MicrophonePermissionService? _instance;
  static MicrophonePermissionService get instance {
    _instance ??= MicrophonePermissionService._();
    return _instance!;
  }

  MicrophonePermissionService._();

  late final AudioRecorder _audioRecorder;

  static const String _microphonePermissionKey =
      'microphone_permission_granted';
  static const String _permissionRequestedKey =
      'microphone_permission_requested';
  static const String _lastPermissionCheckKey =
      'last_permission_check_timestamp';

  Future<void> initialize() async {
    _audioRecorder = AudioRecorder();
  }

  Future<void> _saveMicrophonePermissionState(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_microphonePermissionKey, granted);
      await prefs.setBool(_permissionRequestedKey, true);
      await prefs.setInt(
        _lastPermissionCheckKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('Microphone permission state saved: $granted');
    } catch (e) {
      debugPrint('Error saving microphone permission state: $e');
    }
  }

  Future<bool?> _getSavedMicrophonePermissionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_microphonePermissionKey);
    } catch (e) {
      debugPrint('Error getting saved microphone permission state: $e');
      return null;
    }
  }

  Future<bool> _wasPermissionRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_permissionRequestedKey) ?? false;
    } catch (e) {
      debugPrint('Error checking if permission was requested: $e');
      return false;
    }
  }

  Future<DateTime?> _getLastPermissionCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastPermissionCheckKey);
      return timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (e) {
      debugPrint('Error getting last permission check time: $e');
      return null;
    }
  }

  Future<bool> checkMicrophonePermission() async {
    try {
      final savedPermissionState = await _getSavedMicrophonePermissionState();
      final wasPermissionRequested = await _wasPermissionRequested();

      debugPrint('Saved permission state: $savedPermissionState');
      debugPrint('Permission was requested before: $wasPermissionRequested');

      if (savedPermissionState == true) {
        debugPrint('Using saved permission state: granted');
        bool hasPermission = await _audioRecorder.hasPermission();
        if (hasPermission) {
          debugPrint('Permission confirmed');
          return true;
        } else {
          debugPrint('Permission revoked, updating saved state');
          await _saveMicrophonePermissionState(false);
          return false;
        }
      }

      if (!wasPermissionRequested || savedPermissionState == false) {
        debugPrint('Requesting microphone permission...');
        bool hasPermission = await _audioRecorder.hasPermission();

        if (!hasPermission) {
          debugPrint(
            'Permission not granted, trying to trigger permission dialog...',
          );

          try {
            final dir = await getApplicationSupportDirectory();
            final path = p.join(dir.path, 'temp_audio_test.wav');
            await Directory(dir.path).create(recursive: true);
            final tempConfig = RecordConfig(
              encoder: AudioEncoder.pcm16bits,
              sampleRate: 16000,
              numChannels: 1,
            );

            await _audioRecorder.start(tempConfig, path: path);
            await Future.delayed(const Duration(milliseconds: 100));
            await _audioRecorder.stop();

            hasPermission = await _audioRecorder.hasPermission();
            debugPrint('Permission after trigger attempt: $hasPermission');
          } catch (e) {
            debugPrint('Error triggering permission dialog: $e');
            hasPermission = false;
          }
        }

        await _saveMicrophonePermissionState(hasPermission);
        return hasPermission;
      }

      return await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint('Error checking microphone permission: $e');
      return false;
    }
  }

  Future<bool> requestMicrophonePermission() async {
    try {
      debugPrint('Forcing microphone permission request...');

      await _saveMicrophonePermissionState(false);

      bool hasPermission = await _audioRecorder.hasPermission();

      if (!hasPermission) {
        try {
          final dir = await getApplicationSupportDirectory();
          final path = p.join(dir.path, 'temp_audio_test.wav');
          await Directory(dir.path).create(recursive: true);
          final tempConfig = RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          );

          await _audioRecorder.start(tempConfig, path: path);
          await Future.delayed(const Duration(milliseconds: 100));
          await _audioRecorder.stop();

          hasPermission = await _audioRecorder.hasPermission();
        } catch (e) {
          debugPrint('Error requesting permission: $e');
          hasPermission = false;
        }
      }

      await _saveMicrophonePermissionState(hasPermission);
      return hasPermission;
    } catch (e) {
      debugPrint('Error in requestMicrophonePermission: $e');
      return false;
    }
  }

  Future<void> clearSavedPermissionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_microphonePermissionKey);
      await prefs.remove(_permissionRequestedKey);
      await prefs.remove(_lastPermissionCheckKey);
      debugPrint('Saved permission state cleared');
    } catch (e) {
      debugPrint('Error clearing saved permission state: $e');
    }
  }

  Future<Map<String, dynamic>> getPermissionInfo() async {
    try {
      final savedState = await _getSavedMicrophonePermissionState();
      final wasRequested = await _wasPermissionRequested();
      final lastCheck = await _getLastPermissionCheckTime();
      final currentState = await _audioRecorder.hasPermission();

      return {
        'savedState': savedState,
        'wasRequested': wasRequested,
        'lastCheck': lastCheck?.toIso8601String(),
        'currentState': currentState,
      };
    } catch (e) {
      debugPrint('Error getting permission info: $e');
      return {};
    }
  }
}
