import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ctx.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/glass.dart';
import '../../data/providers.dart';
import '../../data/push.dart';
import '../../router.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  ConsumerState<ShellScreen> createState() => _ShellState();
}

class _ShellState extends ConsumerState<ShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(uidProvider);
      if (uid == null) return;
      PushService.start(
        uid,
        (id) => ref.read(routerProvider).push('/class/$id/space'),
        (m) {
          if (mounted) context.toast(m);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final unverified = user != null && !user.emailVerified;
    final unread = ref.watch(unreadProvider).valueOrNull ?? 0;
    return Scaffold(
      extendBody: true,
      body: Column(children: [
        if (unverified) _VerifyBanner(user: user),
        Expanded(child: MediaQuery.removePadding(context: context, removeTop: unverified, child: widget.shell)),
      ]),
      bottomNavigationBar: GlassNavBar(
        index: widget.shell.currentIndex,
        unread: unread,
        onTap: (i) => widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex),
      ),
    );
  }
}

class _VerifyBanner extends StatefulWidget {
  const _VerifyBanner({required this.user});
  final User user;
  @override
  State<_VerifyBanner> createState() => _VerifyBannerState();
}

class _VerifyBannerState extends State<_VerifyBanner> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.warning.o(0.14),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.s),
          child: Row(children: [
            Icon(Icons.mark_email_unread_rounded, color: c.warning, size: 20),
            const SizedBox(width: Sp.s),
            Expanded(child: Text(context.t('verify_banner'), style: context.tx.bodySmall?.copyWith(color: c.text))),
            TextButton(
              onPressed: () async {
                await widget.user.sendEmailVerification();
                if (context.mounted) context.toast(context.t('sent'));
              },
              child: Text(context.t('resend')),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await widget.user.reload();
                        await FirebaseAuth.instance.currentUser?.getIdToken(true);
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(context.t('verified_check')),
            ),
          ]),
        ),
      ),
    );
  }
}
