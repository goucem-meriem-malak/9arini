import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ctx.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../data/providers.dart';

/// Launch screen: same background and logo position as the native splash, then
/// a spring settle, a light sweep and the wordmark. It runs while Firebase starts.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashState();
}

class _SplashState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  Object? _error;

  @override
  void initState() {
    super.initState();
    _a.forward();
    _go();
  }

  Future<void> _go() async {
    try {
      await Future.wait([ref.read(bootProvider.future), Future<void>.delayed(const Duration(milliseconds: 1000))]);
      final user = await ref.read(authStateProvider.future);
      if (user != null) await ref.read(profileProvider.future);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final reduce = MediaQuery.of(context).disableAnimations;
    final scale = CurvedAnimation(parent: _a, curve: const Interval(0, 0.6, curve: Curves.easeOutBack));
    final sweep = CurvedAnimation(parent: _a, curve: const Interval(0.25, 0.8, curve: Mo.curve));
    final word = CurvedAnimation(parent: _a, curve: const Interval(0.5, 1, curve: Mo.curve));
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(Sp.xl),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(context.t('err_title'), style: context.tx.titleLarge),
                  const SizedBox(height: Sp.l),
                  PillButton(
                    label: context.t('retry'),
                    onPressed: () {
                      setState(() => _error = null);
                      ref.invalidate(bootProvider);
                      _go();
                    },
                  ),
                ]),
              )
            : AnimatedBuilder(
                animation: _a,
                builder: (_, __) {
                  final s = reduce ? 1.0 : 0.82 + 0.18 * scale.value;
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    Opacity(
                      opacity: reduce ? 1 : (_a.value * 4).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: s,
                        child: ShaderMask(
                          blendMode: BlendMode.srcATop,
                          shaderCallback: (r) {
                            final x = -0.5 + 2 * sweep.value;
                            return LinearGradient(
                              begin: Alignment(x - 0.6, -1),
                              end: Alignment(x + 0.1, 1),
                              colors: [Colors.white.o(0), Colors.white.o(reduce ? 0 : 0.55), Colors.white.o(0)],
                            ).createShader(r);
                          },
                          child: Image.asset('assets/logo/logo.png', width: 128, height: 128),
                        ),
                      ),
                    ),
                    const SizedBox(height: Sp.l),
                    Opacity(
                      opacity: reduce ? 1 : word.value,
                      child: Column(children: [
                        Text('9arini', style: context.tx.headlineLarge?.copyWith(letterSpacing: -0.8)),
                        const SizedBox(height: Sp.xs),
                        Text(context.t('tagline'), style: context.tx.bodySmall),
                      ]),
                    ),
                  ]);
                },
              ),
      ),
    );
  }
}
