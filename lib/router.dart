import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/config.dart';
import 'core/widgets/motion.dart';
import 'data/providers.dart';
import 'features/auth/auth_screens.dart';
import 'features/class_space/class_space_screen.dart';
import 'features/class_space/composer_screen.dart';
import 'features/class_space/members_screen.dart';
import 'features/class_space/post_detail_screen.dart';
import 'features/classes/class_detail_screen.dart';
import 'features/classes/class_form_screen.dart';
import 'features/classes/my_classes_screen.dart';
import 'features/discover/discover_screen.dart';
import 'features/legal/legal_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/small_screens.dart';
import 'features/shell/shell_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/tutor/tutor_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  void bump(Object? a, Object? b) => refresh.value++;
  ref.listen(bootProvider, bump);
  ref.listen(authStateProvider.select((a) => a.valueOrNull?.uid), bump);
  ref.listen(authStateProvider.select((a) => a.isLoading), bump);
  ref.listen(profileProvider, bump);
  ref.onDispose(refresh.dispose);

  const publicPaths = ['/onboarding', '/signin', '/signup', '/forgot'];

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;
      if (!ref.read(bootProvider).hasValue) return '/splash';
      final auth = ref.read(authStateProvider);
      if (auth.isLoading) return null;
      final user = auth.valueOrNull;
      final legal = loc.startsWith('/legal');
      if (user == null) {
        if (publicPaths.contains(loc) || legal) return null;
        return ref.read(onboardedProvider) ? '/signin' : '/onboarding';
      }
      final prof = ref.read(profileProvider);
      if (prof.isLoading) return null;
      final p = prof.valueOrNull;
      if (p == null) return (loc == '/complete-profile' || legal) ? null : '/complete-profile';
      if (p.termsVersion != AppConfig.legalVersion) return (loc == '/terms-update' || legal) ? null : '/terms-update';
      if (publicPaths.contains(loc) || loc == '/complete-profile' || loc == '/terms-update') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', pageBuilder: (c, s) => fadeSlide(s, const SplashScreen())),
      GoRoute(path: '/onboarding', pageBuilder: (c, s) => fadeSlide(s, const OnboardingScreen())),
      GoRoute(path: '/signin', pageBuilder: (c, s) => fadeSlide(s, const SignInScreen())),
      GoRoute(path: '/signup', pageBuilder: (c, s) => fadeSlide(s, const SignUpScreen())),
      GoRoute(path: '/complete-profile', pageBuilder: (c, s) => fadeSlide(s, const SignUpScreen(complete: true))),
      GoRoute(path: '/forgot', pageBuilder: (c, s) => fadeSlide(s, const ForgotScreen())),
      GoRoute(path: '/terms-update', pageBuilder: (c, s) => fadeSlide(s, const TermsUpdateScreen())),
      GoRoute(path: '/legal/:doc', pageBuilder: (c, s) => fadeSlide(s, LegalScreen(doc: s.pathParameters['doc']!))),
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => ShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (c, s) => const DiscoverScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/mine', builder: (c, s) => const MyClassesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/class/:id', pageBuilder: (c, s) => fadeSlide(s, ClassDetailScreen(id: s.pathParameters['id']!))),
      GoRoute(path: '/class/:id/space', pageBuilder: (c, s) => fadeSlide(s, ClassSpaceScreen(classId: s.pathParameters['id']!))),
      GoRoute(path: '/class/:id/members', pageBuilder: (c, s) => fadeSlide(s, MembersScreen(classId: s.pathParameters['id']!))),
      GoRoute(path: '/class/:id/compose', pageBuilder: (c, s) => fadeSlide(s, ComposerScreen(classId: s.pathParameters['id']!))),
      GoRoute(path: '/class/:id/post/:pid', pageBuilder: (c, s) => fadeSlide(s, PostDetailScreen(classId: s.pathParameters['id']!, postId: s.pathParameters['pid']!))),
      GoRoute(path: '/class-form', pageBuilder: (c, s) => fadeSlide(s, ClassFormScreen(classId: s.uri.queryParameters['id']))),
      GoRoute(path: '/tutor/:id', pageBuilder: (c, s) => fadeSlide(s, TutorScreen(id: s.pathParameters['id']!))),
      GoRoute(path: '/children', pageBuilder: (c, s) => fadeSlide(s, const ChildrenScreen())),
      GoRoute(path: '/blocked', pageBuilder: (c, s) => fadeSlide(s, const BlockedScreen())),
      GoRoute(path: '/export', pageBuilder: (c, s) => fadeSlide(s, const ExportScreen())),
    ],
  );
});
