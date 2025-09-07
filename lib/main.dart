import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Onboarding flag load karna
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(ProviderScope(
    child: DSBooksApp(seenOnboarding: seenOnboarding),
  ));
}

class DSBooksApp extends ConsumerWidget {
  final bool seenOnboarding;
  const DSBooksApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = buildRouter(seenOnboarding);
    return MaterialApp.router(
      title: 'DS Books App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
