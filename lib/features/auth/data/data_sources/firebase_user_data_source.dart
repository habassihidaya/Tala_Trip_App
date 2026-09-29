import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tala_trip_app/features/auth/data/data_sources/user_data_source.dart';
import 'package:tala_trip_app/features/auth/data/models/user_model.dart';

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
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw StateError('Account creation did not return a user.');
    }

    final model = UserModel(
      id: user.uid,
      username: username,
      email: email,
      mobileNumber: mobileNumber,
    );

    await _firestore.collection('users').doc(user.uid).set(model.toJson());
    return model;
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return getUser();
  }

  @override
  Future<UserModel> getUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No user is signed in.');
    }

    final snapshot =
        await _firestore.collection('users').doc(user.uid).get();

    final profile = snapshot.data();
    if (profile == null) {
      throw StateError('User profile was not found.');
    }

    return UserModel.fromJson({
      ...profile,
      'id': user.uid,
    });
  }
  @override
Future<void> sendVerificationEmail() async {
  final user = _auth.currentUser;

  if (user == null) {
    throw StateError('No user is signed in.');
  }

  if (!user.emailVerified) {
    await user.sendEmailVerification();
  }
}

@override
Future<bool> isEmailVerified() async {
  final user = _auth.currentUser;

  if (user == null) {
    throw StateError('No user is signed in.');
  }

  await user.reload();
  return _auth.currentUser?.emailVerified ?? false;
}

  @override
  Future<void> signOut() => _auth.signOut();
}
