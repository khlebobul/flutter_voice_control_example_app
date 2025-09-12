import 'package:flutter/material.dart';
import '../services/speech_recognition_service.dart';

class SpeechRecognitionWidget extends StatefulWidget {
  const SpeechRecognitionWidget({super.key});

  @override
  State<SpeechRecognitionWidget> createState() =>
      _SpeechRecognitionWidgetState();
}

class _SpeechRecognitionWidgetState extends State<SpeechRecognitionWidget> {
  late final SpeechRecognitionService _speechService;

  String _text = '';
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _speechService = SpeechRecognitionService.instance;

    _speechService.initialize().then((_) {
      setState(() {});
    });

    _speechService.textStream.listen((t) {
      setState(() {
        _text = t;
      });
    });

    _speechService.recordingStateStream.listen((isRec) {
      setState(() {
        _isRecording = isRec;
      });
    });
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_speechService.isRecording) {
      await _speechService.stopRecording();
    } else {
      await _speechService.startRecording();
    }
  }

  void _clearText() {
    setState(() {
      _text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                reverse: true,
                child: SelectableText(
                  _text,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _toggle,
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      label: Text(_isRecording ? 'Stop' : 'Record'),
                      style: const ButtonStyle(
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _text.isNotEmpty ? _clearText : null,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      style: const ButtonStyle(
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
