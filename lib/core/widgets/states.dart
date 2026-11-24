import 'package:flutter/material.dart';
import '../ctx.dart';
import '../theme/tokens.dart';
import 'controls.dart';

/// Moving highlight for skeletons. Static when reduced motion is on.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.p);
  final double p;
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(bounds.width * p, 0, 0);
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    final c = context.c;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) => LinearGradient(
          colors: [c.surfaceAlt, c.surface.o(c.isDark ? 0.4 : 0.9), c.surfaceAlt],
          stops: const [0.25, 0.5, 0.75],
          transform: _SlideGradient(-1 + 3 * _c.value),
        ).createShader(r),
        child: child,
      ),
    );
  }
}

class Bone extends StatelessWidget {
  const Bone({super.key, this.w, this.h = 14, this.r = 8});
  final double? w;
  final double h, r;
  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(color: context.c.surfaceAlt, borderRadius: BorderRadius.circular(r)),
      );
}

/// Skeleton that matches the real class card layout.
class ClassCardSkeleton extends StatelessWidget {
  const ClassCardSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: Sp.m),
        padding: const EdgeInsets.all(Sp.l),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Rd.l), border: Border.all(color: c.hairline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Bone(w: 48, h: 48, r: 14),
            const SizedBox(width: Sp.m),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Bone(w: 160, h: 16), SizedBox(height: Sp.s), Bone(w: 100)])),
          ]),
          const SizedBox(height: Sp.m),
          const Row(children: [Bone(w: 72, h: 24, r: 12), SizedBox(width: Sp.s), Bone(w: 72, h: 24, r: 12), SizedBox(width: Sp.s), Bone(w: 56, h: 24, r: 12)]),
        ]),
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 4});
  final int count;
  @override
  Widget build(BuildContext context) => Column(children: [for (var i = 0; i < count; i++) const ClassCardSkeleton()]);
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String? body, actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.all(Sp.xxl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [c.surfaceAlt, c.surface], begin: Alignment.topLeft, end: Alignment.bottomRight), border: Border.all(color: c.hairline)),
          child: Icon(icon, size: 40, color: c.primary),
        ),
        const SizedBox(height: Sp.l),
        Text(title, style: context.tx.titleLarge, textAlign: TextAlign.center),
        if (body != null) ...[
          const SizedBox(height: Sp.s),
          Text(body!, style: context.tx.bodyMedium?.copyWith(color: c.muted), textAlign: TextAlign.center),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: Sp.l),
          SizedBox(width: 220, child: PillButton(label: actionLabel!, onPressed: onAction)),
        ],
      ]),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: context.t('err_title'),
        body: context.t('err_d'),
        actionLabel: context.t('retry'),
        onAction: onRetry,
      );
}

/// Shown when data comes from the local cache (no connection).
class OfflineChip extends StatelessWidget {
  const OfflineChip({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: const EdgeInsets.only(bottom: Sp.m),
      padding: const EdgeInsets.symmetric(horizontal: Sp.m, vertical: Sp.s),
      decoration: BoxDecoration(color: c.warning.o(0.12), borderRadius: BorderRadius.circular(Rd.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off_rounded, size: 16, color: c.warning),
        const SizedBox(width: Sp.s),
        Flexible(child: Text(context.t('offline'), style: context.tx.labelMedium?.copyWith(color: c.warning))),
      ]),
    );
  }
}
