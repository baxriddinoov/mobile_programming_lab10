import 'package:flutter_test/flutter_test.dart';
import 'package:tm_classifier/services/classifier.dart';

void main() {
  group('parseLabels', () {
    test('normal case: newline-separated indexed labels', () {
      const raw = '0 Mug\n1 Bottle\n';
      final labels = parseLabels(raw);
      expect(labels, equals(['Mug', 'Bottle']));
    });

    test('awkward case: Windows line endings, trailing blank line, and label with space', () {
      const raw = "0 Mug\r\n1 Bottle\r\n2 Car keys\r\n\r\n";
      final labels = parseLabels(raw);
      expect(labels, equals(['Mug', 'Bottle', 'Car keys']));
    });
  });
}
