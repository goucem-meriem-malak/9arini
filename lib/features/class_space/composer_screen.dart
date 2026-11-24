import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config.dart';
import '../../core/ctx.dart';
import '../../core/errors.dart';
import '../../core/theme/tokens.dart';
import '../../core/validators.dart';
import '../../core/widgets/controls.dart';
import '../../data/repo.dart';
import '../../data/providers.dart';
import 'post_card.dart';

class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({super.key, required this.classId});
  final String classId;
  @override
  ConsumerState<ComposerScreen> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<ComposerScreen> {
  static const _types = ['announcement', 'assignment', 'document', 'poll', 'list'];
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final List<TextEditingController> _items = [TextEditingController(), TextEditingController()];
  String _type = 'announcement';
  bool _comments = true, _multi = false, _busy = false;
  DateTime? _due;
  PlatformFile? _file;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    for (final c in _items) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: Repo.allowedExtensions);
    final f = r?.files.single;
    if (f == null) return;
    if (f.size > AppConfig.maxUploadBytes) {
      if (mounted) context.toast(context.t('file_big'));
      return;
    }
    setState(() => _file = f);
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: _due ?? now, firstDate: now.subtract(const Duration(days: 1)), lastDate: now.add(const Duration(days: 365)));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
    setState(() => _due = DateTime(d.year, d.month, d.day, t?.hour ?? 18, t?.minute ?? 0));
  }

  Future<void> _publish() async {
    if (!_form.currentState!.validate()) return;
    final texts = _items.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
    if ((_type == 'poll' && texts.length < 2) || (_type == 'list' && texts.isEmpty) || (_type == 'document' && _file == null)) {
      context.toast(context.t('err_required'));
      return;
    }
    setState(() => _busy = true);
    try {
      final data = <String, dynamic>{
        'type': _type,
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'commentsEnabled': _comments,
        if (_type == 'assignment' && _due != null) 'dueAt': Timestamp.fromDate(_due!),
        if (_type == 'poll') 'options': [for (var i = 0; i < texts.length; i++) {'id': 'o$i', 'text': texts[i]}],
        if (_type == 'poll') 'multi': _multi,
        if (_type == 'list') 'listItems': texts,
      };
      final name = ref.read(profileProvider).valueOrNull!.name;
      await ref.read(repoProvider)!.createPost(widget.classId, data, name, file: _type == 'document' ? _file : null);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) context.toast(errText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('new_post'))),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(Sp.l), children: [
          Wrap(spacing: Sp.s, runSpacing: Sp.s, children: [for (final t in _types) Tag(context.t(t), icon: postIcon(t), selected: _type == t, onTap: () => setState(() => _type = t))]),
          const SizedBox(height: Sp.l),
          PillField(controller: _title, label: context.t('post_title'), maxLength: 120, validator: tr(context, (v) => vRequired(v, max: 120))),
          PillField(controller: _body, label: context.t('post_body'), maxLines: 5, maxLength: 3000),
          if (_type == 'assignment')
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.m),
              child: PillButton(label: _due == null ? context.t('due_date') : context.t('due', {'date': shortDate(context, _due)}), secondary: true, icon: Icons.event_rounded, onPressed: _pickDue),
            ),
          if (_type == 'document')
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.m),
              child: PillButton(label: _file?.name ?? context.t('attach'), secondary: true, icon: Icons.attach_file_rounded, onPressed: _pickFile),
            ),
          if (_type == 'poll' || _type == 'list') ...[
            Text(context.t(_type == 'poll' ? 'options' : 'list'), style: context.tx.labelLarge),
            const SizedBox(height: Sp.s),
            for (var i = 0; i < _items.length; i++) PillField(controller: _items[i], label: '${context.t('item')} ${i + 1}', maxLength: _type == 'poll' ? 80 : 120),
            if (_items.length < (_type == 'poll' ? 8 : 30))
              TextButton.icon(onPressed: () => setState(() => _items.add(TextEditingController())), icon: const Icon(Icons.add_rounded), label: Text(context.t(_type == 'poll' ? 'add_option' : 'add_item'))),
            if (_type == 'poll') SwitchListTile(contentPadding: EdgeInsets.zero, value: _multi, onChanged: (v) => setState(() => _multi = v), title: Text(context.t('multi_choice'))),
          ],
          SwitchListTile(contentPadding: EdgeInsets.zero, value: _comments, activeColor: c.primary, onChanged: (v) => setState(() => _comments = v), title: Text(context.t('allow_comments'))),
          const SizedBox(height: Sp.m),
          PillButton(label: context.t('publish'), loading: _busy, onPressed: _publish),
          const SizedBox(height: Sp.xxl),
        ]),
      ),
    );
  }
}
