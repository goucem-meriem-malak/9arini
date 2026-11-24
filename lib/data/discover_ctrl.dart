import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'providers.dart';

class Filters {
  const Filters({this.wilaya, this.level, this.subject, this.mode, this.maxPrice, this.query = ''});
  final String? wilaya, level, subject, mode;
  final int? maxPrice;
  final String query;

  Filters copyWith({String? Function()? wilaya, String? Function()? level, String? Function()? subject, String? Function()? mode, int? Function()? maxPrice, String? query}) => Filters(
        wilaya: wilaya != null ? wilaya() : this.wilaya,
        level: level != null ? level() : this.level,
        subject: subject != null ? subject() : this.subject,
        mode: mode != null ? mode() : this.mode,
        maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
        query: query ?? this.query,
      );

  /// Fields filtered by the server (one at most, to keep indexes few).
  String get serverKey => wilaya != null ? 'w$wilaya' : (level != null ? 'l$level' : (subject != null ? 's$subject' : ''));
  int get activeCount => [wilaya, level, subject, mode, maxPrice].where((e) => e != null).length;

  bool matches(ClassModel c) {
    if (wilaya != null && c.wilaya != wilaya) return false;
    if (level != null && c.level != level) return false;
    if (subject != null && c.subject != subject) return false;
    if (mode != null && c.mode != 'both' && c.mode != mode) return false;
    if (maxPrice != null && c.price > maxPrice!) return false;
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty && !('${c.title} ${c.tutorName} ${c.commune}'.toLowerCase().contains(q))) return false;
    return true;
  }
}

class DiscoverState {
  const DiscoverState({this.all = const [], this.filters = const Filters(), this.loading = false, this.hasMore = true, this.fromCache = false, this.error});
  final List<ClassModel> all;
  final Filters filters;
  final bool loading, hasMore, fromCache;
  final Object? error;
  List<ClassModel> get visible => all.where(filters.matches).toList();

  DiscoverState copyWith({List<ClassModel>? all, Filters? filters, bool? loading, bool? hasMore, bool? fromCache, Object? error, bool clearError = false}) => DiscoverState(
        all: all ?? this.all,
        filters: filters ?? this.filters,
        loading: loading ?? this.loading,
        hasMore: hasMore ?? this.hasMore,
        fromCache: fromCache ?? this.fromCache,
        error: clearError ? null : (error ?? this.error),
      );
}

class DiscoverCtrl extends Notifier<DiscoverState> {
  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  @override
  DiscoverState build() {
    ref.watch(uidProvider);
    Future.microtask(refresh);
    return const DiscoverState();
  }

  Future<void> refresh() => _load(true);
  Future<void> loadMore() => state.hasMore ? _load(false) : Future.value();

  void setFilters(Filters f) {
    final serverChanged = f.serverKey != state.filters.serverKey;
    state = state.copyWith(filters: f);
    if (serverChanged) {
      refresh();
    } else if (state.visible.length < 6 && state.hasMore) {
      loadMore();
    }
  }

  Future<void> _load(bool reset) async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final acc = reset ? <ClassModel>[] : [...state.all];
      var cursor = reset ? null : _cursor;
      var more = true;
      var cache = false;
      var pages = 0;
      final f = state.filters;
      while (more && pages < 4) {
        Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('classes').where('status', isEqualTo: 'open');
        if (f.wilaya != null) {
          q = q.where('wilaya', isEqualTo: f.wilaya);
        } else if (f.level != null) {
          q = q.where('level', isEqualTo: f.level);
        } else if (f.subject != null) {
          q = q.where('subject', isEqualTo: f.subject);
        }
        q = q.orderBy('createdAt', descending: true).limit(20);
        if (cursor != null) q = q.startAfterDocument(cursor);
        final s = await q.get();
        cache = s.metadata.isFromCache;
        acc.addAll(s.docs.map(ClassModel.fromDoc));
        if (s.docs.isNotEmpty) cursor = s.docs.last;
        more = s.docs.length == 20;
        pages++;
        if (acc.where(f.matches).length >= 10) break;
      }
      _cursor = cursor;
      state = state.copyWith(all: acc, hasMore: more, loading: false, fromCache: cache);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }
}

final discoverProvider = NotifierProvider<DiscoverCtrl, DiscoverState>(DiscoverCtrl.new);
