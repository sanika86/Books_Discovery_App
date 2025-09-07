import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/analytics/presentation/analytics_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/verification_page.dart';
import '../features/contacts/presentation/contacts_page.dart';
import '../features/home/model/home_model.dart';
import '../features/home/presentation/home_page.dart';
import '../features/home/provider/search_provider.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/profile/presentation/profile_page.dart';

GoRouter buildRouter(bool seenOnboardingInitial) {
  return GoRouter(
    initialLocation: seenOnboardingInitial ? '/login' : '/onboarding',
    redirect: (context, state) async {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

      final loggingIn = state.matchedLocation == '/login';
      final registering = state.matchedLocation == '/register';
      final onboarding = state.matchedLocation == '/onboarding';

      if (!seenOnboarding && !onboarding) {
        return '/onboarding';
      }

      if (!isLoggedIn && !loggingIn && !registering && !onboarding) {
        return '/login';
      }

      if (isLoggedIn && (loggingIn || registering || onboarding)) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/verification',
        name: 'verification',
        builder: (context, state) => const VerificationPage(),
      ),

      // Main App with Tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            TabsScaffold(navigationShell: navShell),
        branches: [
          // Home Branch with stacked navigation
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomePage(),
              routes: [
                // Book Detail Page (stacked on Home)
                GoRoute(
                  path: 'book-detail',
                  name: 'book-detail',
                  builder: (context, state) {
                    final book = state.extra as Book;
                    return BookDetailPage(book: book);
                  },
                ),
                // Search Filter Page (stacked on Home)
                GoRoute(
                  path: 'search-filter',
                  name: 'search-filter',
                  builder: (context, state) => const SearchFilterPage(),
                ),
              ],
            ),
          ]),

          // Analytics Branch
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/analytics',
              name: 'analytics',
              builder: (context, state) => const AnalyticsPage(),
            ),
          ]),

          // Search Branch (placeholder for now)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/search',
              name: 'search',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Search Tab')),
              ),
            ),
          ]),

          // Contacts Branch with stacked navigation
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/contacts',
              name: 'contacts',
              builder: (context, state) => const ContactsPage(),
            ),
          ]),

          // Profile Branch
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ]),
        ],
      ),
    ],
  );
}

// ✅ Updated TabsScaffold with Riverpod support
class TabsScaffold extends ConsumerStatefulWidget {
  const TabsScaffold({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<TabsScaffold> createState() => _TabsScaffoldState();
}

class _TabsScaffoldState extends ConsumerState<TabsScaffold> {
  int get _currentIndex => widget.navigationShell.currentIndex;

  void _onTap(int index) {
    if (index == 2) {
      // Search tab index
      widget.navigationShell.goBranch(0, initialLocation: false);
      // ✅ Use ref.read instead of context.read
      ref.read(searchFocusProvider.notifier).state = true;
    } else {
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTap,
        selectedItemColor: const Color(0xFF3D5CFF),
        unselectedItemColor: const Color(0xFF9CA3AF),
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts_rounded),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),
    );
  }
}
