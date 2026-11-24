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
import '../discover/class_card.dart';

class MyClassesScreen extends ConsumerWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prof = ref.watch(profileProvider).valueOrNull;
    final tutor = prof?.isTutor ?? false;
    return SafeArea(
      bottom: false,
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(Sp.l, Sp.l, Sp.l, Sp.s), child: Text(context.t('my_classes'), style: context.tx.headlineLarge)),
          Expanded(child: tutor ? _TutorList(uid: prof!.uid) : const _MemberList()),
        ]),
        if (tutor)
          PositionedDirectional(
            end: Sp.l,
            bottom: 108,
            child: PillButton(label: context.t('new_class'), icon: Icons.add_rounded, onPressed: () => context.push('/class-form')),
          ),
      ]),
    );
  }
}

class _TutorList extends ConsumerWidget {
  const _TutorList({required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(classesOfProvider(uid));
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(Sp.l), child: ListSkeleton(count: 3)),
      error: (_, __) => ErrorState(onRetry: () => ref.invalidate(classesOfProvider(uid))),
      data: (list) => list.isEmpty
          ? Center(child: EmptyState(icon: Icons.class_rounded, title: context.t('no_classes'), body: context.t('no_classes_d')))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, 180),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                return Stack(children: [
                  ClassCard(model: c, index: i, onTap: () => context.push('/class/${c.id}')),
                  if (c.pending > 0)
                    PositionedDirectional(
                      top: Sp.s,
                      end: Sp.s,
                      child: Tag(context.t('pending_n', {'n': '${c.pending}'}), selected: true),
                    ),
                ]);
              },
            ),
    );
  }
}

class _MemberList extends ConsumerWidget {
  const _MemberList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(membershipsProvider);
    final c = context.c;
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(Sp.l), child: ListSkeleton(count: 3)),
      error: (_, __) => ErrorState(onRetry: () => ref.invalidate(membershipsProvider)),
      data: (list) {
        if (list.isEmpty) return Center(child: EmptyState(icon: Icons.school_outlined, title: context.t('no_joined'), body: context.t('no_joined_d'), actionLabel: context.t('discover'), onAction: () => context.go('/')));
        final sorted = [...list]..sort((a, b) => (b.requestedAt ?? DateTime(2000)).compareTo(a.requestedAt ?? DateTime(2000)));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, 120),
          itemCount: sorted.length,
          itemBuilder: (_, i) {
            final m = sorted[i];
            final color = m.status == 'approved' ? c.success : (m.status == 'pending' ? c.warning : c.error);
            return FadeSlideIn(
              index: i,
              child: Pressable(
                onTap: () => context.push(m.status == 'approved' ? '/class/${m.classId}/space' : '/class/${m.classId}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: Sp.m),
                  padding: const EdgeInsets.all(Sp.l),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Rd.l), border: Border.all(color: c.hairline), boxShadow: c.shadow),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.classTitle, style: context.tx.titleMedium),
                        const SizedBox(height: 2),
                        Text(m.childName.isEmpty ? m.tutorName : '${m.tutorName} · ${m.childName}', style: context.tx.bodySmall),
                      ]),
                    ),
                    Tag(context.t('status_${m.status}'), color: color),
                  ]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
