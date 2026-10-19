import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../features/auth/auth_controller.dart';
import 'package:go_router/go_router.dart';
import '../core/localization/strings.dart';
import '../features/auth/auth_screen.dart';
import '../features/create_incident/create_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/feed/home_screen.dart';
import '../features/incident_details/details_screen.dart';
import '../features/map/map_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/profile_screen.dart';
import '../shared/widgets/brand_mark.dart';
import '../core/theme/app_theme.dart';

GoRouter createRouter() => GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(path: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
        GoRoute(path: '/create', builder: (_, _) => const CreateScreen()),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsScreen(),
        ),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      ],
    ),
    GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
    GoRoute(path: '/feed', builder: (_, _) => const FeedScreen()),
    GoRoute(
      path: '/my-incidents/:id',
      builder: (_, state) => FeedScreen(authorId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/my-confirmations',
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(context.l.myConfirmations)),
        body: const NotificationsScreen(confirmations: true),
      ),
    ),
    GoRoute(
      path: '/incident/:id',
      builder: (_, state) => DetailsScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/success/:id',
      builder: (context, state) =>
          SuccessScreen(id: state.pathParameters['id']!),
    ),
  ],
);

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 100,
                color: Color(0xFF087E70),
              ),
              const SizedBox(height: 24),
              Text(
                context.l.success,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(context.l.successSubtitle, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/incident/$id'),
                child: Text(context.l.openIncident),
              ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(context.l.home),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    const paths = ['/home', '/map', '/create', '/notifications', '/profile'];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandMark(),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                context.l.appName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                if (auth.asData?.value == null &&
                    ref.read(apiProvider).sessions.expired)
                  MaterialBanner(
                    content: Text(context.l.sessionExpired),
                    actions: [
                      TextButton(
                        onPressed: () => context.push('/auth'),
                        child: Text(context.l.login),
                      ),
                    ],
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppPalette.line)),
        ),
        child: NavigationBar(
          selectedIndex: paths.indexOf(path).clamp(0, 4),
          onDestinationSelected: (index) => context.go(paths[index]),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: context.l.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map),
              label: context.l.map,
            ),
            NavigationDestination(
              icon: const Icon(Icons.add_circle_outline),
              selectedIcon: const Icon(Icons.add_circle),
              label: context.l.create,
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_none),
              selectedIcon: const Icon(Icons.notifications),
              label: context.l.notificationsTab,
              tooltip: context.l.notifications,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: context.l.profile,
            ),
          ],
        ),
      ),
    );
  }
}
