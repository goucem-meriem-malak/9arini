import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ctx.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/states.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'post_card.dart';

class ClassSpaceScreen extends ConsumerStatefulWidget {
  const ClassSpaceScreen({super.key, required this.classId});
  final String classId;
  @override
  ConsumerState<ClassSpaceScreen> createState() => _ClassSpaceState();
}

class _ClassSpaceState extends ConsumerState<ClassSpaceScreen> {
  int _limit = 20;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final cls = ref.watch(classProvider(widget.classId)).valueOrNull;
    final me = ref.watch(profileProvider).valueOrNull;
    final owner = cls != null && me?.uid == cls.tutorId;
    final repo = ref.watch(repoProvider);
    if (repo == null) return const SizedBox.shrink();

    return Scaffold(
      floatingActionButton: owner
          ? PillButton(label: context.t('new_post'), icon: Icons.edit_rounded, onPressed: () => context.push('/class/${widget.classId}/compose'))
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: repo.postsSnap(widget.classId, _limit),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          final posts = docs.map(PostModel.fromDoc).toList();
          final cache = snap.data?.metadata.isFromCache ?? false;
          return CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: HeroBackdrop(
                height: 200,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.s, Sp.xs, Sp.l, Sp.l),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        BackButton(color: Colors.white, onPressed: () => context.pop()),
                        const Spacer(),
                        if (cls != null) IconButton(tooltip: context.t('about_class'), icon: const Icon(Icons.info_outline_rounded, color: Colors.white), onPressed: () => context.push('/class/${cls.id}')),
                        if (owner) IconButton(tooltip: context.t('members_tab'), icon: const Icon(Icons.groups_rounded, color: Colors.white), onPressed: () => context.push('/class/${widget.classId}/members')),
                      ]),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: Sp.m),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(cls?.title ?? '', style: context.tx.headlineMedium?.copyWith(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (cls != null) Text('${cls.tutorName} · ${context.pl('members', cls.members)}', style: context.tx.bodySmall?.copyWith(color: Colors.white.o(0.9))),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Sp.l, Sp.l, Sp.l, 0),
              sliver: SliverToBoxAdapter(child: cache && posts.isNotEmpty ? const OfflineChip() : const SizedBox.shrink()),
            ),
            if (snap.hasError)
              SliverToBoxAdapter(child: ErrorState(onRetry: () => setState(() {})))
            else if (!snap.hasData)
              const SliverPadding(padding: EdgeInsets.symmetric(horizontal: Sp.l), sliver: SliverToBoxAdapter(child: ListSkeleton(count: 3)))
            else if (posts.isEmpty)
              SliverToBoxAdapter(child: EmptyState(icon: Icons.forum_outlined, title: context.t('no_posts'), body: context.t('no_posts_d')))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Sp.l),
                sliver: SliverList.builder(
                  itemCount: posts.length,
                  itemBuilder: (_, i) => PostCard(post: posts[i], index: i, onTap: () => context.push('/class/${widget.classId}/post/${posts[i].id}')),
                ),
              ),
            if (posts.length >= _limit)
              SliverToBoxAdapter(child: Center(child: TextButton(onPressed: () => setState(() => _limit += 20), child: Text(context.t('load_more'))))),
            SliverToBoxAdapter(child: SizedBox(height: owner ? 120 : 40, child: DecoratedBox(decoration: BoxDecoration(color: c.bg)))),
          ]);
        },
      ),
    );
  }
}
