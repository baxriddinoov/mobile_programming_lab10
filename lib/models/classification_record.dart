import 'dart:typed_data';
import 'package:tm_classifier/services/classifier.dart';

class ClassificationRecord {
  ClassificationRecord({
    required this.imageBytes,
    required this.predictions,
    required this.source,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final Uint8List imageBytes;
  final List<Prediction> predictions;
  final String source; // 'Camera', 'Gallery', 'Download'
  final DateTime timestamp;

  Prediction get topPrediction => predictions.isNotEmpty
      ? predictions.first
      : const Prediction('Unknown', 0.0);
}
