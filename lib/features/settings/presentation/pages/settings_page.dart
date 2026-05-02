import 'package:flutter/material.dart';

import '../../../../core/config/app_strings.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input.dart';
import '../../../../shared/widgets/info_card.dart';
import '../../../../shared/widgets/language_selector.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _subscriptionService = SubscriptionService();

  bool _isSaving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final strings = context.strings;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 6) {
      _showMessage(strings.t('passwordMinLength'), true);
      return;
    }

    if (password != confirmPassword) {
      _showMessage(strings.t('passwordsDoNotMatch'), true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _authService.updatePassword(password);
      _passwordController.clear();
      _confirmPasswordController.clear();
      _showMessage(strings.t('passwordUpdated'), false);
    } catch (_) {
      _showMessage(strings.t('passwordUpdateError'), true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message, bool isError) {
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
    final user = _authService.getCurrentUser()!;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('settings')),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: LanguageSelector()),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: FutureBuilder<SubscriptionAccessInfo>(
                future: _subscriptionService.fetchAccessInfo(user),
                builder: (context, snapshot) {
                  final accessInfo = snapshot.data;

                  return ListView(
                    children: [
                      InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    strings.t('account'),
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${strings.t('emailLabel')}: ${user.email ?? strings.t('notAvailable')}',
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${strings.t('plan')}: ${accessInfo?.planName ?? strings.t('loading')}',
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${strings.t('status')}: ${accessInfo?.statusLabel ?? strings.t('loading')}',
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${strings.t('validity')}: ${accessInfo?.expiresAtLabel ?? strings.t('loading')}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.t('changePassword'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              controller: _passwordController,
                              label: strings.t('newPassword'),
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              controller: _confirmPasswordController,
                              label: strings.t('confirmPassword'),
                              obscureText: true,
                            ),
                            const SizedBox(height: 20),
                            AppButton(
                              label: strings.t('saveNewPassword'),
                              onPressed: _savePassword,
                              isLoading: _isSaving,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
