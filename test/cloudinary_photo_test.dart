import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tala_trip_app/core/errors/exceptions.dart';
import 'package:tala_trip_app/features/hotels/data/data_sources/cloudinary_hotel_photo_data_source.dart';

void main() {
  late Directory temporary;
  late File photo;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('tala-photo-test-');
    photo = await File(
      '${temporary.path}/photo.jpg',
    ).writeAsBytes([255, 216, 255, 217]);
  });
  tearDown(() async => temporary.delete(recursive: true));

  CloudinaryHotelPhotoDataSource source(http.Client client) =>
      CloudinaryHotelPhotoDataSource(
        client: client,
        cloudName: 'test-cloud',
        uploadPreset: 'test-preset',
      );

  test('photo upload validates the remote URL', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1_1/test-cloud/image/upload');
      return http.Response(
        '{"secure_url":"https://res.cloudinary.com/test/image/upload/photo.jpg"}',
        200,
      );
    });
    addTearDown(client.close);
    expect(
      await source(client).uploadPhoto(photo.path),
      'https://res.cloudinary.com/test/image/upload/photo.jpg',
    );
  });
  test('successful HTTP response with unsafe URL is rejected', () async {
    final client = MockClient(
      (_) async =>
          http.Response('{"secure_url":"file:///private/photo.jpg"}', 200),
    );
    addTearDown(client.close);
    await expectLater(
      source(client).uploadPhoto(photo.path),
      throwsA(isA<HotelOperationException>()),
    );
  });
  test('missing photo fails before making a request', () async {
    final client = MockClient(
      (_) async => throw StateError('Network must not be called'),
    );
    addTearDown(client.close);
    await expectLater(
      source(client).uploadPhoto('${temporary.path}/missing.jpg'),
      throwsA(isA<HotelOperationException>()),
    );
  });
}
