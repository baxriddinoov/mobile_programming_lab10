import 'package:flutter/material.dart';
import 'package:tm_classifier/services/classifier.dart';

class ModelScreen extends StatelessWidget {
  const ModelScreen({
    super.key,
    required this.classifier,
  });

  final Classifier classifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Metadata & Info'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Model Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.memory_rounded, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            'TensorFlow Lite Model',
                            style: textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _infoRow(context, 'Model File', 'assets/model/model_unquant.tflite'),
                      _infoRow(context, 'Input Tensor Dimensions', '${Classifier.inputSize} × ${Classifier.inputSize} × 3'),
                      _infoRow(context, 'Input Normalization', 'Float32 [-1.0, 1.0]'),
                      _infoRow(context, 'Number of Classes', '${classifier.labels.length} classes'),
                      _infoRow(context, 'Runtime Engine', 'tflite_flutter (On-Device C-API)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Labels Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.label_outline_rounded, color: colorScheme.secondary),
                          const SizedBox(width: 10),
                          Text(
                            'Parsed Labels (labels.txt)',
                            style: textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: classifier.labels.asMap().entries.map((entry) {
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              child: Text(
                                '${entry.key}',
                                style: textTheme.labelSmall?.copyWith(color: Colors.white),
                              ),
                            ),
                            label: Text(entry.value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Design Credit Card (T14)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_outlined, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Design Credit & Attribution',
                            style: textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'UI Kit: Mobile UI kit (Community)',
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Author: Figma Community Contributors',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Link: figma.com/design/9Z32ejEoHgFCi3pN7cnCsi',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'License: Creative Commons Attribution 4.0 (CC BY 4.0)',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reference Frames: docs/design-1.png & docs/design-2.png',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String title, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyMedium),
          Text(value, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
