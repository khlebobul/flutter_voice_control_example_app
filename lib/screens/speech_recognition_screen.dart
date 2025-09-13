import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../speech_recognition/services/speech_recognition_service.dart';
import '../speech_recognition/services/voice_command_service.dart';
import '../speech_recognition/utils/commands.dart';
import '../speech_recognition/widgets/text_display_widget.dart';
import '../speech_recognition/widgets/control_buttons_widget.dart';
import '../speech_recognition/widgets/confetti_overlay_widget.dart';

class SpeechRecognitionScreen extends StatefulWidget {
  const SpeechRecognitionScreen({super.key});

  @override
  State<SpeechRecognitionScreen> createState() =>
      _SpeechRecognitionScreenState();
}

class _SpeechRecognitionScreenState extends State<SpeechRecognitionScreen> {
  late final SpeechRecognitionService _speechService;
  late final VoiceCommandService _voiceCommandService;
  late final ConfettiController _confettiController;

  String _text = '';
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _speechService = SpeechRecognitionService.instance;
    _voiceCommandService = VoiceCommandService.instance;
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _speechService.initialize().then((_) {
      setState(() {});
    });

    _speechService.textStream.listen((t) {
      setState(() {
        _text = t;
      });
      _voiceCommandService.processRecognizedText(t);
    });

    _speechService.recordingStateStream.listen((isRec) {
      setState(() {
        _isRecording = isRec;
      });
    });

    for (final command in confettiCommands) {
      _voiceCommandService.registerCommand(command, _triggerConfetti);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_speechService.isRecording) {
      await _speechService.stopRecording();
    } else {
      await _speechService.startRecording();
    }
  }

  void _clearText() {
    _speechService.clearText();
    setState(() {
      _text = '';
    });
  }

  void _triggerConfetti() {
    if (_confettiController.state == ConfettiControllerState.playing) {
      _confettiController.stop();
    }
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                TextDisplayWidget(text: _text),
                ControlButtonsWidget(
                  isRecording: _isRecording,
                  hasText: _text.isNotEmpty,
                  onToggleRecording: _toggleRecording,
                  onClearText: _clearText,
                ),
              ],
            ),
          ),
          ConfettiOverlayWidget(confettiController: _confettiController),
        ],
      ),
    );
  }
}

