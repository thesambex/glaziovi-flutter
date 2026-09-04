import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glaziovi/features/activity-recorder/activity_recorder_page.dart';
import 'package:glaziovi/features/home/home_page.dart';
import 'package:glaziovi/l10n/app_localizations.dart';
import 'package:glaziovi/l10n/l10n_providers.dart';
import 'package:go_router/go_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: App()));
}

final _router = GoRouter(
  initialLocation: '/',
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

    _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Glaziovi',
      routerConfig: _router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
        ...GlobalCupertinoLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(appLocaleProvider),
    );
  }

  Future<void> _bootstrap() async {
    await _loadDependencies();
  }

  Future<void> _loadDependencies() async {}
}
