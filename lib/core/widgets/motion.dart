import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';

/// Fade in + 8px upward move, staggered by index. Skipped with reduced motion.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final i = index > 8 ? 8 : index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + 40 * i),
      curve: Mo.curve,
      builder: (_, v, c) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 8 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

/// Route transition: soft fade with a small upward slide (decelerating curve).
Page<void> fadeSlide(GoRouterState s, Widget child) => CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: Mo.screen,
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (ctx, a, sa, c) {
        if (MediaQuery.of(ctx).disableAnimations) return c;
        final curved = CurvedAnimation(parent: a, curve: Mo.curve);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
            child: c,
          ),
        );
      },
    );

/// Press feedback: scale 0.98 + light haptic.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.semanticLabel});
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.onTap != null;
    return Semantics(
      button: on,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: on ? (_) => setState(() => _down = true) : null,
        onTapCancel: on ? () => setState(() => _down = false) : null,
        onTapUp: on ? (_) => setState(() => _down = false) : null,
        onTap: on
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: Mo.tap,
          curve: Mo.curve,
          child: widget.child,
        ),
      ),
    );
  }
}
