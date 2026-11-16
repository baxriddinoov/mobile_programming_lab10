import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageSources {
  final ImagePicker _picker = ImagePicker();

  /// Captures an image from the camera with maxWidth 1024 to optimize decoding speed.
  /// Returns null if user cancels.
  Future<Uint8List?> fromCamera() async {
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
    );
    return shot == null ? null : await shot.readAsBytes();
  }

  /// Selects an image from the device photo gallery.
  /// Returns null if user cancels.
  Future<Uint8List?> fromGallery() async {
    final pick = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    return pick == null ? null : await pick.readAsBytes();
  }

  /// Downloads an image from a web URL.
  /// Enforces HTTP 200 and image/* content-type validation.
  /// Throws descriptive user-friendly exceptions for timeouts, invalid URLs, and non-image responses.
  Future<Uint8List> fromUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('URL address cannot be empty');
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('Invalid image URL. Must start with http:// or https://');
    }

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw FormatException(
          'Failed to download image: Server returned HTTP ${response.statusCode}',
        );
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      if (!contentType.startsWith('image/')) {
        throw FormatException(
          'Target URL returned a web page or file ($contentType) instead of an image.',
        );
      }

      if (response.bodyBytes.isEmpty) {
        throw const FormatException('Downloaded image file was empty');
      }

      return response.bodyBytes;
    } on TimeoutException {
      throw const FormatException('Download timed out. Check your connection or try another URL.');
    } on http.ClientException catch (e) {
      throw FormatException('Network connection error: ${e.message}');
    }
  }
}
