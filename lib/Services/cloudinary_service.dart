import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Uploads images directly to Cloudinary using an unsigned upload preset.
///
/// Mobile clients must use unsigned uploads (no API secret bundled in the
/// app); the upload preset controls what's allowed (folder, size, formats)
/// from the Cloudinary dashboard under Settings → Upload → Upload presets.
class CloudinaryService {
  CloudinaryService._();

  static const String cloudName = 't7bqibfu';
  static const String uploadPreset = 'babyshophub';

  static Uri get _uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  /// Uploads [bytes] and returns the resulting HTTPS image URL.
  /// Throws an [Exception] with a user-readable message on failure.
  static Future<String> uploadImage(
    Uint8List bytes, {
    String fileName = 'product.jpg',
    String folder = 'babyshophub/products',
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uploadUri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: fileName),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final url = data['secure_url'] as String?;
        if (url == null || url.isEmpty) {
          throw Exception('Cloudinary did not return an image URL.');
        }
        return url;
      }

      // Cloudinary returns error details as {"error": {"message": "..."}}.
      String message = 'Image upload failed (${response.statusCode}).';
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final err = body['error'];
        if (err is Map && err['message'] != null) {
          message = err['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }
}
