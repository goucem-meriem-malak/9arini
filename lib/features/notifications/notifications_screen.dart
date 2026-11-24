import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ctx.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/states.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../class_space/post_card.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _text(BuildContext context, NotifModel n) => context.t('n_${n.kind}', {'name': n.name, 'title': n.classTitle, 'post': n.postTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final repo = ref.watch(repoProvider);
    final prof = ref.watch(profileProvider).valueOrNull;
    final c = context.c;
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.l, Sp.l, Sp.s, Sp.s),
          child: Row(children: [
            Expanded(child: Text(context.t('notifications'), style: context.tx.headlineLarge)),
            TextButton(onPressed: () => repo?.markAllRead(), child: Text(context.t('mark_read'))),
          ]),
        ),
        Expanded(
          child: async.when(
            loading: () => const Padding(padding: EdgeInsets.all(Sp.l), child: ListSkeleton(count: 4)),
            error: (_, __) => ErrorState(onRetry: () => ref.invalidate(notificationsProvider)),
            data: (list) => list.isEmpty
                ? Center(child: EmptyState(icon: Icons.notifications_none_rounded, title: context.t('no_notifs')))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, 120),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final n = list[i];
                      return FadeSlideIn(
                        index: i,
                        child: Pressable(
                          onTap: () {
                            repo?.markRead(n.id);
                            final tutorOfClass = prof?.isTutor ?? false;
                            if (n.kind == 'join_request' && tutorOfClass) {
                              context.push('/class/${n.classId}/members');
                            } else if (n.kind == 'join_rejected') {
                              context.push('/class/${n.classId}');
                            } else {
                              context.push('/class/${n.classId}/space');
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: Sp.s),
                            padding: const EdgeInsets.all(Sp.m),
                            decoration: BoxDecoration(color: n.read ? c.surface : c.primary.o(0.08), borderRadius: BorderRadius.circular(Rd.m), border: Border.all(color: c.hairline)),
                            child: Row(children: [
                              Icon(n.kind == 'new_post' ? Icons.campaign_rounded : Icons.person_add_alt_1_rounded, color: c.primary),
                              const SizedBox(width: Sp.m),
                              Expanded(child: Text(_text(context, n), style: context.tx.bodyMedium)),
                              Text(shortDate(context, n.createdAt), style: context.tx.bodySmall),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ]),
    );
  }
}
