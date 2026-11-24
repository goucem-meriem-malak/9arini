import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/config.dart';
import '../../core/ctx.dart';
import '../../core/errors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/push.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap, {String? subtitle, bool danger = false}) {
    final c = context.c;
    return ListTile(
      leading: Icon(icon, color: danger ? c.error : c.primary),
      title: Text(title, style: context.tx.bodyLarge?.copyWith(color: danger ? c.error : null)),
      subtitle: subtitle == null ? null : Text(subtitle, style: context.tx.bodySmall),
      trailing: Icon(Icons.chevron_right_rounded, color: c.muted),
      onTap: onTap,
    );
  }

  Widget _group(BuildContext context, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: Sp.l),
        decoration: BoxDecoration(color: context.c.surface, borderRadius: BorderRadius.circular(Rd.l), border: Border.all(color: context.c.hairline)),
        child: Column(children: children),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final p = ref.watch(profileProvider).valueOrNull;
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    if (p == null) return const SizedBox.shrink();

    return ListView(padding: EdgeInsets.zero, children: [
      HeroBackdrop(
        height: 220,
        child: SafeArea(
          bottom: false,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Avatar(p.name, size: 76),
            const SizedBox(height: Sp.s),
            Text(p.name, style: context.tx.headlineMedium?.copyWith(color: Colors.white)),
            const SizedBox(height: Sp.xs),
            Tag(context.t('role_${p.role}')),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(Sp.l, Sp.l, Sp.l, 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (p.isTutor || p.isParent)
            _group(context, [
              if (p.isTutor) _tile(context, Icons.badge_rounded, context.t('edit_tutor'), () => _editTutor(context, ref, p)),
              if (p.isParent) _tile(context, Icons.family_restroom_rounded, context.t('children'), () => context.push('/children')),
            ]),
          Text(context.t('theme'), style: context.tx.labelLarge),
          const SizedBox(height: Sp.s),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ThemeMode.light, label: Text(context.t('light'))),
              ButtonSegment(value: ThemeMode.dark, label: Text(context.t('dark'))),
              ButtonSegment(value: ThemeMode.system, label: Text(context.t('system'))),
            ],
            selected: {mode},
            onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: Sp.l),
          Text(context.t('language'), style: context.tx.labelLarge),
          const SizedBox(height: Sp.s),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [ButtonSegment(value: 'ar', label: Text('العربية')), ButtonSegment(value: 'fr', label: Text('Français')), ButtonSegment(value: 'en', label: Text('English'))],
            selected: {locale.languageCode},
            onSelectionChanged: (s) => ref.read(localeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: Sp.l),
          _group(context, [
            _tile(context, Icons.block_rounded, context.t('blocked_users'), () => context.push('/blocked')),
            _tile(context, Icons.download_rounded, context.t('export_data'), () => context.push('/export'), subtitle: context.t('export_d')),
            _tile(context, Icons.description_rounded, context.t('terms'), () => context.push('/legal/terms')),
            _tile(context, Icons.privacy_tip_rounded, context.t('privacy'), () => context.push('/legal/privacy')),
            _tile(context, Icons.info_outline_rounded, context.t('about'), () => _about(context)),
          ]),
          _group(context, [
            _tile(context, Icons.logout_rounded, context.t('sign_out'), () async {
              await PushService.stop();
              try {
                await GoogleSignIn().signOut();
              } catch (_) {}
              await FirebaseAuth.instance.signOut();
            }),
            _tile(context, Icons.delete_forever_rounded, context.t('delete_account'), () async {
              if (!await confirmDialog(context, context.t('delete_confirm'), action: context.t('delete'))) return;
              try {
                await PushService.stop();
                await ref.read(repoProvider)!.deleteAccount();
                try {
                  await GoogleSignIn().signOut();
                } catch (_) {}
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                if (context.mounted) context.toast(errText(context, e));
              }
            }, subtitle: context.t('delete_d'), danger: true),
          ]),
          Center(child: Text('9arini 1.0.0', style: context.tx.bodySmall?.copyWith(color: c.muted))),
        ]),
      ),
    ]);
  }

  void _about(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/logo/logo.png', width: 72),
          const SizedBox(height: Sp.m),
          Text('9arini', style: ctx.tx.headlineMedium),
          Text('${ctx.t('version')} 1.0.0', style: ctx.tx.bodySmall),
          if (AppConfig.supportEmail.isNotEmpty) Padding(padding: const EdgeInsets.only(top: Sp.m), child: SelectableText('${ctx.t('support')}: ${AppConfig.supportEmail}')),
        ]),
      ),
    );
  }

  Future<void> _editTutor(BuildContext context, WidgetRef ref, UserProfile p) async {
    final repo = ref.read(repoProvider)!;
    final t = await ref.read(tutorProvider(p.uid).future);
    if (!context.mounted) return;
    final bio = TextEditingController(text: t?.bio ?? '');
    final years = TextEditingController(text: '${t?.years ?? 0}');
    var wilaya = t?.wilaya ?? '';
    final subjects = {...?t?.subjects};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, MediaQuery.of(ctx).viewInsets.bottom + Sp.l),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(ctx.t('edit_tutor'), style: ctx.tx.titleLarge),
              const SizedBox(height: Sp.m),
              PillField(controller: bio, label: ctx.t('bio'), maxLines: 4, maxLength: 600),
              PillField(controller: years, label: ctx.t('years_exp'), keyboard: TextInputType.number, maxLength: 2),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(ctx.t('wilaya')),
                subtitle: Text(wilaya.isEmpty ? '—' : wilayaName(wilaya, ctx.lang)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final r = await pickOne(ctx, ctx.t('wilaya'), wilayaOptions(ctx.lang), selected: wilaya);
                  if (r?.value != null) set(() => wilaya = r!.value!);
                },
              ),
              Text(ctx.t('subjects'), style: ctx.tx.labelLarge),
              const SizedBox(height: Sp.s),
              Wrap(spacing: Sp.s, runSpacing: Sp.s, children: [
                for (final s in subjectIds) Tag(ctx.t('sub_$s'), icon: subjectIcon(s), selected: subjects.contains(s), onTap: () => set(() => subjects.contains(s) ? subjects.remove(s) : subjects.add(s))),
              ]),
              const SizedBox(height: Sp.l),
              PillButton(
                label: ctx.t('save'),
                onPressed: () async {
                  try {
                    await repo.saveTutor(bio: bio.text, subjects: subjects.toList(), wilaya: wilaya, years: int.tryParse(years.text.trim()) ?? 0);
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
    bio.dispose();
    years.dispose();
  }
}
