import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/firebase/firebase_data_source.dart' show AuthResult, FirebaseDataSource;
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';

/// Registration. With Firebase configured this creates a real account;
/// without it, the account is created locally (Demo Mode) so the flow
/// always completes and the parent can proceed to child setup.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final String value = v?.trim() ?? '';
    if (value.isEmpty) return context.l10n.t('common.requiredField');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return context.l10n.t('common.invalidEmail');
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if ((v ?? '').isEmpty) return context.l10n.t('common.requiredField');
    if (v!.length < 6) return context.l10n.t('common.passwordTooShort');
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _password.text) {
      return context.l10n.t('common.passwordsDontMatch');
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    FocusScope.of(context).unfocus();

    final LumoraRepository repo = LumoraRepository.instance;
    await repo.init();

    if (AppConfig.isFirebaseAvailable) {
      final AuthResult result = await FirebaseDataSource.instance.register(
          _email.text.trim(), _password.text);
      if (!result.success && mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(result.errorKey ?? 'common.unknownError')),
        );
        return;
      }
    }

    // Store the local profile either way so the session can start.
    final UserModel user = UserModel(
      id: const Uuid().v4(),
      name: _name.text.trim(),
      email: _email.text.trim(),
      role: UserRole.parent,
    );
    await repo.saveUser(user);

    if (!mounted) return;
    final SessionProvider session = context.read<SessionProvider>();
    unawaited(session.setRole(UserRole.parent));
    unawaited(context.push('/child-setup'));
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.t('auth.registerTitle'))),
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
                      l.t('auth.registerSubtitle'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: l.t('auth.yourName'),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (String? v) =>
                          (v ?? '').trim().isEmpty
                              ? l.t('common.requiredField')
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: l.t('auth.email'),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l.t('auth.password'),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l.t('auth.confirmPassword'),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: _validateConfirm,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4),
                            )
                          : Text(l.t('auth.signUp')),
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


