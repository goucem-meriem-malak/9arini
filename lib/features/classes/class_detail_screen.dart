import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/ctx.dart';
import '../../core/errors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/states.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../discover/class_card.dart';

class ClassDetailScreen extends ConsumerWidget {
  const ClassDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(classProvider(id));
    return Scaffold(
      body: async.when(
        data: (c) => c == null
            ? Center(child: EmptyState(icon: Icons.search_off_rounded, title: context.t('no_results'), actionLabel: context.t('retry'), onAction: () => context.pop()))
            : _Body(model: c),
        loading: () => const Padding(padding: EdgeInsets.all(Sp.l), child: SafeArea(child: ListSkeleton(count: 2))),
        error: (e, _) => ErrorState(onRetry: () => ref.invalidate(classProvider(id))),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.model});
  final ClassModel model;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) context.toast(errText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join(UserProfile p) async {
    if (FirebaseAuth.instance.currentUser?.emailVerified != true) {
      context.toast(context.t('verify_first'));
      return;
    }
    var child = '';
    if (p.isParent) {
      final kids = ref.read(childrenProvider).valueOrNull ?? [];
      final r = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.all(Sp.l), child: Align(alignment: AlignmentDirectional.centerStart, child: Text(ctx.t('joining_for'), style: ctx.tx.titleLarge))),
            ListTile(title: Text(ctx.t('myself')), onTap: () => Navigator.pop(ctx, '')),
            for (final k in kids) ListTile(title: Text(k.name), subtitle: Text(ctx.t('lv_${k.level}')), onTap: () => Navigator.pop(ctx, k.name)),
            ListTile(leading: const Icon(Icons.add_rounded), title: Text(ctx.t('add_child')), onTap: () {
              Navigator.pop(ctx, null);
              context.push('/children');
            }),
          ]),
        ),
      );
      if (r == null) return;
      child = r;
    }
    await _run(() => ref.read(repoProvider)!.requestJoin(widget.model, p, child));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final m = widget.model;
    final prof = ref.watch(profileProvider).valueOrNull;
    final mem = ref.watch(membershipProvider(m.id)).valueOrNull;
    final owner = prof?.uid == m.tutorId;
    final approved = mem?.status == 'approved';
    final link = (owner || approved) && m.mode != 'in_person' ? ref.watch(linkProvider(m.id)).valueOrNull : null;
    final tutor = ref.watch(tutorProvider(m.tutorId)).valueOrNull;

    Widget action;
    if (owner) {
      action = Row(children: [
        Expanded(child: PillButton(label: context.t('manage'), secondary: true, icon: Icons.edit_rounded, onPressed: () => context.push('/class-form?id=${m.id}'))),
        const SizedBox(width: Sp.m),
        Expanded(flex: 2, child: PillButton(label: context.t('open_space'), onPressed: () => context.push('/class/${m.id}/space'))),
      ]);
    } else if (prof != null && prof.isTutor) {
      action = const SizedBox.shrink();
    } else if (mem == null) {
      final blocked = m.status != 'open' || m.isFull;
      action = PillButton(
        label: m.isFull ? context.t('class_full') : (m.status != 'open' ? context.t('class_closed') : context.t('join')),
        loading: _busy,
        onPressed: blocked || prof == null ? null : () => _join(prof),
      );
    } else if (mem.status == 'pending') {
      action = Row(children: [
        Expanded(child: Text(context.t('status_pending'), style: context.tx.labelLarge?.copyWith(color: c.warning))),
        PillButton(label: context.t('cancel_request'), secondary: true, loading: _busy, onPressed: () => _run(() => ref.read(repoProvider)!.leave(m.id))),
      ]);
    } else if (mem.status == 'approved') {
      action = Row(children: [
        PillButton(
          label: context.t('leave'),
          secondary: true,
          danger: true,
          onPressed: () async {
            if (await confirmDialog(context, context.t('leave_q'), action: context.t('leave'))) _run(() => ref.read(repoProvider)!.leave(m.id));
          },
        ),
        const SizedBox(width: Sp.m),
        Expanded(child: PillButton(label: context.t('open_space'), onPressed: () => context.push('/class/${m.id}/space'))),
      ]);
    } else {
      action = Center(child: Text(context.t('status_rejected'), style: context.tx.labelLarge?.copyWith(color: c.error)));
    }

    return Column(children: [
      Expanded(
        child: ListView(padding: EdgeInsets.zero, children: [
          HeroBackdrop(
            height: 230,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Sp.s, Sp.xs, Sp.l, Sp.l),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  BackButton(color: Colors.white, onPressed: () => context.pop()),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: Sp.m),
                    child: Row(children: [
                      SubjectBadge(m.subject, size: 56),
                      const SizedBox(width: Sp.m),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.title, style: context.tx.headlineMedium?.copyWith(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                          GestureDetector(
                            onTap: () => context.push('/tutor/${m.tutorId}'),
                            child: Padding(padding: const EdgeInsets.symmetric(vertical: Sp.xs), child: Text(m.tutorName, style: context.tx.bodyMedium?.copyWith(color: Colors.white.o(0.9), decoration: TextDecoration.underline, decorationColor: Colors.white.o(0.6)))),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Sp.l),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: Sp.s, runSpacing: Sp.s, children: [
                Tag(context.t('lv_${m.level}')),
                Tag(context.t('sub_${m.subject}')),
                Tag(context.t('mode_${m.mode}'), icon: m.mode == 'in_person' ? Icons.groups_rounded : Icons.videocam_rounded),
              ]),
              const SizedBox(height: Sp.l),
              InfoRow(Icons.payments_rounded, priceText(context, m)),
              InfoRow(Icons.place_rounded, [wilayaName(m.wilaya, context.lang), if (m.commune.isNotEmpty) m.commune].join(' · ')),
              if (m.schedule.isNotEmpty) InfoRow(Icons.schedule_rounded, m.schedule),
              InfoRow(Icons.event_seat_rounded, '${context.t('seats')}: ${m.members}/${m.capacity}'),
              if (link != null && link.isNotEmpty)
                Pressable(
                  onTap: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
                  child: Container(
                    padding: const EdgeInsets.all(Sp.m),
                    decoration: BoxDecoration(color: c.primary.o(0.1), borderRadius: BorderRadius.circular(Rd.m)),
                    child: Row(children: [Icon(Icons.videocam_rounded, color: c.primary), const SizedBox(width: Sp.m), Expanded(child: Text(context.t('online_link'), style: context.tx.labelLarge?.copyWith(color: c.primary))), Icon(Icons.open_in_new_rounded, color: c.primary, size: 18)]),
                  ),
                ),
              if (m.description.isNotEmpty) ...[
                SectionTitle(context.t('about_class')),
                Text(m.description, style: context.tx.bodyLarge),
              ],
              SectionTitle(context.t('tutor')),
              Pressable(
                onTap: () => context.push('/tutor/${m.tutorId}'),
                child: Container(
                  padding: const EdgeInsets.all(Sp.m),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Rd.l), border: Border.all(color: c.hairline)),
                  child: Row(children: [
                    Avatar(m.tutorName),
                    const SizedBox(width: Sp.m),
                    Expanded(child: Text(m.tutorName, style: context.tx.titleMedium)),
                    if (tutor != null && tutor.ratingCount > 0) ...[const Icon(Icons.star_rounded, color: Color(0xFFF5A623), size: 20), const SizedBox(width: 2), Text(tutor.ratingAvg.toStringAsFixed(1), style: context.tx.labelLarge)],
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
      if (action is! SizedBox)
        Container(
          decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.hairline))),
          padding: const EdgeInsets.all(Sp.l),
          child: SafeArea(top: false, child: action),
        ),
    ]);
  }
}
