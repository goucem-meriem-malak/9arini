import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/ctx.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/motion.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';

IconData postIcon(String type) => switch (type) {
      'assignment' => Icons.assignment_rounded,
      'document' => Icons.description_rounded,
      'poll' => Icons.poll_rounded,
      'list' => Icons.checklist_rounded,
      _ => Icons.campaign_rounded,
    };

String shortDate(BuildContext context, DateTime? d) => d == null ? '' : DateFormat.MMMd(context.lang).add_Hm().format(d.toLocal());

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onTap, this.index = 0});
  final PostModel post;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final p = post;
    final reactionTotal = p.reactions.values.fold<int>(0, (a, b) => a + b);
    return FadeSlideIn(
      index: index,
      child: Pressable(
        onTap: onTap,
        semanticLabel: p.title,
        child: Container(
          margin: const EdgeInsets.only(bottom: Sp.m),
          padding: const EdgeInsets.all(Sp.l),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Rd.l), border: Border.all(color: c.hairline), boxShadow: c.shadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: c.primary.o(0.12), borderRadius: BorderRadius.circular(Rd.s)),
                child: Icon(postIcon(p.type), size: 20, color: c.primary),
              ),
              const SizedBox(width: Sp.m),
              Expanded(child: Text(context.t(p.type), style: context.tx.labelMedium?.copyWith(color: c.primary))),
              Text(shortDate(context, p.createdAt), style: context.tx.bodySmall),
            ]),
            const SizedBox(height: Sp.m),
            Text(p.title, style: context.tx.titleMedium),
            if (p.body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: Sp.xs), child: Text(p.body, style: context.tx.bodyMedium, maxLines: 4, overflow: TextOverflow.ellipsis)),
            if (p.type == 'assignment' && p.dueAt != null) Padding(padding: const EdgeInsets.only(top: Sp.m), child: Tag(context.t('due', {'date': shortDate(context, p.dueAt)}), icon: Icons.event_rounded, color: c.warning)),
            if (p.type == 'document' && p.fileName.isNotEmpty) Padding(padding: const EdgeInsets.only(top: Sp.m), child: Tag(p.fileName, icon: Icons.attach_file_rounded)),
            if (p.type == 'poll') Padding(padding: const EdgeInsets.only(top: Sp.m), child: Tag('${p.options.length} ${context.t('options')}', icon: Icons.poll_rounded)),
            if (p.type == 'list') Padding(padding: const EdgeInsets.only(top: Sp.m), child: Text(p.listItems.take(3).map((e) => '• $e').join('\n'), style: context.tx.bodyMedium)),
            const SizedBox(height: Sp.m),
            Row(children: [
              if (reactionTotal > 0) ...[
                Text(reactionKeys.where((k) => (p.reactions[k] ?? 0) > 0).map((k) => reactionEmoji[k]).join(' '), style: const TextStyle(fontSize: 14)),
                const SizedBox(width: Sp.xs),
                Text('$reactionTotal', style: context.tx.bodySmall),
                const SizedBox(width: Sp.l),
              ],
              if (p.commentsEnabled) ...[Icon(Icons.mode_comment_outlined, size: 16, color: c.muted), const SizedBox(width: Sp.xs), Text('${p.commentCount}', style: context.tx.bodySmall)],
            ]),
          ]),
        ),
      ),
    );
  }
}
