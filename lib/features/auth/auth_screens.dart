import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/ctx.dart';
import '../../core/errors.dart';
import '../../core/theme/tokens.dart';
import '../../core/validators.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/motion.dart';
import '../../data/providers.dart';
import '../../data/repo.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.children, this.back = false});
  final String title;
  final List<Widget> children;
  final bool back;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        const Positioned(top: 0, left: 0, right: 0, child: HeroBackdrop(height: 300)),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Sp.l, Sp.l, Sp.l, Sp.xxl),
            child: Column(children: [
              if (back) Align(alignment: AlignmentDirectional.centerStart, child: BackButton(color: Colors.white, onPressed: () => context.canPop() ? context.pop() : context.go('/signin'))),
              Image.asset('assets/logo/logo.png', width: 84, height: 84),
              const SizedBox(height: Sp.s),
              Text('9arini', style: context.tx.headlineLarge?.copyWith(color: Colors.white)),
              const SizedBox(height: Sp.xs),
              Text(context.t('tagline'), style: context.tx.bodyMedium?.copyWith(color: Colors.white.o(0.85)), textAlign: TextAlign.center),
              const SizedBox(height: Sp.xl),
              FadeSlideIn(
                child: GlassPanel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(title, style: context.tx.headlineMedium),
                    const SizedBox(height: Sp.l),
                    ...children,
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

Future<void> _googleSignIn() async {
  final g = await GoogleSignIn().signIn();
  if (g == null) return;
  final a = await g.authentication;
  final cred = GoogleAuthProvider.credential(accessToken: a.accessToken, idToken: a.idToken);
  await FirebaseAuth.instance.signInWithCredential(cred);
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInState();
}

class _SignInState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) context.toast(errText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AuthScaffold(
      title: context.t('sign_in'),
      children: [
        Form(
          key: _form,
          child: Column(children: [
            PillField(controller: _email, label: context.t('email'), icon: Icons.mail_rounded, keyboard: TextInputType.emailAddress, action: TextInputAction.next, autofill: const [AutofillHints.email], validator: tr(context, vEmail)),
            PillField(controller: _pass, label: context.t('password'), icon: Icons.lock_rounded, obscure: true, action: TextInputAction.done, autofill: const [AutofillHints.password], validator: tr(context, vRequired)),
          ]),
        ),
        Align(alignment: AlignmentDirectional.centerEnd, child: TextButton(onPressed: () => context.push('/forgot'), child: Text(context.t('forgot')))),
        PillButton(
          label: context.t('continue_btn'),
          loading: _busy,
          onPressed: () => _run(() async {
            if (!_form.currentState!.validate()) return;
            await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text);
          }),
        ),
        Padding(padding: const EdgeInsets.symmetric(vertical: Sp.m), child: Center(child: Text(context.t('or'), style: TextStyle(color: c.muted)))),
        PillButton(label: context.t('google'), secondary: true, icon: Icons.g_mobiledata_rounded, onPressed: _busy ? null : () => _run(_googleSignIn)),
        TextButton(onPressed: () => context.go('/signup'), child: Text(context.t('no_account'))),
      ],
    );
  }
}

/// Sign up (email) or "finish your profile" (Google users without a profile yet).
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.complete = false});
  final bool complete;
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpState();
}

class _SignUpState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName ?? '');
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _role = 'student';
  bool _age = false, _terms = false, _busy = false;

  bool get _ready => _terms && (_role == 'parent' || _age);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || !_ready) return;
    setState(() => _busy = true);
    try {
      final lang = ref.read(localeProvider).languageCode;
      if (!widget.complete) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text);
        await cred.user?.sendEmailVerification();
      }
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await Repo(uid).createProfile(name: _name.text, role: _role, locale: lang);
    } catch (e) {
      if (mounted) context.toast(errText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _roleCard(String role, IconData icon) {
    final c = context.c;
    final sel = _role == role;
    return Expanded(
      child: Pressable(
        semanticLabel: context.t('role_$role'),
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: Mo.tap,
          curve: Mo.curve,
          constraints: const BoxConstraints(minHeight: 84),
          margin: const EdgeInsets.symmetric(horizontal: Sp.xs),
          padding: const EdgeInsets.symmetric(vertical: Sp.m, horizontal: Sp.xs),
          decoration: BoxDecoration(
            color: sel ? c.primary.o(0.12) : c.surface,
            borderRadius: BorderRadius.circular(Rd.m),
            border: Border.all(color: sel ? c.primary : c.hairline, width: sel ? 1.5 : 1),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: sel ? c.primary : c.muted),
            const SizedBox(height: Sp.xs),
            Text(context.t('role_$role'), style: context.tx.labelMedium, textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AuthScaffold(
      title: context.t(widget.complete ? 'complete_profile' : 'sign_up'),
      back: !widget.complete,
      children: [
        Form(
          key: _form,
          child: Column(children: [
            PillField(controller: _name, label: context.t('full_name'), icon: Icons.person_rounded, action: TextInputAction.next, maxLength: 60, validator: tr(context, (v) => vRequired(v, max: 60))),
            if (!widget.complete) ...[
              PillField(controller: _email, label: context.t('email'), icon: Icons.mail_rounded, keyboard: TextInputType.emailAddress, action: TextInputAction.next, autofill: const [AutofillHints.email], validator: tr(context, vEmail)),
              PillField(controller: _pass, label: context.t('password'), icon: Icons.lock_rounded, obscure: true, autofill: const [AutofillHints.newPassword], validator: tr(context, vPassword)),
            ],
          ]),
        ),
        Padding(padding: const EdgeInsets.only(bottom: Sp.s), child: Text(context.t('i_am'), style: context.tx.labelLarge)),
        Row(children: [_roleCard('student', Icons.school_rounded), _roleCard('parent', Icons.family_restroom_rounded), _roleCard('tutor', Icons.cast_for_education_rounded)]),
        const SizedBox(height: Sp.m),
        if (_role != 'parent')
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _age,
            onChanged: (v) => setState(() => _age = v ?? false),
            title: Text(context.t(_role == 'tutor' ? 'age_18' : 'age_13'), style: context.tx.bodyMedium),
          ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _terms,
          onChanged: (v) => setState(() => _terms = v ?? false),
          title: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(context.t('agree_a'), style: context.tx.bodyMedium),
            GestureDetector(onTap: () => context.push('/legal/terms'), child: Text(context.t('terms'), style: context.tx.bodyMedium?.copyWith(color: c.primary, fontWeight: FontWeight.w600))),
            Text(context.t('agree_b'), style: context.tx.bodyMedium),
            GestureDetector(onTap: () => context.push('/legal/privacy'), child: Text(context.t('privacy'), style: context.tx.bodyMedium?.copyWith(color: c.primary, fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(height: Sp.m),
        PillButton(label: context.t(widget.complete ? 'continue_btn' : 'sign_up'), loading: _busy, onPressed: _ready ? _submit : null),
        if (!widget.complete) TextButton(onPressed: () => context.go('/signin'), child: Text(context.t('have_account'))),
        if (widget.complete) TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: Text(context.t('sign_out'))),
      ],
    );
  }
}

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});
  @override
  State<ForgotScreen> createState() => _ForgotState();
}

class _ForgotState extends State<ForgotScreen> {
  final _email = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email.text.trim());
    } catch (_) {
      // Same message either way, so the form never reveals which emails exist.
    }
    if (mounted) {
      setState(() => _busy = false);
      context.toast(context.t('reset_sent'));
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: context.t('forgot'),
        back: true,
        children: [
          Form(key: _form, child: PillField(controller: _email, label: context.t('email'), icon: Icons.mail_rounded, keyboard: TextInputType.emailAddress, validator: tr(context, vEmail))),
          PillButton(label: context.t('send_reset'), loading: _busy, onPressed: _send),
        ],
      );
}

class TermsUpdateScreen extends ConsumerStatefulWidget {
  const TermsUpdateScreen({super.key});
  @override
  ConsumerState<TermsUpdateScreen> createState() => _TermsUpdateState();
}

class _TermsUpdateState extends ConsumerState<TermsUpdateScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: context.t('terms_update_t'),
        children: [
          Text(context.t('terms_update_d'), style: context.tx.bodyLarge),
          const SizedBox(height: Sp.m),
          Row(children: [
            Expanded(child: PillButton(label: context.t('terms'), secondary: true, onPressed: () => context.push('/legal/terms'))),
            const SizedBox(width: Sp.s),
            Expanded(child: PillButton(label: context.t('privacy'), secondary: true, onPressed: () => context.push('/legal/privacy'))),
          ]),
          const SizedBox(height: Sp.m),
          PillButton(
            label: context.t('accept'),
            loading: _busy,
            onPressed: () async {
              setState(() => _busy = true);
              try {
                await ref.read(repoProvider)!.acceptTerms();
              } catch (e) {
                if (mounted) context.toast(errText(context, e));
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
          ),
        ],
      );
}
