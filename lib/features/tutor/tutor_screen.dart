import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class TutorScreen extends ConsumerWidget {
  const TutorScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final async = ref.watch(tutorProvider(id));
    return Scaffold(
      body: async.when(
        loading: () => const Padding(padding: EdgeInsets.all(Sp.l), child: SafeArea(child: ListSkeleton(count: 2))),
        error: (_, __) => ErrorState(onRetry: () => ref.invalidate(tutorProvider(id))),
        data: (t) {
          if (t == null) return Center(child: EmptyState(icon: Icons.person_off_rounded, title: context.t('no_results')));
          final classes = (ref.watch(classesOfProvider(id)).valueOrNull ?? []).where((x) => x.status == 'open').toList();
          final reviews = ref.watch(reviewsProvider(id)).valueOrNull ?? [];
          final me = ref.watch(profileProvider).valueOrNull;
          return ListView(padding: EdgeInsets.zero, children: [
            HeroBackdrop(
              height: 250,
              child: SafeArea(
                bottom: false,
                child: Column(children: [
                  Align(alignment: AlignmentDirectional.centerStart, child: BackButton(color: Colors.white, onPressed: () => context.pop())),
                  Avatar(t.name, size: 80),
                  const SizedBox(height: Sp.s),
                  Text(t.name, style: context.tx.headlineMedium?.copyWith(color: Colors.white)),
                  const SizedBox(height: Sp.xs),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Stars(value: t.ratingAvg, size: 18),
                    const SizedBox(width: Sp.s),
                    Text(context.pl('reviews', t.ratingCount), style: context.tx.bodySmall?.copyWith(color: Colors.white)),
                  ]),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Sp.l),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (t.wilaya.isNotEmpty) InfoRow(Icons.place_rounded, wilayaName(t.wilaya, context.lang)),
                if (t.years > 0) InfoRow(Icons.workspace_premium_rounded, '${context.t('years_exp')}: ${t.years}'),
                if (t.subjects.isNotEmpty) Wrap(spacing: Sp.s, runSpacing: Sp.s, children: [for (final s in t.subjects) Tag(context.t('sub_$s'), icon: subjectIcon(s))]),
                if (t.bio.isNotEmpty) ...[const SizedBox(height: Sp.l), Text(t.bio, style: context.tx.bodyLarge)],
                if (classes.isNotEmpty) ...[
                  SectionTitle(context.t('my_classes')),
                  for (var i = 0; i < classes.length; i++) ClassCard(model: classes[i], index: i, onTap: () => context.push('/class/${classes[i].id}')),
                ],
                SectionTitle(
                  context.t('reviews'),
                  trailing: me != null && !me.isTutor ? TextButton(onPressed: () => _review(context, ref, t, me), child: Text(context.t('write_review'))) : null,
                ),
                if (reviews.isEmpty) Text(context.t('no_reviews'), style: TextStyle(color: c.muted)),
                for (final r in reviews)
                  Container(
                    margin: const EdgeInsets.only(bottom: Sp.m),
                    padding: const EdgeInsets.all(Sp.m),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Rd.m), border: Border.all(color: c.hairline)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: Text(r.authorName, style: context.tx.labelLarge)), Stars(value: r.rating.toDouble(), size: 16)]),
                      if (r.text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: Sp.s), child: Text(r.text, style: context.tx.bodyMedium)),
                    ]),
                  ),
                const SizedBox(height: Sp.xxl),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _review(BuildContext context, WidgetRef ref, TutorProfile t, UserProfile me) async {
    final repo = ref.read(repoProvider)!;
    try {
      final classId = await repo.eligibleClassFor(t.uid);
      if (!context.mounted) return;
      if (classId == null) {
        context.toast(context.t('review_only'));
        return;
      }
      final existing = await repo.myReview(t.uid);
      if (!context.mounted) return;
      var rating = existing?.rating ?? 5;
      final text = TextEditingController(text: existing?.text ?? '');
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, set) => Padding(
            padding: EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, MediaQuery.of(ctx).viewInsets.bottom + Sp.l),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(ctx.t('your_rating'), style: ctx.tx.titleLarge),
              Center(child: Stars(value: rating.toDouble(), onChanged: (v) => set(() => rating = v))),
              PillField(controller: text, label: ctx.t('review_hint'), maxLines: 4, maxLength: 500),
              PillButton(label: ctx.t('submit'), onPressed: () => Navigator.pop(ctx, true)),
            ]),
          ),
        ),
      );
      if (ok == true) {
        await repo.saveReview(t.uid, classId, me.name, rating, text.text, exists: existing != null);
        if (context.mounted) context.toast(context.t('saved'));
      }
      text.dispose();
    } catch (e) {
      if (context.mounted) context.toast(errText(context, e));
    }
  }
}
