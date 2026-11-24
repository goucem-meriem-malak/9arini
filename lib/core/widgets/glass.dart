import 'dart:ui';
import 'package:flutter/material.dart';
import '../ctx.dart';
import '../theme/tokens.dart';

/// Frosted panel. Used sparingly (header, forms, nav bar, sheets) because blur is costly.
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.radius = Rd.l, this.padding = const EdgeInsets.all(Sp.l), this.blur = 16});
  final Widget child;
  final double radius, blur;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final r = BorderRadius.circular(radius);
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: r, boxShadow: c.shadow),
        child: ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(color: c.glass, borderRadius: r, border: Border.all(color: c.glassBorder)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Blue-to-green gradient header with soft translucent circles (from the logo palette).
class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop({super.key, this.height = 240, this.child});
  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _HeroPainter(c.hero))),
        if (child != null) Positioned.fill(child: child!),
      ]),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter(this.colors);
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndCorners(rect, bottomLeft: const Radius.circular(40), bottomRight: const Radius.circular(40));
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(rect),
    );
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.1), size.height * 0.5, Paint()..color = Colors.white.o(0.10));
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.95), size.height * 0.38, Paint()..color = Colors.white.o(0.08));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeroPainter old) => old.colors != colors;
}

/// Floating glass tab bar.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({super.key, required this.index, required this.onTap, this.unread = 0});
  final int index, unread;
  final ValueChanged<int> onTap;

  static const _icons = [Icons.search_rounded, Icons.school_rounded, Icons.notifications_rounded, Icons.person_rounded];
  static const _keys = ['discover', 'my_classes', 'notifications', 'profile'];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final r = BorderRadius.circular(Rd.pill);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, Sp.m),
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: r, boxShadow: c.shadow),
          child: ClipRRect(
            borderRadius: r,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: c.isDark ? c.surface.o(0.82) : Colors.white.o(0.82),
                  borderRadius: r,
                  border: Border.all(color: c.glassBorder),
                ),
                child: Row(children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == index,
                        label: context.t(_keys[i]),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(i),
                          child: Center(
                            child: Stack(clipBehavior: Clip.none, children: [
                              AnimatedContainer(
                                duration: Mo.tap,
                                curve: Mo.curve,
                                width: 52,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: i == index ? LinearGradient(colors: c.button) : null,
                                  borderRadius: BorderRadius.circular(Rd.pill),
                                ),
                                child: Icon(_icons[i], size: 24, color: i == index ? Colors.white : c.muted),
                              ),
                              if (i == 2 && unread > 0)
                                PositionedDirectional(
                                  top: -2,
                                  end: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(color: c.error, borderRadius: BorderRadius.circular(Rd.pill)),
                                    child: Text(unread > 9 ? '9+' : '$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
