import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ctx.dart';
import '../../core/errors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/states.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repoProvider);
    final c = context.c;
    if (repo == null) return const SizedBox.shrink();

    Future<void> act(Future<void> Function() f) async {
      try {
        await f();
      } catch (e) {
        if (context.mounted) context.toast(errText(context, e));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.t('members_tab'))),
      body: StreamBuilder<List<MemberModel>>(
        stream: repo.classMembers(classId),
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(onRetry: () {});
          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(Sp.l), child: ListSkeleton(count: 3));
          final all = snap.data!;
          final pending = all.where((m) => m.status == 'pending').toList();
          final approved = all.where((m) => m.status == 'approved').toList();
          if (pending.isEmpty && approved.isEmpty) return Center(child: EmptyState(icon: Icons.groups_outlined, title: context.t('no_members')));
          Widget tile(MemberModel m, List<Widget> actions) => Container(
                margin: const EdgeInsets.only(bottom: Sp.s),
                padding: const EdgeInsets.all(Sp.m),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Rd.m), border: Border.all(color: c.hairline)),
                child: Row(children: [
                  Avatar(m.name, size: 40),
                  const SizedBox(width: Sp.m),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.name, style: context.tx.labelLarge),
                      Text([context.t('role_${m.role}'), if (m.childName.isNotEmpty) m.childName].join(' · '), style: context.tx.bodySmall),
                    ]),
                  ),
                  ...actions,
                ]),
              );
          return ListView(padding: const EdgeInsets.all(Sp.l), children: [
            if (pending.isNotEmpty) ...[
              SectionTitle(context.t('requests')),
              for (final m in pending)
                tile(m, [
                  IconButton(tooltip: context.t('reject'), icon: Icon(Icons.close_rounded, color: c.error), onPressed: () => act(() => repo.decide(classId, m.uid, false))),
                  IconButton(tooltip: context.t('approve'), icon: Icon(Icons.check_rounded, color: c.success), onPressed: () => act(() => repo.decide(classId, m.uid, true))),
                ]),
            ],
            SectionTitle(context.t('members_tab')),
            for (final m in approved)
              tile(m, [
                IconButton(
                  tooltip: context.t('remove'),
                  icon: Icon(Icons.person_remove_rounded, color: c.muted),
                  onPressed: () async {
                    if (await confirmDialog(context, context.t('delete_q'), action: context.t('remove'))) act(() => repo.removeMember(classId, m.uid));
                  },
                ),
              ]),
          ]);
        },
      ),
    );
  }
}
