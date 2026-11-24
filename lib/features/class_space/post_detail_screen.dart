import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/ctx.dart';
import '../../core/errors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/states.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/repo.dart';
import 'post_card.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.classId, required this.postId});
  final String classId, postId;
  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailState();
}

class _PostDetailState extends ConsumerState<PostDetailScreen> {
  final _comment = TextEditingController();
  List<String>? _draftVote;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      if (mounted) context.toast(errText(context, e));
    }
  }

  Future<void> _report(String path, String uid) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('report_reason')),
        content: TextField(controller: reason, maxLength: 300, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.t('report'))),
        ],
      ),
    );
    final text = reason.text;
    reason.dispose();
    if (ok == true && text.trim().isNotEmpty) {
      await _guard(() async {
        await ref.read(repoProvider)!.report(path, uid, text);
        if (mounted) context.toast(context.t('reported'));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final repo = ref.watch(repoProvider);
    final me = ref.watch(profileProvider).valueOrNull;
    final cls = ref.watch(classProvider(widget.classId)).valueOrNull;
    final blocked = ref.watch(blocksProvider).valueOrNull ?? {};
    if (repo == null || me == null) return const SizedBox.shrink();
    final owner = cls?.tutorId == me.uid;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (owner)
            IconButton(
              tooltip: context.t('delete'),
              icon: Icon(Icons.delete_outline_rounded, color: c.error),
              onPressed: () async {
                if (await confirmDialog(context, context.t('delete_q'))) {
                  await _guard(() => repo.deletePost(widget.classId, widget.postId));
                  if (context.mounted) context.pop();
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<PostModel?>(
        stream: repo.post(widget.classId, widget.postId),
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(onRetry: () => setState(() {}));
          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(Sp.l), child: ListSkeleton(count: 1));
          final p = snap.data;
          if (p == null) return Center(child: EmptyState(icon: Icons.delete_outline_rounded, title: context.t('no_posts')));
          return Column(children: [
            Expanded(
              child: ListView(padding: const EdgeInsets.all(Sp.l), children: [
                Row(children: [Icon(postIcon(p.type), color: c.primary), const SizedBox(width: Sp.s), Text(context.t(p.type), style: context.tx.labelLarge?.copyWith(color: c.primary)), const Spacer(), Text(shortDate(context, p.createdAt), style: context.tx.bodySmall)]),
                const SizedBox(height: Sp.m),
                Text(p.title, style: context.tx.headlineMedium),
                if (p.body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: Sp.m), child: Text(p.body, style: context.tx.bodyLarge)),
                if (p.type == 'assignment' && p.dueAt != null) Padding(padding: const EdgeInsets.only(top: Sp.m), child: Tag(context.t('due', {'date': shortDate(context, p.dueAt)}), icon: Icons.event_rounded, color: c.warning)),
                if (p.type == 'document' && p.filePath.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: Sp.l),
                    child: PillButton(
                      label: '${context.t('open_file')} · ${p.fileName}',
                      icon: Icons.download_rounded,
                      secondary: true,
                      onPressed: () => _guard(() async {
                        final url = await repo.fileUrl(p.filePath);
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }),
                    ),
                  ),
                if (p.type == 'list') ...[const SizedBox(height: Sp.l), for (final it in p.listItems) Padding(padding: const EdgeInsets.only(bottom: Sp.s), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_circle_outline_rounded, size: 20, color: c.primary), const SizedBox(width: Sp.s), Expanded(child: Text(it, style: context.tx.bodyLarge))]))],
                if (p.type == 'poll') _Poll(post: p, repo: repo, classId: widget.classId, draft: _draftVote, onDraft: (v) => setState(() => _draftVote = v), guard: _guard),
                const SizedBox(height: Sp.l),
                StreamBuilder<String?>(
                  stream: repo.myReaction(widget.classId, p.id),
                  builder: (context, rs) => Wrap(spacing: Sp.s, children: [
                    for (final k in reactionKeys)
                      Tag(
                        '${reactionEmoji[k]} ${p.reactions[k] ?? 0}',
                        selected: rs.data == k,
                        onTap: () => _guard(() => repo.react(widget.classId, p.id, rs.data == k ? null : k)),
                      ),
                  ]),
                ),
                SectionTitle(context.t('comments')),
                if (!p.commentsEnabled && !owner)
                  Text(context.t('comments_off'), style: TextStyle(color: c.muted))
                else
                  StreamBuilder<List<CommentModel>>(
                    stream: repo.comments(widget.classId, p.id),
                    builder: (context, cs) {
                      final list = (cs.data ?? []).where((x) => !blocked.containsKey(x.authorId)).toList();
                      if (cs.hasData && list.isEmpty) return Text(context.t('no_comments'), style: TextStyle(color: c.muted));
                      return Column(children: [
                        for (final cm in list)
                          Container(
                            margin: const EdgeInsets.only(bottom: Sp.s),
                            padding: const EdgeInsets.all(Sp.m),
                            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Rd.m), border: Border.all(color: c.hairline)),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Avatar(cm.authorName, size: 32),
                              const SizedBox(width: Sp.m),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(cm.authorName, style: context.tx.labelLarge), Text(cm.text, style: context.tx.bodyMedium)])),
                              PopupMenuButton<String>(
                                tooltip: '',
                                onSelected: (v) async {
                                  if (v == 'report') await _report('classes/${widget.classId}/posts/${p.id}/comments/${cm.id}', cm.authorId);
                                  if (v == 'block') {
                                    await _guard(() => repo.block(cm.authorId, cm.authorName));
                                    if (context.mounted) context.toast(context.t('blocked_done'));
                                  }
                                  if (v == 'delete') await _guard(() => repo.deleteComment(widget.classId, p.id, cm.id));
                                },
                                itemBuilder: (_) => [
                                  if (cm.authorId != me.uid) PopupMenuItem(value: 'report', child: Text(context.t('report'))),
                                  if (cm.authorId != me.uid) PopupMenuItem(value: 'block', child: Text(context.t('block'))),
                                  if (cm.authorId == me.uid || owner) PopupMenuItem(value: 'delete', child: Text(context.t('delete'))),
                                ],
                              ),
                            ]),
                          ),
                      ]);
                    },
                  ),
              ]),
            ),
            if (p.commentsEnabled || owner)
              Container(
                decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.hairline))),
                padding: EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.s, Sp.s + MediaQuery.of(context).viewInsets.bottom),
                child: SafeArea(
                  top: false,
                  child: Row(children: [
                    Expanded(child: TextField(controller: _comment, maxLength: 500, decoration: InputDecoration(hintText: context.t('add_comment'), border: InputBorder.none, counterText: ''))),
                    IconButton(
                      tooltip: context.t('submit'),
                      icon: Icon(Icons.send_rounded, color: c.primary),
                      onPressed: () async {
                        final t = _comment.text.trim();
                        if (t.isEmpty) return;
                        _comment.clear();
                        await _guard(() => repo.addComment(widget.classId, p.id, me.name, t));
                      },
                    ),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class _Poll extends StatelessWidget {
  const _Poll({required this.post, required this.repo, required this.classId, required this.draft, required this.onDraft, required this.guard});
  final PostModel post;
  final Repo repo;
  final String classId;
  final List<String>? draft;
  final ValueChanged<List<String>> onDraft;
  final Future<void> Function(Future<void> Function()) guard;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final total = post.pollCounts.values.fold<int>(0, (a, b) => a + b);
    return StreamBuilder<List<String>>(
      stream: repo.myVote(classId, post.id),
      builder: (context, snap) {
        final mine = snap.data ?? const <String>[];
        final sel = draft ?? mine;
        return Padding(
          padding: const EdgeInsets.only(top: Sp.l),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (post.multi) Padding(padding: const EdgeInsets.only(bottom: Sp.s), child: Text(context.t('multi_choice'), style: context.tx.bodySmall)),
            for (final o in post.options)
              Builder(builder: (_) {
                final n = post.pollCounts[o.id] ?? 0;
                final frac = total == 0 ? 0.0 : n / total;
                final on = sel.contains(o.id);
                return Pressable(
                  onTap: () {
                    final next = post.multi ? (on ? sel.where((e) => e != o.id).toList() : [...sel, o.id]) : [o.id];
                    onDraft(next);
                    if (next.isNotEmpty) guard(() => repo.vote(classId, post.id, next));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: Sp.s),
                    constraints: const BoxConstraints(minHeight: 52),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(Rd.m), border: Border.all(color: on ? c.primary : c.hairline, width: on ? 1.5 : 1), color: c.surface),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Rd.m - 1),
                      child: Stack(children: [
                        Positioned.fill(child: Align(alignment: AlignmentDirectional.centerStart, child: FractionallySizedBox(widthFactor: frac, child: Container(color: c.primary.o(0.14))))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.m),
                          child: Row(children: [
                            Icon(on ? Icons.check_circle_rounded : Icons.circle_outlined, size: 20, color: on ? c.primary : c.muted),
                            const SizedBox(width: Sp.m),
                            Expanded(child: Text(o.text, style: context.tx.bodyLarge)),
                            Text('$n', style: context.tx.labelLarge),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                );
              }),
          ]),
        );
      },
    );
  }
}
