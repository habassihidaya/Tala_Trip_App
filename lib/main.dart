import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection_container.dart';
import 'core/routes/app_router.dart';
import 'core/routes/router_refresh_notifier.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  setupDependencies();

  runApp(const TalaApp());
}

class TalaApp extends StatefulWidget {
  const TalaApp({super.key});

  @override
  State<TalaApp> createState() => _TalaAppState();
}

class _TalaAppState extends State<TalaApp> {
  late final AuthBloc _authBloc;
  late final RouterRefreshNotifier _refreshNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _authBloc = getIt<AuthBloc>();

    _refreshNotifier = RouterRefreshNotifier(_authBloc.stream);

    _router = createAppRouter(
      authBloc: _authBloc,
      refreshNotifier: _refreshNotifier,
    );

    
  }

  @override
  void dispose() {
    _router.dispose();
    _refreshNotifier.dispose();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'TALA Trip',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}

