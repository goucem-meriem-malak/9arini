import 'package:cloud_firestore/cloud_firestore.dart';

String _s(Object? v) => v is String ? v : '';
int _i(Object? v) => v is num ? v.toInt() : 0;
double _d(Object? v) => v is num ? v.toDouble() : 0;
DateTime? _t(Object? v) => v is Timestamp ? v.toDate() : null;
List<String> _ls(Object? v) => v is List ? v.map((e) => '$e').toList() : <String>[];
Map<String, int> _counts(Object? v) => v is Map ? {for (final e in v.entries) '${e.key}': _i(e.value)} : <String, int>{};

typedef Doc = DocumentSnapshot<Map<String, dynamic>>;

class UserProfile {
  const UserProfile({required this.uid, required this.name, required this.role, required this.termsVersion, required this.locale});
  final String uid, name, role, termsVersion, locale;
  bool get isTutor => role == 'tutor';
  bool get isParent => role == 'parent';
  factory UserProfile.fromDoc(Doc d) {
    final m = d.data() ?? {};
    return UserProfile(uid: d.id, name: _s(m['name']), role: _s(m['role']), termsVersion: _s(m['termsVersion']), locale: _s(m['locale']));
  }
}

class TutorProfile {
  const TutorProfile({required this.uid, required this.name, required this.bio, required this.subjects, required this.wilaya, required this.years, required this.ratingAvg, required this.ratingCount});
  final String uid, name, bio, wilaya;
  final List<String> subjects;
  final int years, ratingCount;
  final double ratingAvg;
  factory TutorProfile.fromDoc(Doc d) {
    final m = d.data() ?? {};
    return TutorProfile(
      uid: d.id, name: _s(m['name']), bio: _s(m['bio']), subjects: _ls(m['subjects']), wilaya: _s(m['wilaya']),
      years: _i(m['years']), ratingAvg: _d(m['ratingAvg']), ratingCount: _i(m['ratingCount']),
    );
  }
}

class ClassModel {
  const ClassModel({
    required this.id, required this.tutorId, required this.tutorName, required this.title, required this.subject, required this.level,
    required this.description, required this.price, required this.priceUnit, required this.wilaya, required this.commune,
    required this.mode, required this.schedule, required this.capacity, required this.members, required this.pending,
    required this.status, this.createdAt,
  });
  final String id, tutorId, tutorName, title, subject, level, description, priceUnit, wilaya, commune, mode, schedule, status;
  final int price, capacity, members, pending;
  final DateTime? createdAt;
  bool get isFull => members >= capacity;
  bool get isOpen => status == 'open' && !isFull;
  factory ClassModel.fromDoc(Doc d) {
    final m = d.data() ?? {};
    return ClassModel(
      id: d.id, tutorId: _s(m['tutorId']), tutorName: _s(m['tutorName']), title: _s(m['title']), subject: _s(m['subject']),
      level: _s(m['level']), description: _s(m['description']), price: _i(m['price']), priceUnit: _s(m['priceUnit']),
      wilaya: _s(m['wilaya']), commune: _s(m['commune']), mode: _s(m['mode']), schedule: _s(m['schedule']),
      capacity: _i(m['capacity']), members: _i(m['memberCount']), pending: _i(m['pendingCount']), status: _s(m['status']),
      createdAt: _t(m['createdAt']),
    );
  }
}

class MemberModel {
  const MemberModel({required this.uid, required this.name, required this.role, required this.childName, required this.status, required this.classId, required this.classTitle, required this.tutorName, this.requestedAt});
  final String uid, name, role, childName, status, classId, classTitle, tutorName;
  final DateTime? requestedAt;
  factory MemberModel.fromDoc(Doc d) {
    final m = d.data() ?? {};
    return MemberModel(
      uid: _s(m['uid']), name: _s(m['name']), role: _s(m['role']), childName: _s(m['childName']), status: _s(m['status']),
      classId: _s(m['classId']), classTitle: _s(m['classTitle']), tutorName: _s(m['tutorName']), requestedAt: _t(m['requestedAt']),
    );
  }
}

class PostModel {
  const PostModel({
    required this.id, required this.type, required this.title, required this.body, required this.authorName, required this.commentsEnabled,
    required this.fileName, required this.filePath, required this.fileSize, required this.options, required this.multi, required this.listItems,
    required this.reactions, required this.pollCounts, required this.commentCount, this.dueAt, this.createdAt,
  });
  final String id, type, title, body, authorName, fileName, filePath;
  final bool commentsEnabled, multi;
  final int fileSize, commentCount;
  final List<({String id, String text})> options;
  final List<String> listItems;
  final Map<String, int> reactions, pollCounts;
  final DateTime? dueAt, createdAt;
  factory PostModel.fromDoc(Doc d) {
    final m = d.data() ?? {};
    final opts = <({String id, String text})>[];
    if (m['options'] is List) {
      for (final o in m['options'] as List) {
        final mo = Map<String, dynamic>.from(o as Map);
        opts.add((id: _s(mo['id']), text: _s(mo['text'])));
      }
    }
    return PostModel(
      id: d.id, type: _s(m['type']), title: _s(m['title']), body: _s(m['body']), authorName: _s(m['authorName']),
      commentsEnabled: m['commentsEnabled'] == true, multi: m['multi'] == true, fileName: _s(m['fileName']), filePath: _s(m['filePath']),
      fileSize: _i(m['fileSize']), options: opts, listItems: _ls(m['listItems']), reactions: _counts(m['reactionCounts']),
      pollCounts: _counts(m['pollCounts']), commentCount: _i(m['commentCount']), dueAt: _t(m['dueAt']), createdAt: _t(m['createdAt']),
    );
  }
}

class CommentModel {
  const CommentModel({required this.id, required this.authorId, required this.authorName, required this.text, this.createdAt});
  final String id, authorId, authorName, text;
  final DateTime? createdAt;
  factory CommentModel.fromDoc(Doc d) {
    final m = d.data() ?? {};
    return CommentModel(id: d.id, authorId: _s(m['authorId']), authorName: _s(m['authorName']), text: _s(m['text']), createdAt: _t(m['createdAt']));
  }
}

class ReviewModel {
  const ReviewModel({required this.id, required this.authorName, required this.rating, required this.text, required this.classId, this.createdAt});
  final String id, authorName, text, classId;
  final int rating;
  final DateTime? createdAt;
  factory ReviewModel.fromDoc(Doc d) {
    final m = d.data() ?? {};
    return ReviewModel(id: d.id, authorName: _s(m['authorName']), rating: _i(m['rating']), text: _s(m['text']), classId: _s(m['classId']), createdAt: _t(m['createdAt']));
  }
}

class NotifModel {
  const NotifModel({required this.id, required this.kind, required this.classId, required this.classTitle, required this.name, required this.postTitle, required this.read, this.createdAt});
  final String id, kind, classId, classTitle, name, postTitle;
  final bool read;
  final DateTime? createdAt;
  factory NotifModel.fromDoc(Doc d) {
    final m = d.data() ?? {};
    return NotifModel(
      id: d.id, kind: _s(m['kind']), classId: _s(m['classId']), classTitle: _s(m['classTitle']), name: _s(m['name']),
      postTitle: _s(m['postTitle']), read: m['read'] == true, createdAt: _t(m['createdAt']),
    );
  }
}

class ChildModel {
  const ChildModel({required this.id, required this.name, required this.level});
  final String id, name, level;
  factory ChildModel.fromDoc(Doc d) {
    final m = d.data() ?? {};
    return ChildModel(id: d.id, name: _s(m['name']), level: _s(m['level']));
  }
}
