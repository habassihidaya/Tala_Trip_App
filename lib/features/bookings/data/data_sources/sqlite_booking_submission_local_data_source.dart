import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/booking_submission_model.dart';
import 'booking_submission_local_data_source.dart';

class SqliteBookingSubmissionLocalDataSource
    implements BookingSubmissionLocalDataSource {
  final Database _database;

  SqliteBookingSubmissionLocalDataSource(this._database);

  // Open the local database and create its table on first use.
  static Future<SqliteBookingSubmissionLocalDataSource> open() async {
    final directory = await getDatabasesPath();

    final database = await openDatabase(
      p.join(directory, 'tala_booking_submissions.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE booking_submissions (
            traveler_id TEXT NOT NULL,
            request_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            PRIMARY KEY (traveler_id, request_id)
          )
        ''');
      },
    );

    return SqliteBookingSubmissionLocalDataSource(database);
  }

  @override
  Future<void> saveSubmission(
    BookingSubmissionModel submission,
  ) async {
    final entity = submission.toEntity();

    _requireNonEmpty(entity.travelerId);
    _requireNonEmpty(entity.requestId);

    final payload = jsonEncode(submission.toJson());

    await _database.transaction((transaction) async {
      final existing = await transaction.query(
        'booking_submissions',
        where: 'traveler_id = ? AND request_id = ?',
        whereArgs: [
          entity.travelerId,
          entity.requestId,
        ],
      );

      if (existing.isNotEmpty) {
        final saved = _readRow(existing.single);

        if (saved.toEntity() != entity) {
          throw StateError(
            'This request ID already belongs to different booking details.',
          );
        }

        // The identical submission is already safely recorded.
        return;
      }

      await transaction.insert(
        'booking_submissions',
        {
          'traveler_id': entity.travelerId,
          'request_id': entity.requestId,
          'payload': payload,
        },
      );
    });
  }

  @override
  Future<List<BookingSubmissionModel>> getSubmissions(
    String travelerId,
  ) async {
    _requireNonEmpty(travelerId);

    final rows = await _database.query(
      'booking_submissions',
      where: 'traveler_id = ?',
      whereArgs: [travelerId],
      orderBy: 'request_id ASC',
    );

    return rows.map(_readRow).toList(growable: false);
  }

  @override
  Future<void> removeSubmission({
    required String travelerId,
    required String requestId,
  }) async {
    _requireNonEmpty(travelerId);
    _requireNonEmpty(requestId);

    await _database.delete(
      'booking_submissions',
      where: 'traveler_id = ? AND request_id = ?',
      whereArgs: [
        travelerId,
        requestId,
      ],
    );
  }

  static BookingSubmissionModel _readRow(
    Map<String, Object?> row,
  ) {
    final payload = row['payload'];

    if (payload is! String) {
      throw const FormatException(
        'The saved booking submission is unreadable.',
      );
    }

    final decoded = jsonDecode(payload);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'The saved booking submission has an invalid format.',
      );
    }

    final model = BookingSubmissionModel.fromJson(decoded);
    final entity = model.toEntity();

    if (entity.travelerId != row['traveler_id'] ||
        entity.requestId != row['request_id']) {
      throw const FormatException(
        'The saved booking submission identifiers do not match.',
      );
    }

    return model;
  }

  static void _requireNonEmpty(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('A booking submission identifier is missing.');
    }
  }

  Future<void> close() => _database.close();
}