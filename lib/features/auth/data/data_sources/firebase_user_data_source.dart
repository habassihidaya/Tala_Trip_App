import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tala_trip_app/core/errors/exceptions.dart';
import 'package:tala_trip_app/features/auth/data/data_sources/user_data_source.dart';
import 'package:tala_trip_app/features/auth/data/models/user_model.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';

class FirebaseUserDataSource implements UserDataSource {
  FirebaseUserDataSource(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<UserModel> signUp({
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
    required UserRole role,
  }) async {
    // Public registration allows only travelers and hotel owners.
    if (role != UserRole.traveler && role != UserRole.hotelOwner) {
      throw ArgumentError('Invalid role for registration.');
    }

    final normalizedEmail = email.trim();
    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') rethrow;
      // A previous attempt may have created Auth but not the profile.
      // Require the password again; an email address alone is never enough.
      credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    }

    final user = credential.user;
    if (user == null) throw const UnauthenticatedException();

    final model = UserModel(
      id: user.uid,
      username: username.trim(),
      email: user.email ?? normalizedEmail,
      mobileNumber: mobileNumber,
      role: role,
    );
    final reference = _firestore.collection('users').doc(user.uid);

    try {
      // Read from the server and create only if absent. Repeated attempts cannot
      // overwrite an existing profile, even after an uncertain first result.
      return await _firestore.runTransaction<UserModel>((transaction) async {
        final snapshot = await transaction.get(reference);
        if (_auth.currentUser?.uid != user.uid) {
          throw const UnauthenticatedException();
        }
        final existing = snapshot.data();
        if (existing != null) {
          return UserModel.fromJson({...existing, 'id': user.uid});
        }
        transaction.set(reference, model.toJson());
        return model;
      });
    } on FirebaseException {
      // Keep the Auth account. A transaction failure is not proof that a write
      // did not commit, so retry using the same credentials and check again.
      throw const UserProfileSetupPendingException();
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);

    return getUser();
  }

  @override
  Future<UserModel> getUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const UnauthenticatedException();
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));

    final profile = snapshot.data();
    if (profile == null) {
      throw const UserProfileNotFoundException();
    }

    return UserModel.fromJson({...profile, 'id': user.uid});
  }

  @override
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() => _auth.signOut();
  @override
  Stream<String?> authStateChanges() {
    return _auth.authStateChanges().map((user) => user?.uid);
  }
}
