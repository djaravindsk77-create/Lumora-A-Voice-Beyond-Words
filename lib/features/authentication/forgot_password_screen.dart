import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/firebase/firebase_data_source.dart';

/// Forgot password. Sends a reset email when Firebase auth is available;
/// otherwise explains honestly that reset requires Firebase configuration.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _email = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _sent = false;
  String? _errorKey;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!AppConfig.isFirebaseAvailable) {
      setState(() => _errorKey = 'auth.noFirebase');
      return;
    }
    final AuthResult result =
        await FirebaseDataSource.instance.sendPasswordReset(_email.text.trim());
    if (!mounted) return;
    setState(() {
      if (result.success) {
        _sent = true;
        _errorKey = null;
      } else {
        _errorKey = result.errorKey;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.t('auth.forgotTitle'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Icon(Icons.lock_reset,
                        size: 72,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      l.t('auth.forgotBody'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: l.t('auth.email'),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (String? v) {
                        final String value = v?.trim() ?? '';
                        if (value.isEmpty) {
                          return l.t('common.requiredField');
                        }
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value)) {
                          return l.t('common.invalidEmail');
                        }
                        return null;
                      },
                    ),
                    if (_errorKey != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        l.t(_errorKey!),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_sent) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        l.t('auth.resetSent'),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(l.t('auth.sendResetLink')),
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
