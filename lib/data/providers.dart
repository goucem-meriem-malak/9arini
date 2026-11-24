import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import 'models.dart';
import 'repo.dart';

final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('prefs not loaded'));

/// Starts Firebase while the animated launch screen plays.
final bootProvider = FutureProvider<void>((ref) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (_) {
    // App Check is optional until enforcement is turned on in the console.
  }
});

final authStateProvider = StreamProvider<User?>((ref) async* {
  await ref.watch(bootProvider.future);
  yield* FirebaseAuth.instance.userChanges();
});

final uidProvider = Provider<String?>((ref) => ref.watch(authStateProvider.select((a) => a.valueOrNull?.uid)));

final repoProvider = Provider<Repo?>((ref) {
  final uid = ref.watch(uidProvider);
  return uid == null ? null : Repo(uid);
});

final profileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance.doc('users/$uid').snapshots().map((d) => d.exists ? UserProfile.fromDoc(d) : null);
});

// ---------- settings ----------
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    switch (ref.read(prefsProvider).getString('theme')) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  void set(ThemeMode m) {
    state = m;
    ref.read(prefsProvider).setString('theme', m.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final saved = ref.read(prefsProvider).getString('lang');
    if (saved != null) return Locale(saved);
    final device = PlatformDispatcher.instance.locale.languageCode;
    return Locale(const ['ar', 'fr', 'en'].contains(device) ? device : 'ar');
  }

  void set(String code) {
    state = Locale(code);
    ref.read(prefsProvider).setString('lang', code);
    ref.read(repoProvider)?.setLocale(code).catchError((_) {});
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class OnboardedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(prefsProvider).getBool('onboarded') ?? false;
  void done() {
    state = true;
    ref.read(prefsProvider).setBool('onboarded', true);
  }
}

final onboardedProvider = NotifierProvider<OnboardedNotifier, bool>(OnboardedNotifier.new);

// ---------- data streams ----------
final classProvider = StreamProvider.family<ClassModel?, String>((ref, id) => ref.watch(repoProvider)?.classStream(id) ?? Stream.empty());
final tutorProvider = StreamProvider.family<TutorProfile?, String>((ref, id) => ref.watch(repoProvider)?.tutor(id) ?? Stream.empty());
final membershipProvider = StreamProvider.family<MemberModel?, String>((ref, id) => ref.watch(repoProvider)?.myMembership(id) ?? Stream.empty());
final linkProvider = StreamProvider.family<String, String>((ref, id) => ref.watch(repoProvider)?.onlineLink(id) ?? Stream.empty());
final classesOfProvider = StreamProvider.family<List<ClassModel>, String>((ref, id) => ref.watch(repoProvider)?.classesOf(id) ?? Stream.empty());
final membershipsProvider = StreamProvider<List<MemberModel>>((ref) => ref.watch(repoProvider)?.myMemberships() ?? Stream.empty());
final childrenProvider = StreamProvider<List<ChildModel>>((ref) => ref.watch(repoProvider)?.children() ?? Stream.empty());
final blocksProvider = StreamProvider<Map<String, String>>((ref) => ref.watch(repoProvider)?.blocks() ?? Stream.empty());
final notificationsProvider = StreamProvider<List<NotifModel>>((ref) => ref.watch(repoProvider)?.notifications() ?? Stream.empty());
final reviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, id) => ref.watch(repoProvider)?.reviews(id) ?? Stream.empty());

final unreadProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.empty();
  return FirebaseFirestore.instance.collection('users/$uid/notifications').where('read', isEqualTo: false).limit(10).snapshots().map((s) => s.size);
});
