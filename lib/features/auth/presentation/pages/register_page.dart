import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_strings.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input.dart';
import '../../../../shared/widgets/brand_header.dart';
import '../../../../shared/widgets/info_card.dart';
import '../../../../shared/widgets/language_selector.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final strings = context.strings;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.t('createAccountSuccess')),
          backgroundColor: Colors.green.shade600,
        ),
      );

      Navigator.of(context).pop();
    } on AuthException catch (error) {
      final duplicateUser = error.message.toLowerCase().contains('already') ||
          error.message.toLowerCase().contains('exists') ||
          error.message.toLowerCase().contains('registered');

      _showError(
        duplicateUser
            ? strings.t('emailAlreadyRegistered')
            : strings.t('createAccountError'),
      );
    } catch (_) {
      _showError(strings.t('createAccountError'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: LanguageSelector(),
                  ),
                  const SizedBox(height: 20),
                  BrandHeader(
                    title: strings.t('registerTitle'),
                    subtitle: strings.t('registerSubtitle'),
                  ),
                  const SizedBox(height: 28),
                  InfoCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppInput(
                            controller: _emailController,
                            label: strings.t('email'),
                            hintText: strings.t('emailHint'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return strings.t('fillAllFields');
                              }
                              if (!value.contains('@')) {
                                return strings.t('invalidEmail');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppInput(
                            controller: _passwordController,
                            label: strings.t('password'),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return strings.t('fillAllFields');
                              }
                              if (value.length < 6) {
                                return strings.t('passwordMinLength');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppInput(
                            controller: _confirmPasswordController,
                            label: strings.t('confirmPassword'),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return strings.t('fillAllFields');
                              }
                              if (value != _passwordController.text) {
                                return strings.t('passwordsDoNotMatch');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            label: strings.t('createAccount'),
                            onPressed: _register,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
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
