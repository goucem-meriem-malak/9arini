import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ctx.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/states.dart';
import '../../data/catalog.dart';
import '../../data/discover_ctrl.dart';
import '../../data/providers.dart';
import 'class_card.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(discoverProvider);
    final ctl = ref.read(discoverProvider.notifier);
    final name = ref.watch(profileProvider).valueOrNull?.name.split(' ').first ?? '';
    final items = st.visible;
    final f = st.filters;

    return RefreshIndicator(
      onRefresh: ctl.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 400) ctl.loadMore();
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HeroBackdrop(
                height: 232,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.l, Sp.l, Sp.l, Sp.l),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(context.t('hello', {'name': name}), style: context.tx.headlineMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: Sp.xs),
                      Text(context.t('tagline'), style: context.tx.bodySmall?.copyWith(color: Colors.white.o(0.85))),
                      const Spacer(),
                      Row(children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: Sp.l),
                            decoration: BoxDecoration(color: context.c.surface, borderRadius: BorderRadius.circular(Rd.pill), boxShadow: context.c.shadow),
                            child: Row(children: [
                              Icon(Icons.search_rounded, color: context.c.primary),
                              const SizedBox(width: Sp.s),
                              Expanded(
                                child: TextField(
                                  onChanged: (v) => ctl.setFilters(f.copyWith(query: v)),
                                  style: context.tx.bodyMedium,
                                  decoration: InputDecoration(hintText: context.t('search_hint'), border: InputBorder.none, isDense: true, hintStyle: TextStyle(color: context.c.muted)),
                                ),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(width: Sp.s),
                        Pressable(
                          semanticLabel: context.t('filters'),
                          onTap: () => _filterSheet(context, ref),
                          child: Stack(clipBehavior: Clip.none, children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(color: context.c.surface, shape: BoxShape.circle, boxShadow: context.c.shadow),
                              child: Icon(Icons.tune_rounded, color: context.c.primary),
                            ),
                            if (f.activeCount > 0)
                              PositionedDirectional(
                                top: -2,
                                end: -2,
                                child: CircleAvatar(radius: 10, backgroundColor: context.c.error, child: Text('${f.activeCount}', style: const TextStyle(color: Colors.white, fontSize: 11))),
                              ),
                          ]),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.s),
                  children: [
                    for (final s in subjectIds)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: Sp.s),
                        child: Tag(context.t('sub_$s'), icon: subjectIcon(s), selected: f.subject == s, onTap: () => ctl.setFilters(f.copyWith(subject: () => f.subject == s ? null : s))),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, 0),
              sliver: SliverToBoxAdapter(child: st.fromCache && items.isNotEmpty ? const OfflineChip() : const SizedBox.shrink()),
            ),
            if (items.isEmpty && st.loading)
              const SliverPadding(padding: EdgeInsets.symmetric(horizontal: Sp.l), sliver: SliverToBoxAdapter(child: ListSkeleton()))
            else if (items.isEmpty && st.error != null)
              SliverToBoxAdapter(child: ErrorState(onRetry: ctl.refresh))
            else if (items.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: context.t('no_results'),
                  body: context.t('no_results_d'),
                  actionLabel: f.activeCount > 0 || f.query.isNotEmpty ? context.t('reset') : null,
                  onAction: () => ctl.setFilters(const Filters()),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Sp.l),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => ClassCard(model: items[i], index: i, onTap: () => context.push('/class/${items[i].id}')),
                ),
              ),
            if (items.isNotEmpty && st.loading) const SliverPadding(padding: EdgeInsets.symmetric(horizontal: Sp.l), sliver: SliverToBoxAdapter(child: ClassCardSkeleton())),
            if (items.isNotEmpty && !st.loading && st.hasMore)
              SliverToBoxAdapter(child: Center(child: TextButton(onPressed: ctl.loadMore, child: Text(context.t('load_more'))))),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  void _filterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _FilterSheet());
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();
  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late Filters _f = ref.read(discoverProvider).filters;
  late final _price = TextEditingController(text: _f.maxPrice?.toString() ?? '');

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Widget _row(String label, String value, VoidCallback onTap) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: context.tx.labelLarge),
        subtitle: Text(value, style: TextStyle(color: context.c.muted)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    return Padding(
      padding: EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, MediaQuery.of(context).viewInsets.bottom + Sp.l),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(context.t('filters'), style: context.tx.titleLarge),
          _row(context.t('wilaya'), _f.wilaya == null ? context.t('any') : wilayaName(_f.wilaya!, lang), () async {
            final p = await pickOne(context, context.t('wilaya'), wilayaOptions(lang), selected: _f.wilaya, allowAny: true);
            if (p != null) setState(() => _f = _f.copyWith(wilaya: () => p.value));
          }),
          _row(context.t('level'), _f.level == null ? context.t('any') : context.t('lv_${_f.level}'), () async {
            final p = await pickOne(context, context.t('level'), [for (final l in levelIds) (l, context.t('lv_$l'))], selected: _f.level, allowAny: true);
            if (p != null) setState(() => _f = _f.copyWith(level: () => p.value));
          }),
          _row(context.t('subject'), _f.subject == null ? context.t('any') : context.t('sub_${_f.subject}'), () async {
            final p = await pickOne(context, context.t('subject'), [for (final s in subjectIds) (s, context.t('sub_$s'))], selected: _f.subject, allowAny: true);
            if (p != null) setState(() => _f = _f.copyWith(subject: () => p.value));
          }),
          _row(context.t('mode'), _f.mode == null ? context.t('any') : context.t('mode_${_f.mode}'), () async {
            final p = await pickOne(context, context.t('mode'), [for (final m in modeIds) (m, context.t('mode_$m'))], selected: _f.mode, allowAny: true);
            if (p != null) setState(() => _f = _f.copyWith(mode: () => p.value));
          }),
          const SizedBox(height: Sp.s),
          PillField(controller: _price, label: context.t('max_price'), icon: Icons.payments_rounded, keyboard: TextInputType.number, onChanged: (v) => _f = _f.copyWith(maxPrice: () => int.tryParse(v))),
          Row(children: [
            Expanded(
              child: PillButton(
                label: context.t('reset'),
                secondary: true,
                onPressed: () {
                  ref.read(discoverProvider.notifier).setFilters(Filters(query: _f.query));
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: Sp.m),
            Expanded(
              child: PillButton(
                label: context.t('apply'),
                onPressed: () {
                  ref.read(discoverProvider.notifier).setFilters(_f);
                  Navigator.pop(context);
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
