import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'exceptions.dart';
import 'failures.dart';
import 'booking_exceptions.dart';
import 'booking_failures.dart';

Failure mapExceptionToFailure(Object error) {
  if (error is BookingOutcomeUnknownException) {
    return BookingOutcomeUnknownFailure(
      operationId: error.operationId,
      message: error.message,
    );
  }

  if (error is BookingLocalStorageException) {
    return BookingLocalStorageFailure(error.message);
  }

  if (error is BookingOperationException) {
    return BookingOperationFailure(error.message);
  }
  if (error is TimeoutException || error is http.ClientException) {
    return const NetworkFailure(
      'The request timed out or could not connect. Check your connection and retry.',
    );
  }
  if (error is FormatException || error is TypeError) {
    return const ServerFailure(
      'Some saved data has an invalid format. Reload or correct the record before continuing.',
    );
  }
  if (error is UnauthenticatedException) {
    return const UnauthenticatedFailure();
  }

  if (error is UserProfileNotFoundException) {
    return const ServerFailure(
      'Your account profile could not be found. Please contact support.',
    );
  }
  if (error is HotelNotFoundException) {
    return const ServerFailure(
      'This hotel could not be found. It may have been deleted.',
    );
  }
  if (error is HotelOperationException) {
    return ServerFailure(error.message);
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'network-request-failed':
        return const NetworkFailure(
          'Could not connect. Check your internet connection and try again.',
        );

      case 'invalid-email':
        return const AuthFailure('Please enter a valid email address.');

      case 'user-not-found':
        return const AuthFailure(
          'No account exists with this email. Please create an account.',
        );

      case 'wrong-password':
        return const AuthFailure(
          'Incorrect password. Try again or tap Forgot password.',
        );

      case 'invalid-credential':
        return const AuthFailure(
          'We couldn’t sign you in. Check your email and password. '
          'If you haven’t registered yet, tap Create an account.',
        );
      case 'email-already-in-use':
        return const AuthFailure('An account already uses this email address.');

      case 'weak-password':
        return const AuthFailure('Please choose a stronger password.');

      case 'too-many-requests':
        return const AuthFailure(
          'Too many attempts. Please wait and try again.',
        );

      case 'user-disabled':
        return const AuthFailure(
          'This account has been disabled. Please contact support.',
        );

      case 'requires-recent-login':
        return const AuthFailure('Please sign in again before continuing.');

      default:
        return const AuthFailure(
          'We could not complete this account action. Please try again.',
        );
    }
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return const ServerFailure(
          'You do not have permission to perform this action.',
        );

      case 'unavailable':
      case 'deadline-exceeded':
        return const ServerFailure(
          'The service could not be reached. Please try again shortly.',
        );

      default:
        return const ServerFailure(
          'We could not load or save your data. Please try again.',
        );
    }
  }

  return const UnexpectedFailure('Something went wrong. Please try again.');
}
