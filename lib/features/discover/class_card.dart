import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/ctx.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/motion.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';

String priceText(BuildContext context, ClassModel c) {
  if (c.price == 0) return context.t('free');
  final n = NumberFormat.decimalPattern('en').format(c.price);
  return context.t(c.priceUnit == 'month' ? 'per_month' : 'per_session', {'n': n});
}

class SubjectBadge extends StatelessWidget {
  const SubjectBadge(this.subject, {super.key, this.size = 48});
  final String subject;
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * 0.3), gradient: LinearGradient(colors: c.button, begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Icon(subjectIcon(subject), color: Colors.white, size: size * 0.5),
    );
  }
}

class ClassCard extends StatelessWidget {
  const ClassCard({super.key, required this.model, required this.onTap, this.index = 0});
  final ClassModel model;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final m = model;
    final full = m.isFull;
    return FadeSlideIn(
      index: index,
      child: Pressable(
        onTap: onTap,
        semanticLabel: m.title,
        child: Container(
          margin: const EdgeInsets.only(bottom: Sp.m),
          padding: const EdgeInsets.all(Sp.l),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Rd.l), border: Border.all(color: c.hairline), boxShadow: c.shadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SubjectBadge(m.subject),
              const SizedBox(width: Sp.m),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.title, style: context.tx.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(m.tutorName, style: context.tx.bodySmall),
                ]),
              ),
              const SizedBox(width: Sp.s),
              Text(priceText(context, m), style: context.tx.labelLarge?.copyWith(color: c.primary, fontFeatures: tabularFigures)),
            ]),
            const SizedBox(height: Sp.m),
            Wrap(spacing: Sp.s, runSpacing: Sp.s, children: [
              Tag(context.t('lv_${m.level}')),
              Tag(context.t('sub_${m.subject}')),
              Tag(wilayaName(m.wilaya, context.lang), icon: Icons.place_rounded),
              if (m.mode != 'in_person') Tag(context.t(m.mode == 'online' ? 'mode_online' : 'mode_both'), icon: Icons.videocam_rounded),
              if (full) Tag(context.t('class_full'), color: c.error),
            ]),
          ]),
        ),
      ),
    );
  }
}
