import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tala_trip_app/features/auth/data/data_sources/firebase_user_data_source.dart';
import 'package:tala_trip_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tala_trip_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:tala_trip_app/features/auth/presentation/pages/sign_up_page.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TalaApp());
}

class TalaApp extends StatelessWidget {
  const TalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSource = FirebaseUserDataSource(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
    );

    final repository = AuthRepositoryImpl(dataSource);
    final signUp = SignUp(repository);

    return MaterialApp(
      title: 'TALA Trip',
      debugShowCheckedModeBanner: false,
      home: SignUpPage(signUp: signUp),
    );
  }
}
