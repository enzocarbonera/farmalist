import 'package:flutter/material.dart';

import '../../../../core/config/app_router.dart';
import '../../../../core/config/app_strings.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/info_card.dart';
import '../../../../shared/widgets/language_selector.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final authService = AuthService();
    final user = authService.getCurrentUser();
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('appName')),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Center(child: LanguageSelector()),
          ),
          IconButton(
            tooltip: strings.t('logout'),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.login,
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.t('greeting', params: {
                      'email': user?.email ?? strings.t('professional'),
                    }),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.t('homeSubtitle'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: width > 980 ? 3 : width > 760 ? 2 : 1,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: width > 980 ? 1.02 : 1.16,
                      children: [
                        _HomeCard(
                          icon: Icons.analytics_rounded,
                          title: strings.t('newAnalysis'),
                          description: strings.t('newAnalysisDescription'),
                          buttonLabel: strings.t('startAnalysis'),
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRouter.analysis);
                          },
                        ),
                        _HomeCard(
                          icon: Icons.history_rounded,
                          title: strings.t('history'),
                          description: strings.t('historyDescription'),
                          buttonLabel: strings.t('viewHistory'),
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRouter.history);
                          },
                        ),
                        _HomeCard(
                          icon: Icons.settings_rounded,
                          title: strings.t('settings'),
                          description: strings.t('settingsDescription'),
                          buttonLabel: strings.t('openSettings'),
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRouter.settings);
                          },
                        ),
                      ],
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

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 36),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
          ),
          const Spacer(),
          AppButton(
            label: buttonLabel,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
