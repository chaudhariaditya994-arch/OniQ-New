import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DiagnosisService {
  static const List<String> classNames = [
    'Alternaria',
    'Bulb_Blight',
    'Caterpillar',
    'Fusarium',
    'Healthy',
    'Virosis',
  ];

  static const int imgSize = 224;
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      // Copy asset to local file, then load from file path
      final dir = await getApplicationDocumentsDirectory();
      final modelPath = '${dir.path}/onion_model.tflite';
      final modelFile = File(modelPath);

      if (!await modelFile.exists()) {
        final data = await rootBundle.load('assets/models/onion_model.tflite');
        await modelFile.writeAsBytes(data.buffer.asUint8List());
      }

      _interpreter = Interpreter.fromFile(modelFile);
    } catch (e) {
      throw Exception('Failed to load TFLite model: $e');
    }
  }

  Future<Map<String, dynamic>> classifyImage(File imageFile) async {
    if (_interpreter == null) {
      await loadModel();
    }

    // Read and preprocess image
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    final resized = img.copyResize(image, width: imgSize, height: imgSize);

    // Create input tensor [1, 224, 224, 3] normalized to [-1, 1]
    var input = List.generate(
      1,
      (_) => List.generate(
        imgSize,
        (y) => List.generate(
          imgSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.rNormalized * 2.0 - 1.0, // R normalized to [-1, 1]
              pixel.gNormalized * 2.0 - 1.0, // G normalized to [-1, 1]
              pixel.bNormalized * 2.0 - 1.0, // B normalized to [-1, 1]
            ];
          },
        ),
      ),
    );

    // Output tensor [1, 6]
    var output = List.generate(1, (_) => List.filled(classNames.length, 0.0));

    _interpreter!.run(input, output);

    // Find best prediction
    final predictions = output[0];
    int maxIdx = 0;
    double maxVal = predictions[0];
    for (int i = 1; i < predictions.length; i++) {
      if (predictions[i] > maxVal) {
        maxVal = predictions[i];
        maxIdx = i;
      }
    }

    return {
      'class_name': classNames[maxIdx],
      'confidence': (maxVal * 100).toDouble(),
      'all_predictions': {
        for (int i = 0; i < classNames.length; i++)
          classNames[i]: (predictions[i] * 100).toDouble(),
      },
    };
  }

  void dispose() {
    _interpreter?.close();
  }
}
