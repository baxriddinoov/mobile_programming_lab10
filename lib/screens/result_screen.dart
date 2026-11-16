import 'package:flutter/material.dart';
import 'package:tm_classifier/models/classification_record.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.record,
  });

  final ClassificationRecord record;

  IconData _sourceIcon(String source) {
    switch (source.toLowerCase()) {
      case 'camera':
        return Icons.camera_alt_outlined;
      case 'gallery':
        return Icons.photo_library_outlined;
      case 'download':
        return Icons.cloud_download_outlined;
      default:
        return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final maxImageHeight = mediaQuery.size.height * 0.42;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classification Result'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              avatar: Icon(_sourceIcon(record.source), size: 16, color: colorScheme.primary),
              label: Text(record.source),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Center Image: horizontally centred, uncropped (BoxFit.contain), max half screen
              Center(
                child: Container(
                  constraints: BoxConstraints(maxHeight: maxImageHeight),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    record.imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Class Probabilities',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              // 2. Below the image, one row for every label from labels.txt
              // 3. Rows are sorted highest to lowest, top row visually emphasised
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: record.predictions.length,
                    separatorBuilder: (context, index) => Divider(
                      color: colorScheme.outline,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final pred = record.predictions[index];
                      final isTop = index == 0;
                      final percentage = (pred.confidence * 100).toStringAsFixed(1);

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: isTop ? colorScheme.primaryContainer : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (isTop) ...[
                                      Icon(
                                        Icons.stars_rounded,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      pred.label,
                                      style: isTop
                                          ? textTheme.titleMedium?.copyWith(
                                              color: colorScheme.onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                            )
                                          : textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                                Text(
                                  '$percentage %',
                                  style: isTop
                                      ? textTheme.titleMedium?.copyWith(
                                          color: colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        )
                                      : textTheme.labelLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pred.confidence.clamp(0.0, 1.0),
                                minHeight: isTop ? 10 : 6,
                                color: isTop ? colorScheme.primary : colorScheme.secondary,
                                backgroundColor: isTop
                                    ? colorScheme.outlineVariant
                                    : colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
}
