import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Registers the device for push. The server sends messages (Cloud Functions);
/// the app only stores its own token under users/{uid}/tokens.
abstract final class PushService {
  static String? _uid;
  static String? _token;
  static StreamSubscription<String>? _tokenSub;
  static StreamSubscription<RemoteMessage>? _openSub, _fgSub;

  static Future<void> start(String uid, void Function(String classId) open, void Function(String message) show) async {
    if (_uid == uid) return;
    _uid = uid;
    try {
      final m = FirebaseMessaging.instance;
      final s = await m.requestPermission();
      if (s.authorizationStatus == AuthorizationStatus.denied) return;
      _token = await m.getToken();
      if (_token != null) await _save(uid, _token!);
      _tokenSub = m.onTokenRefresh.listen((t) {
        _token = t;
        _save(uid, t);
      });
      _openSub = FirebaseMessaging.onMessageOpenedApp.listen((e) => _open(e, open));
      _fgSub = FirebaseMessaging.onMessage.listen((e) {
        final n = e.notification;
        if (n != null) show('${n.title ?? ''}\n${n.body ?? ''}'.trim());
      });
      final initial = await m.getInitialMessage();
      if (initial != null) _open(initial, open);
    } catch (_) {
      // Push is best effort; the in-app notification list still works.
    }
  }

  static void _open(RemoteMessage e, void Function(String) open) {
    final id = e.data['classId'];
    if (id is String && id.isNotEmpty) open(id);
  }

  static Future<void> _save(String uid, String token) =>
      FirebaseFirestore.instance.doc('users/$uid/tokens/$token').set({'platform': defaultTargetPlatform.name, 'createdAt': FieldValue.serverTimestamp()});

  static Future<void> stop() async {
    final uid = _uid, token = _token;
    _uid = null;
    _token = null;
    await _tokenSub?.cancel();
    await _openSub?.cancel();
    await _fgSub?.cancel();
    if (uid != null && token != null) {
      try {
        await FirebaseFirestore.instance.doc('users/$uid/tokens/$token').delete();
      } catch (_) {}
    }
  }
}
