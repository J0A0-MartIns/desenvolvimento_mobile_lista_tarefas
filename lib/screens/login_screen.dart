import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../enums/app_spacing.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import 'main_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final auth = context.read<AuthProvider>();
    auth.validateForm();
    if (_formKey.currentState!.validate()) {
      bool success = await auth.submit(_emailController.text, _passwordController.text);
      if (success && mounted) {
        // Exibir Success SnackBar leve conforme o doc
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sucesso! Redirecionando...')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainListScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>();
    final isRegister = authState.mode == AuthMode.register;
    final isLoading = authState.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.large.value),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(mode: authState.mode),
                  SizedBox(height: AppSpacing.large.value),
                  if (authState.errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(AppSpacing.small.value),
                      margin: EdgeInsets.only(bottom: AppSpacing.medium.value),
                      color: Colors.red.shade100,
                      child: Text(
                        authState.errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  AuthTextField(
                    label: 'E-mail',
                    hint: 'Seu endereço de e-mail',
                    controller: _emailController,
                    enabled: !isLoading,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Campo obrigatório';
                      final regex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                      if (!regex.hasMatch(val)) return 'E-mail inválido. Faltando @ ou .';
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.medium.value),
                  AuthTextField(
                    label: 'Senha',
                    hint: 'Sua senha secreta',
                    controller: _passwordController,
                    isPassword: true,
                    enabled: !isLoading,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Campo obrigatório';
                      if (val.length < 6) return 'Mínimo de 6 caracteres';
                      return null;
                    },
                  ),
                  if (isRegister) ...[
                    SizedBox(height: AppSpacing.medium.value),
                    AuthTextField(
                      label: 'Confirmar Senha',
                      hint: 'Repita sua senha',
                      controller: _confirmPasswordController,
                      isPassword: true,
                      enabled: !isLoading,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Campo obrigatório';
                        if (val != _passwordController.text) return 'As senhas não conferem';
                        return null;
                      },
                    ),
                  ],
                  if (!isRegister) ...[
                    SizedBox(height: AppSpacing.small.value),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Funcionalidade ainda não implementada.')),
                          );
                        },
                        child: const Text('Esqueci minha senha?'),
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.large.value),
                  PrimaryButton(
                    text: isRegister ? 'Criar conta' : 'Entrar',
                    onPressed: _submit,
                    isLoading: isLoading,
                  ),
                  SizedBox(height: AppSpacing.large.value),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isRegister ? 'Já tem conta?' : 'Não tem conta?'),
                      TextButton(
                        onPressed: isLoading ? null : () {
                          // Clear fields when toggling mode
                          _emailController.clear();
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                          context.read<AuthProvider>().toggleMode();
                        },
                        child: Text(isRegister ? 'Faça login' : 'Cadastre-se'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
