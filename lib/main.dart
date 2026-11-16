import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tm_classifier/screens/main_navigation_shell.dart';
import 'package:tm_classifier/screens/welcome_screen.dart';
import 'package:tm_classifier/services/classifier.dart';
import 'package:tm_classifier/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TmClassifierApp());
}

class TmClassifierApp extends StatefulWidget {
  const TmClassifierApp({super.key});

  @override
  State<TmClassifierApp> createState() => _TmClassifierAppState();
}

class _TmClassifierAppState extends State<TmClassifierApp> {
  Classifier? _classifier;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final classifier = await Classifier.load(
        modelPath: 'assets/model/model_unquant.tflite',
        labelsPath: 'assets/model/labels.txt',
      );

      // T10 Smoke Test on start-up
      await _runSmokeTest(classifier);

      if (mounted) {
        setState(() {
          _classifier = classifier;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// T10 Smoke test: Classify sample.jpg and debugPrint percentages
  Future<void> _runSmokeTest(Classifier classifier) async {
    try {
      final sampleBytes = (await rootBundle.load('assets/model/sample.jpg')).buffer.asUint8List();
      final predictions = classifier.classify(sampleBytes);

      debugPrint('=== [T10 SMOKE TEST START] ===');
      debugPrint('Total classes: ${predictions.length}');
      double totalConfidence = 0.0;
      for (final p in predictions) {
        final pct = (p.confidence * 100).toStringAsFixed(1);
        debugPrint('  ${p.label.padRight(14)}: $pct %');
        totalConfidence += p.confidence;
      }
      debugPrint('Sum of confidences: ${totalConfidence.toStringAsFixed(3)} (Expected: ~1.000)');
      debugPrint('Top predicted class: ${predictions.first.label} (${(predictions.first.confidence * 100).toStringAsFixed(1)}%)');
      debugPrint('=== [T10 SMOKE TEST COMPLETE] ===');
    } catch (e) {
      debugPrint('Smoke test failed: $e');
    }
  }

  @override
  void dispose() {
    // T11: Close classifier when app shuts down
    _classifier?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vision Classifier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _hasStarted && _classifier != null
          ? MainNavigationShell(classifier: _classifier!)
          : WelcomeScreen(
              classifier: _classifier,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              onRetry: _initializeClassifier,
              onGetStarted: () {
                setState(() {
                  _hasStarted = true;
                });
              },
            ),
    );
  }
}
