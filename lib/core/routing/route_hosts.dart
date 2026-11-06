import 'package:flutter/material.dart';

import '../../features/authentication/child_profile_setup_screen.dart';
import '../../features/authentication/forgot_password_screen.dart';
import '../../features/authentication/login_screen.dart';
import '../../features/authentication/register_screen.dart';

/// Hosts that adapt GoRouter query parameters to screen constructors.
class LoginRouteHost extends StatelessWidget {
  const LoginRouteHost({super.key, this.demo = false, this.role});

  final bool demo;
  final String? role;

  @override
  Widget build(BuildContext context) {
    return LoginScreen(demoMode: demo, initialRole: role);
  }
}

class RegisterRouteHost extends StatelessWidget {
  const RegisterRouteHost({super.key});

  @override
  Widget build(BuildContext context) => const RegisterScreen();
}

class ForgotPasswordRouteHost extends StatelessWidget {
  const ForgotPasswordRouteHost({super.key});

  @override
  Widget build(BuildContext context) => const ForgotPasswordScreen();
}

class ChildProfileSetupRouteHost extends StatelessWidget {
  const ChildProfileSetupRouteHost({super.key});

  @override
  Widget build(BuildContext context) => const ChildProfileSetupScreen();
}

class SetupCompleteRouteHost extends StatelessWidget {
  const SetupCompleteRouteHost({super.key});

  @override
  Widget build(BuildContext context) => const SetupCompleteScreen();
}
