import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ctx.dart';
import '../theme/tokens.dart';
import 'motion.dart';

class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, this.onPressed, this.loading = false, this.secondary = false, this.danger = false, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final bool loading, secondary, danger;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final enabled = onPressed != null && !loading;
    final fg = secondary ? (danger ? c.error : c.primary) : Colors.white;
    return Pressable(
      semanticLabel: label,
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: Mo.tap,
        curve: Mo.curve,
        height: 52,
        constraints: const BoxConstraints(minWidth: 120),
        decoration: BoxDecoration(
          gradient: (secondary || !enabled) ? null : LinearGradient(colors: c.button),
          color: secondary ? c.surface : (enabled ? null : c.muted.o(0.35)),
          borderRadius: BorderRadius.circular(Rd.pill),
          border: secondary ? Border.all(color: danger ? c.error.o(0.4) : c.hairline) : null,
          boxShadow: (secondary || !enabled) ? null : [BoxShadow(color: c.primary.o(0.25), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: Sp.s)],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: context.tx.labelLarge?.copyWith(color: fg, fontSize: 15))),
                ]),
        ),
      ),
    );
  }
}

class PillField extends StatefulWidget {
  const PillField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.obscure = false,
    this.validator,
    this.keyboard,
    this.maxLines = 1,
    this.maxLength,
    this.action,
    this.autofill,
    this.onChanged,
    this.formatters,
  });
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscure;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboard;
  final int maxLines;
  final int? maxLength;
  final TextInputAction? action;
  final Iterable<String>? autofill;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? formatters;

  @override
  State<PillField> createState() => _PillFieldState();
}

class _PillFieldState extends State<PillField> {
  bool _hide = true;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final multi = widget.maxLines > 1;
    OutlineInputBorder border(Color col, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(multi ? Rd.m : Rd.pill),
          borderSide: BorderSide(color: col, width: w),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.m),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.obscure && _hide,
        keyboardType: widget.keyboard,
        textInputAction: widget.action,
        autofillHints: widget.autofill,
        maxLines: widget.obscure ? 1 : widget.maxLines,
        maxLength: widget.maxLength,
        validator: widget.validator,
        onChanged: widget.onChanged,
        inputFormatters: widget.formatters,
        style: context.tx.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.label,
          hintStyle: TextStyle(color: c.muted),
          filled: true,
          fillColor: c.surface,
          counterText: '',
          prefixIcon: widget.icon == null ? null : Icon(widget.icon, color: c.muted, size: 20),
          suffixIcon: widget.obscure
              ? IconButton(
                  icon: Icon(_hide ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: c.muted, size: 20),
                  onPressed: () => setState(() => _hide = !_hide),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.m + 2),
          border: border(c.hairline),
          enabledBorder: border(c.hairline),
          focusedBorder: border(c.primary, 1.5),
          errorBorder: border(c.error),
          focusedErrorBorder: border(c.error, 1.5),
        ),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.icon, this.selected = false, this.onTap, this.color});
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = selected ? Colors.white : (color ?? c.text);
    final chip = AnimatedContainer(
      duration: Mo.tap,
      constraints: BoxConstraints(minHeight: onTap == null ? 28 : 40),
      padding: const EdgeInsets.symmetric(horizontal: Sp.m, vertical: Sp.xs),
      decoration: BoxDecoration(
        gradient: selected ? LinearGradient(colors: c.button) : null,
        color: selected ? null : c.surfaceAlt,
        borderRadius: BorderRadius.circular(Rd.pill),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: Sp.xs)],
        Text(label, style: context.tx.labelMedium?.copyWith(color: fg)),
      ]),
    );
    return onTap == null ? chip : Pressable(onTap: onTap, semanticLabel: label, child: chip);
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, this.size = 44});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    String first(String w) => String.fromCharCode(w.runes.first);
    final initials = parts.isEmpty ? '?' : (parts.length == 1 ? first(parts[0]) : first(parts[0]) + first(parts[1]));
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: c.hero, begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Text(initials.toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.38)),
    );
  }
}

class Stars extends StatelessWidget {
  const Stars({super.key, required this.value, this.size = 18, this.onChanged});
  final double value;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 1; i <= 5; i++)
        GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(i),
          child: Padding(
            padding: EdgeInsets.all(onChanged == null ? 0 : Sp.xs),
            child: Icon(
              value >= i ? Icons.star_rounded : (value >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
              size: onChanged == null ? size : 36,
              color: const Color(0xFFF5A623),
            ),
          ),
        ),
    ]);
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Sp.xl, bottom: Sp.m),
        child: Row(children: [
          Expanded(child: Text(text, style: context.tx.titleMedium)),
          if (trailing != null) trailing!,
        ]),
      );
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Sp.m),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: context.c.primary),
          const SizedBox(width: Sp.m),
          Expanded(child: Text(text, style: context.tx.bodyMedium)),
        ]),
      );
}

class Picked {
  const Picked(this.value);
  final String? value;
}

/// Bottom sheet list. Returns null when dismissed, Picked(null) when "Any" is chosen.
Future<Picked?> pickOne(BuildContext context, String title, List<(String, String)> options, {String? selected, bool allowAny = false}) {
  return showModalBottomSheet<Picked>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, sc) => Column(children: [
        Padding(padding: const EdgeInsets.all(Sp.l), child: Align(alignment: AlignmentDirectional.centerStart, child: Text(title, style: ctx.tx.titleLarge))),
        Expanded(
          child: ListView(controller: sc, children: [
            if (allowAny) ListTile(title: Text(ctx.t('any')), onTap: () => Navigator.pop(ctx, const Picked(null))),
            for (final o in options)
              ListTile(
                title: Text(o.$2),
                trailing: o.$1 == selected ? Icon(Icons.check_rounded, color: ctx.c.primary) : null,
                onTap: () => Navigator.pop(ctx, Picked(o.$1)),
              ),
          ]),
        ),
      ]),
    ),
  );
}

Future<bool> confirmDialog(BuildContext context, String message, {String? action}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t('cancel'))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action ?? ctx.t('delete'), style: TextStyle(color: ctx.c.error))),
      ],
    ),
  );
  return r ?? false;
}
