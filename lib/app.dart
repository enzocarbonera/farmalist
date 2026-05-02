import 'package:flutter/material.dart';

import 'core/config/app_strings.dart';
import 'core/services/locale_service.dart';
import 'core/config/app_theme.dart';
import 'core/config/app_router.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/analysis/presentation/pages/analysis_page.dart';
import 'features/history/presentation/pages/history_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/sales/presentation/pages/landing_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';

class FarmaDoseApp extends StatelessWidget {
  const FarmaDoseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      notifier: LocaleService.instance,
      child: AnimatedBuilder(
        animation: LocaleService.instance,
        builder: (context, _) {
          return MaterialApp(
            title: context.strings.t('appName'),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: AppRouter.landing,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case AppRouter.landing:
                  return MaterialPageRoute<void>(
                    builder: (_) => const LandingPage(),
                    settings: settings,
                  );
                case AppRouter.login:
                  return MaterialPageRoute<void>(
                    builder: (_) => const LoginPage(),
                    settings: settings,
                  );
                case AppRouter.home:
                  return MaterialPageRoute<void>(
                    builder: (_) => const ProtectedRoute(child: HomePage()),
                    settings: settings,
                  );
                case AppRouter.analysis:
                  return MaterialPageRoute<void>(
                    builder: (_) => const ProtectedRoute(child: AnalysisPage()),
                    settings: settings,
                  );
                case AppRouter.history:
                  return MaterialPageRoute<void>(
                    builder: (_) => const ProtectedRoute(child: HistoryPage()),
                    settings: settings,
                  );
                case AppRouter.settings:
                  return MaterialPageRoute<void>(
                    builder: (_) => const ProtectedRoute(child: SettingsPage()),
                    settings: settings,
                  );
                default:
                  return MaterialPageRoute<void>(
                    builder: (_) => const LandingPage(),
                    settings: settings,
                  );
              }
            },
          );
        },
      ),
    );
  }
}
