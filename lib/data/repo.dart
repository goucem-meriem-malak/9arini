import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/config.dart';
import 'models.dart';

typedef Json = Map<String, dynamic>;

/// All Firestore / Storage / Functions access. Permissions are enforced by
/// firestore.rules and storage.rules, never by this class.
class Repo {
  Repo(this.uid);
  final String uid;
  FirebaseFirestore get db => FirebaseFirestore.instance;
  FirebaseFunctions get fn => FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);
  DocumentReference<Json> get _user => db.doc('users/$uid');

  // ---------- profile ----------
  Future<void> createProfile({required String name, required String role, required String locale}) async {
    await _user.set({
      'name': name.trim(),
      'role': role,
      'ageConfirmed': true,
      'locale': locale,
      'termsVersion': AppConfig.legalVersion,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (role == 'tutor') {
      await db.doc('tutors/$uid').set({'name': name.trim(), 'bio': '', 'subjects': <String>[], 'wilaya': '', 'years': 0, 'ratingAvg': 0, 'ratingCount': 0});
    }
  }

  Future<void> acceptTerms() => _user.update({'termsVersion': AppConfig.legalVersion, 'termsAcceptedAt': FieldValue.serverTimestamp()});
  Future<void> setLocale(String l) => _user.update({'locale': l});

  Future<void> saveTutor({required String bio, required List<String> subjects, required String wilaya, required int years}) =>
      db.doc('tutors/$uid').update({'bio': bio.trim(), 'subjects': subjects, 'wilaya': wilaya, 'years': years});

  Stream<TutorProfile?> tutor(String id) => db.doc('tutors/$id').snapshots().map((d) => d.exists ? TutorProfile.fromDoc(d) : null);

  // ---------- classes ----------
  Stream<ClassModel?> classStream(String id) => db.doc('classes/$id').snapshots().map((d) => d.exists ? ClassModel.fromDoc(d) : null);

  Stream<List<ClassModel>> classesOf(String tutorId) => db
      .collection('classes')
      .where('tutorId', isEqualTo: tutorId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(ClassModel.fromDoc).toList());

  Stream<String> onlineLink(String classId) => db.doc('classes/$classId/private/info').snapshots().map((d) => (d.data()?['onlineLink'] as String?) ?? '');

  Future<String> createClass(Json data, String link, String tutorName) async {
    final ref = db.collection('classes').doc();
    await ref.set({...data, 'tutorId': uid, 'tutorName': tutorName, 'memberCount': 0, 'pendingCount': 0, 'status': 'open', 'createdAt': FieldValue.serverTimestamp()});
    await ref.collection('private').doc('info').set({'onlineLink': link});
    return ref.id;
  }

  Future<void> updateClass(String id, Json data, String link) async {
    await db.doc('classes/$id').update(data);
    await db.doc('classes/$id/private/info').set({'onlineLink': link});
  }

  Future<void> setClassOpen(String id, bool open) => db.doc('classes/$id').update({'status': open ? 'open' : 'closed'});

  // ---------- membership ----------
  Stream<MemberModel?> myMembership(String classId) =>
      db.doc('classes/$classId/members/$uid').snapshots().map((d) => d.exists ? MemberModel.fromDoc(d) : null);

  Stream<List<MemberModel>> myMemberships() => db
      .collectionGroup('members')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map(MemberModel.fromDoc).toList());

  Future<void> requestJoin(ClassModel c, UserProfile p, String childName) => db.doc('classes/${c.id}/members/$uid').set({
        'uid': uid,
        'name': p.name,
        'role': p.role,
        'childName': childName,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'classId': c.id,
        'classTitle': c.title,
        'tutorId': c.tutorId,
        'tutorName': c.tutorName,
      });

  Future<void> leave(String classId) => db.doc('classes/$classId/members/$uid').delete();

  Stream<List<MemberModel>> classMembers(String classId) =>
      db.collection('classes/$classId/members').orderBy('requestedAt').snapshots().map((s) => s.docs.map(MemberModel.fromDoc).toList());

  Future<void> decide(String classId, String memberUid, bool approve) =>
      db.doc('classes/$classId/members/$memberUid').update({'status': approve ? 'approved' : 'rejected', 'decidedAt': FieldValue.serverTimestamp()});

  Future<void> removeMember(String classId, String memberUid) => db.doc('classes/$classId/members/$memberUid').delete();

  // ---------- posts ----------
  Stream<QuerySnapshot<Json>> postsSnap(String classId, int limit) =>
      db.collection('classes/$classId/posts').orderBy('createdAt', descending: true).limit(limit).snapshots(includeMetadataChanges: true);

  Stream<PostModel?> post(String classId, String postId) =>
      db.doc('classes/$classId/posts/$postId').snapshots().map((d) => d.exists ? PostModel.fromDoc(d) : null);

  static String _safe(String n) {
    final s = n.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return s.length > 80 ? s.substring(s.length - 80) : s;
  }

  static String? mime(String? ext) => switch ((ext ?? '').toLowerCase()) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'txt' => 'text/plain',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        _ => null,
      };

  static const allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg', 'txt', 'docx', 'pptx', 'xlsx'];

  Future<void> createPost(String classId, Json data, String authorName, {PlatformFile? file}) async {
    final ref = db.collection('classes/$classId/posts').doc();
    final d = <String, dynamic>{...data, 'authorId': uid, 'authorName': authorName, 'createdAt': FieldValue.serverTimestamp()};
    if (file != null && file.path != null) {
      final path = 'classes/$classId/${ref.id}/${_safe(file.name)}';
      await FirebaseStorage.instance.ref(path).putFile(File(file.path!), SettableMetadata(contentType: mime(file.extension)));
      d.addAll({'fileName': file.name, 'filePath': path, 'fileSize': file.size});
    }
    await ref.set(d);
  }

  Future<void> deletePost(String classId, String postId) => db.doc('classes/$classId/posts/$postId').delete();

  Future<String> fileUrl(String path) => FirebaseStorage.instance.ref(path).getDownloadURL();

  Stream<String?> myReaction(String classId, String postId) =>
      db.doc('classes/$classId/posts/$postId/reactions/$uid').snapshots().map((d) => d.data()?['emoji'] as String?);

  Future<void> react(String classId, String postId, String? key) {
    final ref = db.doc('classes/$classId/posts/$postId/reactions/$uid');
    return key == null ? ref.delete() : ref.set({'uid': uid, 'emoji': key, 'createdAt': FieldValue.serverTimestamp()});
  }

  Stream<List<String>> myVote(String classId, String postId) => db
      .doc('classes/$classId/posts/$postId/votes/$uid')
      .snapshots()
      .map((d) => d.exists ? List<String>.from((d.data()?['options'] as List?) ?? const []) : <String>[]);

  Future<void> vote(String classId, String postId, List<String> ids) =>
      db.doc('classes/$classId/posts/$postId/votes/$uid').set({'uid': uid, 'options': ids, 'updatedAt': FieldValue.serverTimestamp()});

  Stream<List<CommentModel>> comments(String classId, String postId) => db
      .collection('classes/$classId/posts/$postId/comments')
      .orderBy('createdAt')
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(CommentModel.fromDoc).toList());

  Future<void> addComment(String classId, String postId, String name, String text) =>
      db.collection('classes/$classId/posts/$postId/comments').add({'authorId': uid, 'authorName': name, 'text': text.trim(), 'createdAt': FieldValue.serverTimestamp()});

  Future<void> deleteComment(String classId, String postId, String id) => db.doc('classes/$classId/posts/$postId/comments/$id').delete();

  // ---------- reviews ----------
  Stream<List<ReviewModel>> reviews(String tutorId) => db
      .collection('tutors/$tutorId/reviews')
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs.map(ReviewModel.fromDoc).toList());

  Future<ReviewModel?> myReview(String tutorId) async {
    final d = await db.doc('tutors/$tutorId/reviews/$uid').get();
    return d.exists ? ReviewModel.fromDoc(d) : null;
  }

  /// A class of this tutor in which the user is approved, or null.
  Future<String?> eligibleClassFor(String tutorId) async {
    final s = await db.collectionGroup('members').where('uid', isEqualTo: uid).where('tutorId', isEqualTo: tutorId).get();
    for (final d in s.docs) {
      if (d.data()['status'] == 'approved') return d.data()['classId'] as String?;
    }
    return null;
  }

  Future<void> saveReview(String tutorId, String classId, String name, int rating, String text, {required bool exists}) {
    final ref = db.doc('tutors/$tutorId/reviews/$uid');
    if (exists) return ref.update({'rating': rating, 'text': text.trim(), 'updatedAt': FieldValue.serverTimestamp()});
    return ref.set({'authorId': uid, 'authorName': name, 'rating': rating, 'text': text.trim(), 'classId': classId, 'createdAt': FieldValue.serverTimestamp()});
  }

  // ---------- notifications ----------
  Stream<List<NotifModel>> notifications() => db
      .collection('users/$uid/notifications')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(NotifModel.fromDoc).toList());

  Future<void> markRead(String id) => db.doc('users/$uid/notifications/$id').update({'read': true});

  Future<void> markAllRead() async {
    final s = await db.collection('users/$uid/notifications').where('read', isEqualTo: false).limit(50).get();
    final b = db.batch();
    for (final d in s.docs) {
      b.update(d.reference, {'read': true});
    }
    await b.commit();
  }

  // ---------- children, blocks, reports ----------
  Stream<List<ChildModel>> children() => db.collection('users/$uid/children').snapshots().map((s) => s.docs.map(ChildModel.fromDoc).toList());
  Future<void> addChild(String name, String level) => db.collection('users/$uid/children').add({'name': name.trim(), 'level': level});
  Future<void> removeChild(String id) => db.doc('users/$uid/children/$id').delete();

  Stream<Map<String, String>> blocks() =>
      db.collection('users/$uid/blocks').snapshots().map((s) => {for (final d in s.docs) d.id: (d.data()['name'] as String?) ?? ''});
  Future<void> block(String otherUid, String name) => db.doc('users/$uid/blocks/$otherUid').set({'name': name, 'createdAt': FieldValue.serverTimestamp()});
  Future<void> unblock(String otherUid) => db.doc('users/$uid/blocks/$otherUid').delete();

  Future<void> report(String targetPath, String targetUid, String reason) =>
      db.collection('reports').add({'reporterId': uid, 'targetPath': targetPath, 'targetUid': targetUid, 'reason': reason.trim(), 'createdAt': FieldValue.serverTimestamp()});

  // ---------- data rights ----------
  Future<String> exportData() async {
    final r = await fn.httpsCallable('exportMyData').call();
    return r.data as String;
  }

  Future<void> deleteAccount() => fn.httpsCallable('deleteAccount').call();
}
