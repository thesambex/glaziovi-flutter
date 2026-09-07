import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glaziovi/database/database_provider.dart';
import 'package:glaziovi/features/activity-recorder/activity_recorder_page.dart';
import 'package:glaziovi/features/home/home_page.dart';
import 'package:glaziovi/l10n/app_localizations.dart';
import 'package:glaziovi/l10n/l10n_providers.dart';
import 'package:glaziovi/navigation/app_route_observer.dart';
import 'package:glaziovi/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: App()));
}

final _router = GoRouter(
  initialLocation: '/',
  observers: [appRouteObserver],
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const HomePage(),
      routes: [
        GoRoute(
          path: '/activity-recorder',
          builder: (_, _) => const ActivityRecorderPage(),
        ),
      ],
    ),
  ],
);

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  // TODO: Create splash screen while dependencies are initializing
  Future<void> _bootstrap() async {
    try {
      await _loadDependencies();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load app dependencies',
        name: 'glaziovi.app.bootstrap',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadDependencies() async {
    await ref.read(databaseProvider.future);
  }

  // TODO: Create application theme

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Glaziovi',
      routerConfig: _router,
      theme: theme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
        ...GlobalCupertinoLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(appLocaleProvider),
    );
  }
}
