import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ctx.dart';
import '../../core/errors.dart';
import '../../core/theme/tokens.dart';
import '../../core/validators.dart';
import '../../core/widgets/controls.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class ClassFormScreen extends ConsumerStatefulWidget {
  const ClassFormScreen({super.key, this.classId});
  final String? classId;
  @override
  ConsumerState<ClassFormScreen> createState() => _ClassFormState();
}

class _ClassFormState extends ConsumerState<ClassFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController(text: '0');
  final _commune = TextEditingController();
  final _link = TextEditingController();
  final _schedule = TextEditingController();
  final _capacity = TextEditingController(text: '10');
  String _subject = 'math', _level = 'bac', _unit = 'month', _mode = 'in_person', _wilaya = '';
  bool _busy = false, _loaded = false;
  ClassModel? _existing;

  @override
  void dispose() {
    for (final c in [_title, _desc, _price, _commune, _link, _schedule, _capacity]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    _loaded = true;
    final id = widget.classId;
    if (id == null) return;
    final repo = ref.read(repoProvider)!;
    final m = await repo.classStream(id).first;
    final link = await repo.onlineLink(id).first.catchError((_) => '');
    if (m == null || !mounted) return;
    setState(() {
      _existing = m;
      _title.text = m.title;
      _desc.text = m.description;
      _price.text = '${m.price}';
      _commune.text = m.commune;
      _schedule.text = m.schedule;
      _capacity.text = '${m.capacity}';
      _subject = m.subject;
      _level = m.level;
      _unit = m.priceUnit;
      _mode = m.mode;
      _wilaya = m.wilaya;
      _link.text = link;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_wilaya.isEmpty) {
      context.toast(context.t('wilaya'));
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(repoProvider)!;
      final data = {
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'subject': _subject,
        'level': _level,
        'price': int.parse(_price.text.trim()),
        'priceUnit': _unit,
        'wilaya': _wilaya,
        'commune': _commune.text.trim(),
        'mode': _mode,
        'schedule': _schedule.text.trim(),
        'capacity': int.parse(_capacity.text.trim()),
        'status': _existing?.status ?? 'open',
      };
      final link = _mode == 'in_person' ? '' : _link.text.trim();
      if (_existing == null) {
        final name = ref.read(profileProvider).valueOrNull!.name;
        final id = await repo.createClass(data, link, name);
        if (mounted) context.pushReplacement('/class/$id');
      } else {
        await repo.updateClass(_existing!.id, data, link);
        if (mounted) {
          context.toast(context.t('saved'));
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) context.toast(errText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _pick(String label, String value, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: Sp.m),
        child: Pressable(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.s),
            decoration: BoxDecoration(color: context.c.surface, borderRadius: BorderRadius.circular(Rd.pill), border: Border.all(color: context.c.hairline)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(label, style: context.tx.bodySmall), Text(value.isEmpty ? '—' : value, style: context.tx.bodyLarge)])),
              Icon(Icons.expand_more_rounded, color: context.c.muted),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!_loaded) _load();
    final lang = context.lang;
    return Scaffold(
      appBar: AppBar(title: Text(context.t(widget.classId == null ? 'new_class' : 'edit_class'))),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(Sp.l), children: [
          PillField(controller: _title, label: context.t('class_title'), icon: Icons.title_rounded, maxLength: 80, validator: tr(context, (v) => (v == null || v.trim().length < 3) ? 'err_required' : null)),
          _pick(context.t('subject'), context.t('sub_$_subject'), () async {
            final p = await pickOne(context, context.t('subject'), [for (final s in subjectIds) (s, context.t('sub_$s'))], selected: _subject);
            if (p?.value != null) setState(() => _subject = p!.value!);
          }),
          _pick(context.t('level'), context.t('lv_$_level'), () async {
            final p = await pickOne(context, context.t('level'), [for (final l in levelIds) (l, context.t('lv_$l'))], selected: _level);
            if (p?.value != null) setState(() => _level = p!.value!);
          }),
          _pick(context.t('wilaya'), _wilaya.isEmpty ? '' : wilayaName(_wilaya, lang), () async {
            final p = await pickOne(context, context.t('wilaya'), wilayaOptions(lang), selected: _wilaya);
            if (p?.value != null) setState(() => _wilaya = p!.value!);
          }),
          PillField(controller: _commune, label: context.t('commune'), icon: Icons.location_city_rounded, maxLength: 40),
          _pick(context.t('mode'), context.t('mode_$_mode'), () async {
            final p = await pickOne(context, context.t('mode'), [for (final m in modeIds) (m, context.t('mode_$m'))], selected: _mode);
            if (p?.value != null) setState(() => _mode = p!.value!);
          }),
          if (_mode != 'in_person') PillField(controller: _link, label: context.t('link'), icon: Icons.link_rounded, keyboard: TextInputType.url, maxLength: 300, validator: (v) => (v == null || v.isEmpty || v.startsWith('https://')) ? null : context.t('err_required')),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: PillField(controller: _price, label: context.t('price'), icon: Icons.payments_rounded, keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly], maxLength: 7, validator: tr(context, (v) => vInt(v, max: 1000000)))),
            const SizedBox(width: Sp.s),
            Expanded(
              flex: 2,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [ButtonSegment(value: 'month', label: Text(context.t('unit_month'))), ButtonSegment(value: 'session', label: Text(context.t('unit_session')))],
                selected: {_unit},
                onSelectionChanged: (s) => setState(() => _unit = s.first),
              ),
            ),
          ]),
          PillField(controller: _capacity, label: context.t('capacity'), icon: Icons.event_seat_rounded, keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly], maxLength: 3, validator: tr(context, (v) => vInt(v, min: 1, max: 200))),
          PillField(controller: _schedule, label: context.t('schedule_hint'), icon: Icons.schedule_rounded, maxLength: 120),
          PillField(controller: _desc, label: context.t('description'), maxLines: 5, maxLength: 1500),
          const SizedBox(height: Sp.s),
          PillButton(label: context.t('save'), loading: _busy, onPressed: _save),
          if (_existing != null) ...[
            const SizedBox(height: Sp.m),
            PillButton(
              label: context.t(_existing!.status == 'open' ? 'close_class' : 'reopen_class'),
              secondary: true,
              onPressed: () async {
                await ref.read(repoProvider)!.setClassOpen(_existing!.id, _existing!.status != 'open');
                if (context.mounted) context.pop();
              },
            ),
          ],
          const SizedBox(height: Sp.xxl),
        ]),
      ),
    );
  }
}
