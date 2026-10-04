import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:tala_trip_app/core/errors/exceptions.dart';

import 'hotel_photo_data_source.dart';

class CloudinaryHotelPhotoDataSource implements HotelPhotoDataSource {
  final http.Client _client;
  final String _cloudName;
  final String _uploadPreset;

 CloudinaryHotelPhotoDataSource({
  required this._client,
  required this._cloudName,
  required this._uploadPreset,
});

  @override
  Future<String> uploadPhoto(String filePath) async {
    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$_cloudName/image/upload',
    );

    // A multipart request carries the photo and text fields.
    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = _uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath('file', filePath),
    );

    final response = await (() async {
      final streamedResponse = await _client.send(request);
      return http.Response.fromStream(streamedResponse);
    })().timeout(const Duration(seconds: 60));

    // Show the HTTP status in VS Code's Debug Console.
    if (kDebugMode) {
      debugPrint('Cloudinary upload status: ${response.statusCode}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Show Cloudinary's actual error to diagnose the failure.
      if (kDebugMode) {
        debugPrint('Cloudinary upload error: ${response.body}');
      }

      throw const HotelOperationException(
        'Could not upload the photo. Please try again.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const HotelOperationException(
        'The photo service returned an invalid response.',
      );
    }

    final url = decoded['secure_url'];

    if (url is! String || url.isEmpty) {
      throw const HotelOperationException(
        'The photo was uploaded, but its URL was missing.',
      );
    }

    return url;
  }
}