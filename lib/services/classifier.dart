import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Prediction {
  const Prediction(this.label, this.confidence);
  final String label;
  final double confidence; // 0.0 to 1.0
}

/// "0 Mug\n1 Bottle\n" becomes ['Mug', 'Bottle']. Pure, so it is unit-testable.
List<String> parseLabels(String raw) => [
      for (final line in raw.split('\n'))
        if (line.trim().isNotEmpty)
          line.trim().replaceFirst(RegExp(r'^\d+\s+'), ''),
    ];

class Classifier {
  Classifier._(this._interpreter, this.labels, {this.modelPath = 'assets/model/model_unquant.tflite'});

  final Interpreter _interpreter;
  final List<String> labels;
  final String modelPath;
  static const int inputSize = 224;

  static Future<Classifier> load({
    String modelPath = 'assets/model/model_unquant.tflite',
    String labelsPath = 'assets/model/labels.txt',
  }) async {
    try {
      final interpreter = await Interpreter.fromAsset(modelPath);
      final rawLabels = await rootBundle.loadString(labelsPath);
      final labels = parseLabels(rawLabels);
      if (labels.isEmpty) {
        throw const FormatException('Labels file is empty or corrupted');
      }
      return Classifier._(interpreter, labels, modelPath: modelPath);
    } catch (e) {
      throw Exception(
        'Failed to load model from "$modelPath" or labels from "$labelsPath": $e',
      );
    }
  }

  List<Prediction> classify(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('Image data is empty');
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Not a readable image file or corrupted format');
    }

    final oriented = img.bakeOrientation(decoded);
    final square = img.copyResizeCropSquare(oriented, size: inputSize);

    final input = [
      List.generate(inputSize, (y) => List.generate(inputSize, (x) {
        final p = square.getPixel(x, y);
        return [
          p.r / 127.5 - 1,
          p.g / 127.5 - 1,
          p.b / 127.5 - 1,
        ];
      })),
    ];

    final output = [List<double>.filled(labels.length, 0.0)];
    _interpreter.run(input, output);

    final predictions = <Prediction>[];
    for (var i = 0; i < labels.length; i++) {
      predictions.add(Prediction(labels[i], output.first[i]));
    }

    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions;
  }

  void close() {
    _interpreter.close();
  }
}
