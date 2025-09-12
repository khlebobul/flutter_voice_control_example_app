import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import '../utils/utils.dart';
import '../utils/speech_models.dart';
import 'permission_service.dart';

class SpeechRecognitionService {
  static SpeechRecognitionService? _instance;
  static SpeechRecognitionService get instance {
    _instance ??= SpeechRecognitionService._();
    return _instance!;
  }

  SpeechRecognitionService._();

  late final AudioRecorder _audioRecorder;
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;

  bool _isInitialized = false;
  bool _isRecording = false;
  final int _sampleRate = 16000;
  String _lastRecognizedText = '';

  StreamSubscription<RecordState>? _recordSub;

  final StreamController<String> _textController =
      StreamController<String>.broadcast();
  final StreamController<bool> _recordingStateController =
      StreamController<bool>.broadcast();

  Stream<String> get textStream => _textController.stream;
  Stream<bool> get recordingStateStream => _recordingStateController.stream;
  bool get isRecording => _isRecording;
  String get lastRecognizedText => _lastRecognizedText;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // debugPrint('Initializing SpeechRecognitionService...');
      _audioRecorder = AudioRecorder();

      _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
        // debugPrint('Record state changed: $recordState');
      });

      // debugPrint('Initializing sherpa_onnx bindings...');
      sherpa_onnx.initBindings();

      // debugPrint('Creating online recognizer...');
      _recognizer = await _createOnlineRecognizer();

      // debugPrint('Creating stream...');
      _stream = _recognizer?.createStream();

      // Initialize microphone permission service
      await MicrophonePermissionService.instance.initialize();

      _isInitialized = true;
      _isRecording = false;
      // debugPrint('SpeechRecognitionService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SpeechRecognitionService: $e');
      rethrow;
    }
  }

  Future<sherpa_onnx.OnlineRecognizer> _createOnlineRecognizer() async {
    final type = 0;

    final modelConfig = await getOnlineModelConfig(type: type);
    final config = sherpa_onnx.OnlineRecognizerConfig(
      model: modelConfig,
      ruleFsts: '',
    );

    return sherpa_onnx.OnlineRecognizer(config);
  }

  Future<bool> startRecording() async {
    // debugPrint('Starting recording...');
    if (!_isInitialized) {
      debugPrint('Not initialized, initializing now...');
      await initialize();
    }

    if (_isRecording) {
      debugPrint('Already recording, returning false');
      return false;
    }

    try {
      debugPrint('Checking audio permission...');

      debugPrint('Checking microphone permission...');
      bool hasPermission = await MicrophonePermissionService.instance
          .checkMicrophonePermission();
      debugPrint('Permission check result: $hasPermission');

      if (hasPermission) {
        debugPrint('Permission granted');
        const encoder = AudioEncoder.pcm16bits;

        debugPrint('Checking encoder support...');
        if (!await _isEncoderSupported(encoder)) {
          debugPrint('PCM16 encoder not supported');
          return false;
        }
        debugPrint('Encoder supported');

        const config = RecordConfig(
          encoder: encoder,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 128000,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        );
        debugPrint(
          'Record config created: sampleRate=16000, channels=1, bitRate=128000',
        );

        debugPrint('Starting audio stream...');

        final devices = await _audioRecorder.listInputDevices();
        debugPrint('Available input devices: $devices');

        final stream = await _audioRecorder.startStream(config);
        debugPrint('Audio stream started successfully');

        _isRecording = true;
        _recordingStateController.add(true);
        debugPrint('Recording state updated to true');

        stream.listen(
          (data) {
            // debugPrint('Received audio data: ${data.length} bytes');
            if (data.isNotEmpty) {
              // debugPrint('Audio data is not empty, processing...');
              _processAudioData(Uint8List.fromList(data));
            } else {
              // debugPrint('Received empty audio data');
            }
          },
          onDone: () {
            debugPrint('Audio stream stopped');
          },
          onError: (error) {
            debugPrint('Audio stream error: $error');
          },
        );

        debugPrint('Recording started successfully');
        return true;
      } else {
        debugPrint('Audio recording permission not granted');
        return false;
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _isRecording = false;
      _recordingStateController.add(false);
      return false;
    }
  }

  void _processAudioData(Uint8List data) {
    if (!_isInitialized || _stream == null || _recognizer == null) {
      debugPrint(
        'Speech recognition not initialized or stream/recognizer is null',
      );
      return;
    }

    try {
      // debugPrint('Processing audio data: ${data.length} bytes');
      final samplesFloat32 = convertBytesToFloat32(data);
      // debugPrint('Converted to ${samplesFloat32.length} float samples');

      _stream!.acceptWaveform(samples: samplesFloat32, sampleRate: _sampleRate);
      // debugPrint('Waveform accepted');

      while (_recognizer!.isReady(_stream!)) {
        _recognizer!.decode(_stream!);
        // debugPrint('Decoded chunk');
      }

      final result = _recognizer!.getResult(_stream!);
      final rawText = result.text;
      final text = _normalizeRecognizedText(rawText);
      // debugPrint('Recognition result: "$text"');

      String textToDisplay = _lastRecognizedText;
      if (text.isNotEmpty) {
        if (_lastRecognizedText.isEmpty) {
          textToDisplay = text; // first entry, no numbering
        } else {
          // Show newest at the bottom, older on top, without numbering
          textToDisplay = '$_lastRecognizedText\n$text';
        }
        // debugPrint('Updated display text: "$textToDisplay"');
      }

      if (_recognizer!.isEndpoint(_stream!)) {
        // debugPrint('Endpoint detected, resetting stream');
        _recognizer!.reset(_stream!);
        if (text.isNotEmpty) {
          _lastRecognizedText = textToDisplay;
        }
      }

      if (textToDisplay != _lastRecognizedText ||
          _recognizer!.isEndpoint(_stream!)) {
        _textController.add(textToDisplay);
      }
    } catch (e) {
      debugPrint('Error processing audio data: $e');
    }
  }

  String _normalizeRecognizedText(String text) {
    var t = text;
    // Replace special word-boundary markers if present
    t = t.replaceAll('▁', ' ');
    // Remove leading hyphens and surrounding spaces at start
    t = t.replaceFirst(RegExp(r'^\s*-+\s*'), '');
    // Replace occurrences of space-hyphen-space with a single space when likely spurious
    t = t.replaceAll(RegExp(r'\s*-\s+'), ' ');
    // Collapse multiple spaces
    t = t.replaceAll(RegExp(r'\s{2,}'), ' ');
    // Trim
    t = t.trim();
    return t;
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      await _audioRecorder.stop();
      _isRecording = false;
      _recordingStateController.add(false);

      if (_stream != null && _recognizer != null) {
        _stream!.free();
        _stream = _recognizer!.createStream();
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> pauseRecording() async {
    if (_isRecording) {
      await _audioRecorder.pause();
    }
  }

  Future<void> resumeRecording() async {
    if (_isRecording) {
      await _audioRecorder.resume();
    }
  }

  void clearText() {
    _lastRecognizedText = '';
    _textController.add('');
  }

  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await _audioRecorder.isEncoderSupported(encoder);

    if (!isSupported) {
      debugPrint('${encoder.name} is not supported on this platform.');
      debugPrint('Supported encoders are:');

      for (final e in AudioEncoder.values) {
        if (await _audioRecorder.isEncoderSupported(e)) {
          debugPrint('- ${e.name}');
        }
      }
    }

    return isSupported;
  }

  void dispose() {
    _recordSub?.cancel();
    _audioRecorder.dispose();
    _stream?.free();
    _recognizer?.free();
    _textController.close();
    _recordingStateController.close();
    _isInitialized = false;
  }
}
