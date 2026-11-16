import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tm_classifier/models/classification_record.dart';
import 'package:tm_classifier/screens/result_screen.dart';
import 'package:tm_classifier/services/classifier.dart';
import 'package:tm_classifier/services/image_sources.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.classifier,
    required this.onRecordAdded,
    this.mostRecentRecord,
  });

  final Classifier classifier;
  final ValueChanged<ClassificationRecord> onRecordAdded;
  final ClassificationRecord? mostRecentRecord;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImageSources _imageSources = ImageSources();
  bool _isProcessing = false;
  String _processingStatus = '';

  Future<void> _processImageBytes(Uint8List? bytes, String source) async {
    if (bytes == null) {
      // User cancelled camera/gallery - stays where it is
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Classifying with TensorFlow Lite...';
    });

    try {
      final predictions = widget.classifier.classify(bytes);
      final record = ClassificationRecord(
        imageBytes: bytes,
        predictions: predictions,
        source: source,
      );

      widget.onRecordAdded(record);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(record: record),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog('Classification Failed', e.toString());
      }
    }
  }

  Future<void> _handleCamera() async {
    try {
      final bytes = await _imageSources.fromCamera();
      await _processImageBytes(bytes, 'Camera');
    } catch (e) {
      _showErrorDialog('Camera Error', e.toString());
    }
  }

  Future<void> _handleGallery() async {
    try {
      final bytes = await _imageSources.fromGallery();
      await _processImageBytes(bytes, 'Gallery');
    } catch (e) {
      _showErrorDialog('Gallery Error', e.toString());
    }
  }

  Future<void> _handleDownload() async {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Text('Download Image', style: theme.textTheme.titleMedium),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter a direct web address for an image (e.g. JPG, PNG):',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: textController,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/photo.jpg',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a URL';
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'Must begin with http:// or https://';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, textController.text.trim());
                }
              },
              child: const Text('Download & Classify'),
            ),
          ],
        );
      },
    );

    if (url == null || url.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Downloading image from web...';
    });

    try {
      final bytes = await _imageSources.fromUrl(url);
      await _processImageBytes(bytes, 'Download');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog('Download Error', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          icon: Icon(Icons.error_outline, color: theme.colorScheme.error),
          title: Text(title, style: theme.textTheme.titleMedium),
          content: Text(message, style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vision Classifier'),
      ),
      body: SafeArea(
        child: _isProcessing
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 20),
                      Text(
                        _processingStatus,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Processing image pixels...',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Input Sources',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose how you want to provide an image to the model:',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // Action 1: Take a photo
                    _ActionCard(
                      title: 'Take a Photo',
                      subtitle: 'Capture an object using your phone camera',
                      icon: Icons.camera_alt_outlined,
                      accentColor: colorScheme.primary,
                      onTap: _handleCamera,
                    ),
                    const SizedBox(height: 12),

                    // Action 2: Choose from gallery
                    _ActionCard(
                      title: 'Choose from Gallery',
                      subtitle: 'Select an existing photo or screenshot',
                      icon: Icons.photo_library_outlined,
                      accentColor: colorScheme.secondary,
                      onTap: _handleGallery,
                    ),
                    const SizedBox(height: 12),

                    // Action 3: Download an image
                    _ActionCard(
                      title: 'Download an Image',
                      subtitle: 'Fetch and classify an image directly from a URL',
                      icon: Icons.cloud_download_outlined,
                      accentColor: colorScheme.primary,
                      onTap: _handleDownload,
                    ),
                    const SizedBox(height: 24),

                    // Most recent result (if there is one)
                    Text(
                      'Recent Classification',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),

                    if (widget.mostRecentRecord != null) ...[
                      Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultScreen(
                                  record: widget.mostRecentRecord!,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: colorScheme.outline),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.memory(
                                    widget.mostRecentRecord!.imageBytes,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.mostRecentRecord!.topPrediction.label,
                                        style: textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Top confidence: ${(widget.mostRecentRecord!.topPrediction.confidence * 100).toStringAsFixed(1)} %',
                                        style: textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Source: ${widget.mostRecentRecord!.source}',
                                        style: textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 16, color: colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.image_search_rounded,
                                  size: 36,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No recent classifications yet',
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
