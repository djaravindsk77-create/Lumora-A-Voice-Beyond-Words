import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utilities/feedback_service.dart';
import '../../models/user_role.dart';
import '../../providers/session_provider.dart';

/// Login screen.
///
/// In Demo Mode (no Firebase), the documented demo emails sign in locally
/// with any password. Validation errors and auth errors are accessible and
/// specific; there is always a path into the app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.demoMode = false, this.initialRole});

  final bool demoMode;
  final String? initialRole;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;
  UserRole _role = UserRole.child;

  @override
  void initState() {
    super.initState();
    _role = roleFromId(widget.initialRole ?? 'child');
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final String value = v?.trim() ?? '';
    if (value.isEmpty) return context.l10n.t('common.requiredField');
    final RegExp email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!email.hasMatch(value)) return context.l10n.t('common.invalidEmail');
    return null;
  }

  String? _validatePassword(String? v) {
    if ((v ?? '').isEmpty) return context.l10n.t('common.requiredField');
    if (v!.length < 6) return context.l10n.t('common.passwordTooShort');
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final SessionProvider session = context.read<SessionProvider>();
    if (widget.demoMode || !AppConfig.isFirebaseAvailable) {
      // Demo Mode: any of the demo emails with any password (>=6 chars).
      final bool ok = await session.signIn(_email.text.trim(), _password.text);
      if (!mounted) return;
      if (ok) {
        FeedbackService.success();
        // Replace the stack: Back from home must not return to Login.
        // Every adult role (parent, caregiver, teacher, therapist) opens the
        // dashboard; only the child role opens Child Mode.
        context.go(session.homeRoute);
      } else {
        session.clearError();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Demo accounts: parent@demo.lumora, teacher@demo.lumora, '
              'therapist@demo.lumora (any password).',
            ),
          ),
        );
      }
      return;
    }

    final bool ok = await session.signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (ok) {
      // Replace the stack: Back from home must not return to Login.
      context.go(session.homeRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.error ?? 'common.unknownError')),
      );
      session.clearError();
    }
  }

  Future<void> _enterDemo() async {
    final SessionProvider session = context.read<SessionProvider>();
    await session.startDemo(role: _role);
    if (!mounted) return;
    FeedbackService.success();
    // Replace the stack: Back from home must not return to Login.
    context.go(session.homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l.t('auth.loginTitle'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      l.t('auth.loginSubtitle'),
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: l.t('auth.email'),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const <String>[AutofillHints.email],
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l.t('auth.password'),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      autofillHints: const <String>[AutofillHints.password],
                      validator: _validatePassword,
                    ),
                    if (session.error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        session.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text(l.t('auth.forgotPassword')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: session.loading ? null : _submit,
                      child: session.loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4),
                            )
                          : Text(l.t('auth.signIn')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed:
                          session.loading ? null : () => context.push('/register'),
                      child: Text(l.t('auth.signUp')),
                    ),
                    const Divider(height: 32),
                    Text(
                      l.t('auth.demoAccountsBody'),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: _role,
                      decoration: InputDecoration(
                        labelText: l.t('onboarding.roleTitle'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      items: <UserRole>[
                        UserRole.child,
                        UserRole.parent,
                        UserRole.teacher,
                        UserRole.therapist,
                        UserRole.caregiver,
                      ]
                          .map((UserRole r) => DropdownMenuItem<UserRole>(
                                value: r,
                                child: Text(l.t('role.${r.nameId}')),
                              ))
                          .toList(),
                      onChanged: (UserRole? r) =>
                          setState(() => _role = r ?? UserRole.child),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.science),
                      label: Text(l.t('onboarding.demoButton')),
                      onPressed: session.loading ? null : _enterDemo,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
