import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../enums/app_spacing.dart';

class AuthHeader extends StatelessWidget {
  final AuthMode mode;

  const AuthHeader({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final title = mode == AuthMode.login ? 'Bem-vindo(a)!' : 'Crie sua conta';
    final subtitle = mode == AuthMode.login ? 'Faça login para continuar' : 'Preencha seus dados';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.small.value),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
