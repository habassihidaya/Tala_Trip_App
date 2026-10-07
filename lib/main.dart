import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_assets.dart';
import 'core/di/injection_container.dart';
import 'core/routes/app_router.dart';
import 'core/routes/router_refresh_notifier.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'features/onboarding/presentation/bloc/onboarding_event.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await setupDependencies();

  // Keep the native launch screen until splash images are ready.
  WidgetsBinding.instance.deferFirstFrame();

  runApp(const TalaApp());
}

class TalaApp extends StatefulWidget {
  const TalaApp({super.key});

  @override
  State<TalaApp> createState() => _TalaAppState();
}

class _TalaAppState extends State<TalaApp> {
  late final AuthBloc _authBloc;
  late final OnboardingBloc _onboardingBloc;
  late final RouterRefreshNotifier _refreshNotifier;
  late final GoRouter _router;

  Timer? _splashTimer;
  bool _splashReady = false;
  bool _preloadingStarted = false;

  @override
  void initState() {
    super.initState();

    _authBloc = getIt<AuthBloc>();
    _onboardingBloc = getIt<OnboardingBloc>();

    _refreshNotifier = RouterRefreshNotifier(
      _authBloc.stream,
      additionalStreams: [_onboardingBloc.stream],
    );

    _router = createAppRouter(
      authBloc: _authBloc,
      onboardingBloc: _onboardingBloc,
      refreshNotifier: _refreshNotifier,
      isSplashReady: () => _splashReady,
    );

    _onboardingBloc.add(const OnboardingCheckRequested());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_preloadingStarted) return;
    _preloadingStarted = true;

    unawaited(_prepareSplash());
  }

  Future<void> _prepareSplash() async {
    try {
      await Future.wait([
        precacheImage(
          const AssetImage(AppAssets.splash),
          context,
          onError: (error, stackTrace) {
            debugPrint('Splash preload failed: $error');
          },
        ),
        precacheImage(
          const AssetImage(AppAssets.logo),
          context,
          onError: (error, stackTrace) {
            debugPrint('Logo preload failed: $error');
          },
        ),
      ]);
    } finally {
      // Release the first frame even if image loading fails.
      WidgetsBinding.instance.allowFirstFrame();
    }

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Keep the splash visible for at least two seconds.
      _splashTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;

        _splashReady = true;
        _router.refresh();
      });
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _router.dispose();
    _refreshNotifier.dispose();
    unawaited(_onboardingBloc.close());
    unawaited(_authBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<OnboardingBloc>.value(value: _onboardingBloc),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'TALA Trip',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
