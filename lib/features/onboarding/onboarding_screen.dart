import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ctx.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../data/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _i = 0;
  static const _icons = [Icons.travel_explore_rounded, Icons.how_to_reg_rounded, Icons.forum_rounded];

  void _finish() {
    ref.read(onboardedProvider.notifier).done();
    context.go('/signup');
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: Stack(children: [
        const Positioned(top: 0, left: 0, right: 0, child: HeroBackdrop(height: 360)),
        SafeArea(
          child: Column(children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: _finish, child: Text(context.t('skip'), style: const TextStyle(color: Colors.white))),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: 3,
                onPageChanged: (v) => setState(() => _i = v),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
                  child: Column(children: [
                    const SizedBox(height: Sp.xl),
                    GlassPanel(radius: 44, padding: const EdgeInsets.all(Sp.xl), child: Icon(_icons[i], size: 72, color: Colors.white)),
                    const Spacer(),
                    GlassPanel(
                      child: Column(children: [
                        Text(context.t('onb${i + 1}_t'), style: context.tx.headlineMedium, textAlign: TextAlign.center),
                        const SizedBox(height: Sp.s),
                        Text(context.t('onb${i + 1}_d'), style: context.tx.bodyLarge?.copyWith(color: c.muted), textAlign: TextAlign.center),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Sp.xl),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: Mo.tap,
                      curve: Mo.curve,
                      margin: const EdgeInsets.all(Sp.xs),
                      width: i == _i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(color: i == _i ? c.primary : c.muted.o(0.35), borderRadius: BorderRadius.circular(Rd.pill)),
                    ),
                ]),
                const SizedBox(height: Sp.l),
                PillButton(
                  label: context.t(_i == 2 ? 'get_started' : 'next'),
                  onPressed: () => _i == 2 ? _finish() : _page.nextPage(duration: Mo.screen, curve: Mo.curve),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
