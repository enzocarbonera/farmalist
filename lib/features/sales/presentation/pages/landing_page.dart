import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_router.dart';
import '../../../../core/config/app_strings.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/info_card.dart';
import '../../../../shared/widgets/language_selector.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static const _monthlyUrl = 'https://pay.hotmart.com/L105641185S?off=7o50j6ca';
  static const _annualUrl = 'https://pay.hotmart.com/L105641185S?off=o49smsoa';

  final _plansKey = GlobalKey();
  final _authService = AuthService();
  final _subscriptionService = SubscriptionService();

  Future<void> _openCheckout(String url) async {
    await launchUrl(
      Uri.parse(url),
      webOnlyWindowName: '_blank',
    );
  }

  void _scrollToPlans() {
    final context = _plansKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _goToLoginOrHome() async {
    final user = _authService.getCurrentUser();

    if (user != null && await _subscriptionService.canAccessApp(user)) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(AppRouter.home);
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamed(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFE6FFFB),
              Color(0xFFF8FAFC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(onLoginPressed: _goToLoginOrHome),
                    const SizedBox(height: 32),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _HeroSection(
                              onPrimaryPressed: _scrollToPlans,
                              onSecondaryPressed: _goToLoginOrHome,
                            ),
                          ),
                          const SizedBox(width: 24),
                          const Expanded(child: _HeroCard()),
                        ],
                      )
                    else ...[
                      _HeroSection(
                        onPrimaryPressed: _scrollToPlans,
                        onSecondaryPressed: _goToLoginOrHome,
                      ),
                      const SizedBox(height: 24),
                      const _HeroCard(),
                    ],
                    const SizedBox(height: 32),
                    const _BenefitsSection(),
                    const SizedBox(height: 32),
                    const _HowItWorksSection(),
                    const SizedBox(height: 32),
                    Container(
                      key: _plansKey,
                      child: _PlansSection(
                        onMonthlyPressed: () => _openCheckout(_monthlyUrl),
                        onAnnualPressed: () => _openCheckout(_annualUrl),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _LegalNotice(text: strings.t('legalNotice')),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onLoginPressed});

  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.local_hospital_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            strings.t('appName'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const LanguageSelector(),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onLoginPressed,
          child: Text(strings.t('login')),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
  });

  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(strings.t('landingBadge')),
        ),
        const SizedBox(height: 18),
        Text(
          strings.t('landingHeadline'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 48,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          strings.t('landingSubtitle'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade700,
                height: 1.6,
                fontSize: 18,
              ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: strings.t('startNow'),
                onPressed: onPrimaryPressed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: onSecondaryPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(strings.t('login')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('landingHeroTitle'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          _MiniStat(
            title: strings.t('landingHeroStat1Title'),
            description: strings.t('landingHeroStat1Description'),
          ),
          const SizedBox(height: 16),
          _MiniStat(
            title: strings.t('landingHeroStat2Title'),
            description: strings.t('landingHeroStat2Description'),
          ),
          const SizedBox(height: 16),
          _MiniStat(
            title: strings.t('landingHeroStat3Title'),
            description: strings.t('landingHeroStat3Description'),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          height: 12,
          width: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final benefits = [
      strings.t('benefit1'),
      strings.t('benefit2'),
      strings.t('benefit3'),
      strings.t('benefit4'),
      strings.t('benefit5'),
    ];

    return _SectionCard(
      title: strings.t('benefits'),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: benefits
            .map(
              (benefit) => SizedBox(
                width: 320,
                child: InfoCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          benefit,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final steps = [
      strings.t('step1'),
      strings.t('step2'),
      strings.t('step3'),
      strings.t('step4'),
    ];

    return _SectionCard(
      title: strings.t('howItWorks'),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: List.generate(
          steps.length,
          (index) => SizedBox(
            width: 240,
            child: InfoCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    steps[index],
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
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

class _PlansSection extends StatelessWidget {
  const _PlansSection({
    required this.onMonthlyPressed,
    required this.onAnnualPressed,
  });

  final VoidCallback onMonthlyPressed;
  final VoidCallback onAnnualPressed;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return _SectionCard(
      title: strings.t('plans'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final singleColumn = constraints.maxWidth < 860;

          final monthly = _PlanCard(
            title: strings.t('monthlyPlan'),
            price: strings.t('monthlyPriceLabel'),
            highlights: [
              strings.t('fullAccess'),
              strings.t('updatesIncluded'),
            ],
            buttonLabel: strings.t('chooseMonthlyPlan'),
            onPressed: onMonthlyPressed,
          );

          final annual = _PlanCard(
            title: strings.t('annualPlan'),
            price: strings.t('annualPriceLabel'),
            badge: strings.t('bestPrice'),
            highlights: [
              strings.t('fullAccess'),
              strings.t('updatesIncluded'),
            ],
            buttonLabel: strings.t('chooseAnnualPlan'),
            onPressed: onAnnualPressed,
          );

          if (singleColumn) {
            return Column(
              children: [
                monthly,
                const SizedBox(height: 16),
                annual,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: monthly),
              const SizedBox(width: 16),
              Expanded(child: annual),
            ],
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.highlights,
    required this.buttonLabel,
    required this.onPressed,
    this.badge,
  });

  final String title;
  final String price;
  final List<String> highlights;
  final String buttonLabel;
  final VoidCallback onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(badge!),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            price,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 18),
          for (final item in highlights) ...[
            Row(
              children: [
                Icon(
                  Icons.check_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          AppButton(
            label: buttonLabel,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _LegalNotice extends StatelessWidget {
  const _LegalNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              height: 1.6,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
