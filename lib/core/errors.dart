import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'ctx.dart';

/// Turns any error into a short, safe, localized message (never raw details).
String errText(BuildContext c, Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
      case 'invalid-email':
        return c.t('err_creds');
      case 'email-already-in-use':
        return c.t('err_in_use');
      case 'too-many-requests':
        return c.t('err_many');
      case 'network-request-failed':
        return c.t('err_network');
    }
    return c.t('err_generic');
  }
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') return c.t('err_perm');
    if (e.code == 'unavailable') return c.t('err_network');
  }
  return c.t('err_generic');
}
