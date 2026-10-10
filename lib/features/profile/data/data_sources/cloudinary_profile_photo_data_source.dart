import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/errors/exceptions.dart';
import 'profile_photo_data_source.dart';

class CloudinaryProfilePhotoDataSource implements ProfilePhotoDataSource {
  final http.Client _client;
  final String _cloudName;
  final String _uploadPreset;

  CloudinaryProfilePhotoDataSource({
    required this._client,
    required this._cloudName,
    required this._uploadPreset,
  });

  @override
  Future<String> uploadPhoto({required String filePath}) async {
    if (_cloudName.trim().isEmpty || _uploadPreset.trim().isEmpty) {
      throw const ProfileOperationException(
        'Photo uploads are not configured yet.',
      );
    }

    try {
      final file = File(filePath);
      final length = await file.length();

      if (length == 0 || length > 5 * 1024 * 1024) {
        throw const ProfileOperationException(
          'Choose a non-empty photo no larger than 5 MB.',
        );
      }

      final uri = Uri.https(
        'api.cloudinary.com',
        '/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await (() async {
        final streamedResponse = await _client.send(request);
        return http.Response.fromStream(streamedResponse);
      })().timeout(const Duration(seconds: 60));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ProfileOperationException(
          'Could not upload your photo. Please try again.',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const ProfileOperationException(
          'The photo service returned an invalid response.',
        );
      }

      final url = decoded['secure_url'];

      if (url is! String || !_isValidPhotoUrl(url)) {
        throw const ProfileOperationException(
          'Could not read the uploaded photo address. Please try again.',
        );
      }

      return url;
    } on FileSystemException {
      throw const ProfileOperationException(
        'This photo is no longer available. Select it again.',
      );
    } on TimeoutException {
      throw const ProfileOperationException(
        'The photo upload took too long. Check your connection and retry.',
      );
    } on SocketException {
      throw const ProfileOperationException(
        'Could not connect to the photo service. Check your connection.',
      );
    } on http.ClientException {
      throw const ProfileOperationException(
        'The photo upload was interrupted. Please try again.',
      );
    } on FormatException {
      throw const ProfileOperationException(
        'The photo service returned an unreadable response.',
      );
    }
  }

  bool _isValidPhotoUrl(String value) {
    final uri = Uri.tryParse(value);

    return value.length <= 2048 &&
        uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'res.cloudinary.com' &&
        uri.pathSegments.isNotEmpty;
  }
}
