import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glaziovi/features/home/home_view.dart';
import 'package:go_router/go_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: App()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [GoRoute(path: '/', builder: (_, _) => const HomeView())],
);

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();

    _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'Glaziovi', routerConfig: _router);
  }

  Future<void> _bootstrap() async {
    await _loadDependencies();
  }

  Future<void> _loadDependencies() async {}
}
