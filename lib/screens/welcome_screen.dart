import 'package:flutter/material.dart';
import 'package:tm_classifier/services/classifier.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.classifier,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onGetStarted,
  });

  final Classifier? classifier;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.remove_red_eye_rounded,
                    size: 44,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Vision Classifier',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Recognises daily desktop objects locally on your phone using an on-device TensorFlow Lite neural network.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              if (isLoading) ...[
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Loading on-device model tensors...',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ] else if (errorMessage != null) ...[
                Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.error),
                        const SizedBox(height: 8),
                        Text(
                          'Model Loading Error',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: onRetry,
                          child: const Text('Retry Loading'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (classifier != null) ...[
                Text(
                  'Recognisable Classes:',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: classifier!.labels.map((label) {
                    return Chip(
                      label: Text(label),
                      avatar: Icon(
                        label.toLowerCase().contains('desk') || label.toLowerCase().contains('empty')
                            ? Icons.crop_free
                            : Icons.check_circle_outline,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: (isLoading || classifier == null) ? null : onGetStarted,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
