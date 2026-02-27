import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HabitDuelApp()));
}

class HabitDuelApp extends ConsumerStatefulWidget {
  const HabitDuelApp({super.key});

  @override
  ConsumerState<HabitDuelApp> createState() => _HabitDuelAppState();
}

class _HabitDuelAppState extends ConsumerState<HabitDuelApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Check for persisted session on app launch.
    Future.microtask(
      () => ref.read(authProvider.notifier).checkSession(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes and redirect accordingly.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is Authenticated) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home',
          (_) => false,
        );
      } else if (next is Unauthenticated) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (_) => false,
        );
      }
    });

    return MaterialApp(
      title: 'HabitDuel',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        // Home placeholder — will be implemented in Week 2
        '/home': (_) => const _HomePlaceholder(),
      },
    );
  }
}

/// Temporary home screen placeholder until Week 2.
class _HomePlaceholder extends ConsumerWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitDuel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to HabitDuel!\nHome screen coming in Week 2.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
