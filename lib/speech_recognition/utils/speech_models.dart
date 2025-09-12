import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'utils.dart';

Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig({
  required int type,
}) async {
  switch (type) {
    case 0:
      final modelDir =
          'assets/models/sherpa-onnx-streaming-zipformer-en-kroko-2025-08-06';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile('$modelDir/encoder.onnx'),
          decoder: await copyAssetFile('$modelDir/decoder.onnx'),
          joiner: await copyAssetFile('$modelDir/joiner.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );
    default:
      throw ArgumentError('Unsupported type: $type');
  }
}
