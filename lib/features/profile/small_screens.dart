import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ctx.dart';
import '../../core/errors.dart';
import '../../core/theme/tokens.dart';
import '../../core/validators.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/states.dart';
import '../../data/catalog.dart';
import '../../data/providers.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(childrenProvider);
    final c = context.c;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('children'))),
      floatingActionButton: PillButton(label: context.t('add_child'), icon: Icons.add_rounded, onPressed: () => _add(context, ref)),
      body: async.when(
        loading: () => const Padding(padding: EdgeInsets.all(Sp.l), child: ListSkeleton(count: 2)),
        error: (_, __) => ErrorState(onRetry: () => ref.invalidate(childrenProvider)),
        data: (list) => list.isEmpty
            ? Center(child: EmptyState(icon: Icons.child_care_rounded, title: context.t('children'), body: context.t('add_child')))
            : ListView(padding: const EdgeInsets.all(Sp.l), children: [
                for (final k in list)
                  Container(
                    margin: const EdgeInsets.only(bottom: Sp.s),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Rd.m), border: Border.all(color: c.hairline)),
                    child: ListTile(
                      leading: Avatar(k.name, size: 40),
                      title: Text(k.name),
                      subtitle: Text(context.t('lv_${k.level}')),
                      trailing: IconButton(tooltip: context.t('remove'), icon: Icon(Icons.delete_outline_rounded, color: c.error), onPressed: () => ref.read(repoProvider)!.removeChild(k.id)),
                    ),
                  ),
              ]),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final form = GlobalKey<FormState>();
    var level = 'p1';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, MediaQuery.of(ctx).viewInsets.bottom + Sp.l),
          child: Form(
            key: form,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(ctx.t('add_child'), style: ctx.tx.titleLarge),
              const SizedBox(height: Sp.m),
              PillField(controller: name, label: ctx.t('child_name'), maxLength: 60, validator: tr(ctx, (v) => vRequired(v, max: 60))),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(ctx.t('level')),
                subtitle: Text(ctx.t('lv_$level')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final r = await pickOne(ctx, ctx.t('level'), [for (final l in levelIds) (l, ctx.t('lv_$l'))], selected: level);
                  if (r?.value != null) set(() => level = r!.value!);
                },
              ),
              PillButton(
                label: ctx.t('save'),
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  try {
                    await ref.read(repoProvider)!.addChild(name.text, level);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) ctx.toast(errText(ctx, e));
                  }
                },
              ),
            ]),
          ),
        ),
      ),
    );
    name.dispose();
  }
}

class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(blocksProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.t('blocked_users'))),
      body: async.when(
        loading: () => const Padding(padding: EdgeInsets.all(Sp.l), child: ListSkeleton(count: 2)),
        error: (_, __) => ErrorState(onRetry: () => ref.invalidate(blocksProvider)),
        data: (m) => m.isEmpty
            ? Center(child: EmptyState(icon: Icons.shield_outlined, title: context.t('no_blocked')))
            : ListView(children: [
                for (final e in m.entries)
                  ListTile(
                    leading: Avatar(e.value, size: 40),
                    title: Text(e.value),
                    trailing: TextButton(onPressed: () => ref.read(repoProvider)!.unblock(e.key), child: Text(context.t('unblock'))),
                  ),
              ]),
      ),
    );
  }
}

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});
  @override
  ConsumerState<ExportScreen> createState() => _ExportState();
}

class _ExportState extends ConsumerState<ExportScreen> {
  late final Future<String> _data = ref.read(repoProvider)!.exportData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('my_data'))),
      body: FutureBuilder<String>(
        future: _data,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(onRetry: () => setState(() {}));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return Column(children: [
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(Sp.l), child: SelectableText(snap.data!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)))),
            Padding(
              padding: const EdgeInsets.all(Sp.l),
              child: SafeArea(
                top: false,
                child: PillButton(
                  label: context.t('copy'),
                  icon: Icons.copy_rounded,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: snap.data!));
                    if (context.mounted) context.toast(context.t('copied'));
                  },
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
