# Flutter Voice Control Example App

<div align="center">

An application demonstrating local speech recognition and voice command control on Flutter using Sherpa-ONNX.

<video controls width="600">
  <source src="assets/demo_recordings/voice_control.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

</div>

## How Speech Recognition Works

// TODO Medium article link

### Initialization
```dart
// Creating recognizer
_recognizer = await _createOnlineRecognizer();
_stream = _recognizer?.createStream();
```

### Audio Recording
```dart
// Recording configuration
const config = RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: 16000,
  numChannels: 1,
  bitRate: 128000,
);
```

### Audio Stream Processing
```dart
// Convert bytes to float32
final samplesFloat32 = convertBytesToFloat32(data);
// Pass to model
_stream!.acceptWaveform(samples: samplesFloat32, sampleRate: _sampleRate);
// Decoding
while (_recognizer!.isReady(_stream!)) {
  _recognizer!.decode(_stream!);
}
```

### Getting Results
```dart
final result = _recognizer!.getResult(_stream!);
final text = _normalizeRecognizedText(result.text);
```

## Voice Command System

### Command Registration
```dart
// Register command with action
_voiceCommandService.registerCommand('confetti', _triggerConfetti);
```

### Command Processing
```dart
void processRecognizedText(String text) {
  // Search for commands in recognized text
  for (final commandEntry in _commands.entries) {
    if (_containsCommand(latestLine, command)) {
      action(); // Execute action
    }
  }
}
```

### Automatic Model Installation with Makefile

```
assets/models/
└── sherpa-onnx-streaming-zipformer-en-kroko-2025-08-06/
    ├── encoder.onnx          # Audio encoder
    ├── decoder.onnx          # Text decoder
    ├── joiner.onnx           # Joining layer
    └── tokens.txt            # Token vocabulary
```

The project includes a Makefile for automating installation and running:

```bash
make install-model
```

## Performance

| Feature | Sherpa-ONNX | Whisper | Vosk |
|---------|-------------|---------|------|
| **Latency** | ~100-300ms | ~500-2000ms | ~200-500ms |
| **Memory Usage** | ~50-100MB | ~1-3GB | ~100-500MB |
| **Model Size** | ~50MB | ~290MB-3GB | ~50-200MB |
| **Accuracy** | High | Very High | Good |
| **Streaming** | ✅ Real-time | ❌ Batch only | ✅ Real-time |
| **Offline** | ✅ Fully offline | ✅ Fully offline | ✅ Fully offline |
| **Languages** | Multiple | 99+ languages | Multiple |
| **Platform Support** | Mobile/Desktop | Desktop/Server | Mobile/Desktop |
| **Setup Complexity** | Medium | Easy | Medium |

## Useful Links

- [Sherpa-ONNX Documentation](https://github.com/k2-fsa/sherpa-onnx)
- [Confetti Package](https://pub.dev/packages/confetti)
- [Example](https://k2-fsa.github.io/sherpa/onnx/flutter/pre-built-app.html#streaming-speech-recognition-stt-asr)
- [sherpa_onnx package](https://pub.dev/packages/sherpa_onnx)
- [streaming_asr](https://github.com/k2-fsa/sherpa-onnx/tree/master/flutter-examples/streaming_asr)
- [Models](https://github.com/k2-fsa/sherpa-onnx/releases)

## Contacts

[![@khlebobul](https://img.shields.io/badge/@khlebobul-414141?style=for-the-badge&logo=X&logoColor=F1F1F1)](https://x.com/khlebobul) [![Email - khlebobul@gmail.com](https://img.shields.io/badge/Email-khlebobul%40gmail.com-414141?style=for-the-badge&logo=Email&logoColor=F1F1F1)](mailto:khlebobul@gmail.com) [![@khlebobul](https://img.shields.io/badge/%40khlebobul-414141?style=for-the-badge&logo=Telegram&logoColor=F1F1F1)](https://t.me/khlebobul) [![Personal - Website](https://img.shields.io/badge/Personal-Website-414141?style=for-the-badge&logo=Personal&logoColor=F1F1F1)](https://khlebobul.github.io/)

## License

[![LICENCE - MIT](https://img.shields.io/badge/LICENCE-MIT-414141?style=for-the-badge&logo=Licence&logoColor=F1F1F1)](https://github.com/khlebobul/flutter_voice_control_example_app/blob/main/LICENSE)

