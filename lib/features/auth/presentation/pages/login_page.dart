import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_router.dart';
import '../../../../core/config/app_strings.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input.dart';
import '../../../../shared/widgets/brand_header.dart';
import '../../../../shared/widgets/info_card.dart';
import '../../../../shared/widgets/language_selector.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _subscriptionService = SubscriptionService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showPlanPrompt = false;
  bool _blockedBySubscription = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfNeeded());
  }

  Future<void> _redirectIfNeeded() async {
    final user = _authService.getCurrentUser();

    if (user == null) {
      return;
    }

    final hasActiveSubscription = await _subscriptionService.canAccessApp(user);

    if (!mounted) {
      return;
    }

    if (hasActiveSubscription) {
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    }
  }

  Future<void> _login() async {
    final strings = context.strings;

    if (!_formKey.currentState!.validate()) {
      _showMessage(strings.t('fillAllFields'), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = _authService.getCurrentUser();
      final hasActiveSubscription =
          user != null ? await _subscriptionService.canAccessApp(user) : false;

      if (!hasActiveSubscription) {
        await _authService.logout();

        if (mounted) {
          setState(() {
            _showPlanPrompt = true;
            _blockedBySubscription = true;
          });
        }

        return;
      }

      if (mounted) {
        setState(() {
          _showPlanPrompt = false;
          _blockedBySubscription = false;
        });
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
      }
    } on AuthException catch (error) {
      final invalidCredentials = error.message.toLowerCase().contains('invalid') ||
          error.message.toLowerCase().contains('credentials') ||
          error.message.toLowerCase().contains('credenciais');

      _showMessage(
        invalidCredentials
            ? strings.t('invalidCredentials')
            : strings.t('loginError'),
        isError: true,
      );
    } catch (_) {
      _showMessage(strings.t('loginError'), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final strings = context.strings;
    final email = _emailController.text.trim();
    final currentUser = _authService.getCurrentUser();

    if (email.isEmpty) {
      _showMessage(strings.t('fillAllFields'), isError: true);
      return;
    }

    if (_blockedBySubscription) {
      _showMessage(strings.t('noAccessSystem'), isError: true);
      return;
    }

    if (currentUser != null) {
      final canAccess = await _subscriptionService.canAccessApp(currentUser);
      if (!canAccess) {
        _showMessage(strings.t('noAccessSystem'), isError: true);
        return;
      }
    }

    try {
      await _authService.resetPassword(email);
      _showMessage(strings.t('passwordResetSent'));
    } on AuthException {
      _showMessage(strings.t('passwordRecoveryError'), isError: true);
    } catch (_) {
      _showMessage(strings.t('passwordRecoveryError'), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
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
                    title: strings.t('loginWelcome'),
                    subtitle: strings.t('loginSubtitle'),
                  ),
                  const SizedBox(height: 28),
                  InfoCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            strings.t('login'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
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
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                            ),
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
                          const SizedBox(height: 24),
                          AppButton(
                            label: strings.t('enter'),
                            onPressed: _login,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resetPassword,
                              child: Text(strings.t('forgotPassword')),
                            ),
                          ),
                          if (_showPlanPrompt) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(strings.t('noActiveSubscription')),
                                  const SizedBox(height: 12),
                                  AppButton(
                                    label: strings.t('seePlans'),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pushReplacementNamed(AppRouter.landing);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushReplacementNamed(AppRouter.landing);
                            },
                            child: Text(strings.t('createAccount')),
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
