import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_strings.dart';
import '../../../../core/services/analysis_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/info_card.dart';

enum MedicationVisualType {
  tablet,
  liquid,
  topical,
  injectable,
  medicine,
}

class AnalysisResultView extends StatelessWidget {
  const AnalysisResultView({
    super.key,
    required this.result,
  });

  final MedicationAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.current;
    final visualType = _classifyMedicationType(result);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.fallbackMessage.trim().isNotEmpty)
          _FallbackMessageCard(message: result.fallbackMessage.trim()),
        _SectionCard(
          title: strings.t('analysisSummary'),
          icon: _iconForType(visualType),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeIllustration(type: visualType),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TypeBadge(type: visualType),
                    const SizedBox(height: 12),
                    Text(
                      result.medication,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (result.therapeuticClass.isNotEmpty ||
            result.indicationSummary.isNotEmpty ||
            result.commonSymptomsOrSituations.isNotEmpty ||
            result.commonUses.isNotEmpty ||
            result.mechanismSummary.isNotEmpty)
          _SectionCard(
            title: strings.t('useAndIndications'),
            icon: Icons.fact_check_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.therapeuticClass.isNotEmpty)
                  _LabeledValue(
                    label: strings.t('therapeuticClass'),
                    value: result.therapeuticClass,
                  ),
                if (result.indicationSummary.isNotEmpty) ...[
                  _SubsectionTitle(label: strings.t('whatIsItUsedFor')),
                  Text(
                    result.indicationSummary,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 16),
                ],
                if (result.commonSymptomsOrSituations.isNotEmpty) ...[
                  _SubsectionTitle(label: strings.t('commonSituations')),
                  _BulletedList(
                    items: result.commonSymptomsOrSituations,
                    emptyLabel: '',
                  ),
                  const SizedBox(height: 16),
                ],
                if (result.commonUses.isNotEmpty) ...[
                  _SubsectionTitle(label: strings.t('commonUses')),
                  _BulletedList(
                    items: result.commonUses,
                    emptyLabel: '',
                  ),
                  const SizedBox(height: 16),
                ],
                if (result.mechanismSummary.isNotEmpty) ...[
                  _SubsectionTitle(label: strings.t('mechanismSummary')),
                  Text(
                    result.mechanismSummary,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.6),
                  ),
                ],
              ],
            ),
          ),
        _DoseResultCard(result: result),
        _SectionCard(
          title: strings.t('stepByStepCalculation'),
          icon: Icons.calculate_rounded,
          child: _BulletedList(
            items: result.calculationSteps,
            emptyLabel: strings.t('calculationNotReceived'),
          ),
        ),
        _SectionCard(
          title: strings.t('explanation'),
          icon: Icons.menu_book_rounded,
          child: Text(
            result.explanation,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
          ),
        ),
        _SectionCard(
          title: strings.t('importantWarnings'),
          icon: Icons.warning_amber_rounded,
          child: _BulletedList(
            items: result.resolvedAlerts,
            emptyLabel: strings.t('warningsNotReceived'),
          ),
        ),
        _OfficialSourceCard(
          source: result.officialSource,
          showWhoPahoBadge: result.hasWhoPahoSource,
        ),
        if (result.clinicalSources.isNotEmpty)
          _ClinicalSourcesCard(sources: result.clinicalSources),
        _SectionCard(
          title: strings.t('educationalNotice'),
          icon: Icons.school_rounded,
          child: Text(
            result.disclaimer,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }

  static MedicationVisualType _classifyMedicationType(
    MedicationAnalysisResult result,
  ) {
    final text = [
      result.medication,
      result.explanation,
      result.officialSource.sourceTitle,
      result.officialSource.authority,
      result.indicationSummary,
      result.mechanismSummary,
    ].join(' ').toLowerCase();

    if (text.contains('comprimido') ||
        text.contains('tableta') ||
        text.contains('cápsula') ||
        text.contains('capsula') ||
        text.contains('mg oral')) {
      return MedicationVisualType.tablet;
    }

    if (text.contains('gotas') ||
        text.contains('solución oral') ||
        text.contains('solucion oral') ||
        text.contains('jarabe') ||
        text.contains('suspensión') ||
        text.contains('suspension')) {
      return MedicationVisualType.liquid;
    }

    if (text.contains('crema') ||
        text.contains('pomada') ||
        text.contains('gel') ||
        text.contains('tópico') ||
        text.contains('topico')) {
      return MedicationVisualType.topical;
    }

    if (text.contains('inyectable') ||
        text.contains('intravenosa') ||
        text.contains('intramuscular') ||
        text.contains('ampolla')) {
      return MedicationVisualType.injectable;
    }

    return MedicationVisualType.medicine;
  }

  static IconData _iconForType(MedicationVisualType type) {
    switch (type) {
      case MedicationVisualType.tablet:
        return Icons.medication_rounded;
      case MedicationVisualType.liquid:
        return Icons.science_rounded;
      case MedicationVisualType.topical:
        return Icons.healing_rounded;
      case MedicationVisualType.injectable:
        return Icons.vaccines_rounded;
      case MedicationVisualType.medicine:
        return Icons.local_hospital_rounded;
    }
  }
}

class _DoseResultCard extends StatelessWidget {
  const _DoseResultCard({required this.result});

  final MedicationAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.current;

    if (result.doseCalculated) {
      return _SectionCard(
        title: strings.t('doseResult'),
        icon: Icons.verified_rounded,
        child: _DoseHero(
          backgroundColor: const Color(0xFFDCFCE7),
          accentColor: const Color(0xFF166534),
          title: strings.t('officialDoseCalculated'),
          value: result.doseMg != null
              ? '${result.doseMg!.toStringAsFixed(2)} mg'
              : strings.t('doseAvailable'),
          helperText: strings.t('basedOnOfficialSource'),
          detailRows: [
            if (result.resolvedPosology.isNotEmpty)
              _DoseDetailRow(
                icon: Icons.library_books_rounded,
                label: strings.t('posology'),
                value: result.resolvedPosology,
              ),
            if (result.resolvedFrequency.isNotEmpty)
              _DoseDetailRow(
                icon: Icons.schedule_rounded,
                label: strings.t('frequency'),
                value: result.resolvedFrequency,
              ),
            if (result.resolvedDuration.isNotEmpty)
              _DoseDetailRow(
                icon: Icons.calendar_today_rounded,
                label: strings.t('duration'),
                value: result.resolvedDuration,
              ),
            if (result.resolvedMaxDailyDoseMg != null)
              _DoseDetailRow(
                icon: Icons.monitor_weight_outlined,
                label: strings.t('maxDailyDose'),
                value: '${result.resolvedMaxDailyDoseMg!.toStringAsFixed(2)} mg',
              ),
          ],
        ),
      );
    }

    if (result.estimatedAvailable) {
      return _SectionCard(
        title: strings.t('doseResult'),
        icon: Icons.auto_awesome_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DoseHero(
              backgroundColor: const Color(0xFFFEF3C7),
              accentColor: const Color(0xFF92400E),
              title: strings.t('estimatedDoseByAi'),
              value: _estimatedValue(strings),
              helperText: strings.t('estimatedEducationalNotice'),
              detailRows: [
                _DoseInlineBadge(label: strings.t('educationalEstimate')),
                if (result.resolvedPosology.isNotEmpty)
                  _DoseDetailRow(
                    icon: Icons.library_books_rounded,
                    label: strings.t('posology'),
                    value: result.resolvedPosology,
                  ),
                if (result.estimatedFrequency.isNotEmpty)
                  _DoseDetailRow(
                    icon: Icons.schedule_rounded,
                    label: strings.t('estimatedFrequency'),
                    value: result.estimatedFrequency,
                  ),
                if (result.estimatedDuration.isNotEmpty)
                  _DoseDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: strings.t('estimatedDuration'),
                    value: result.estimatedDuration,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _ConfidenceBadge(confidence: result.estimatedConfidence),
          ],
        ),
      );
    }

    return _SectionCard(
      title: strings.t('doseResult'),
      icon: Icons.info_rounded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.t('unsafeDoseTitle'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF9A3412),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              strings.t('unsafeDoseMessage'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _estimatedValue(AppStrings strings) {
    final min = result.estimatedDetails.minEstimatedDoseMg;
    final max = result.estimatedDetails.maxEstimatedDoseMg;

    if (min != null && max != null) {
      return '${min.toStringAsFixed(2)} mg - ${max.toStringAsFixed(2)} mg';
    }

    if (result.estimatedDoseMg != null) {
      return '${result.estimatedDoseMg!.toStringAsFixed(2)} mg';
    }

    return strings.t('estimateAvailable');
  }
}

class _DoseHero extends StatelessWidget {
  const _DoseHero({
    required this.backgroundColor,
    required this.accentColor,
    required this.title,
    required this.value,
    required this.helperText,
    required this.detailRows,
  });

  final Color backgroundColor;
  final Color accentColor;
  final String title;
  final String value;
  final String helperText;
  final List<Widget> detailRows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (detailRows.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...detailRows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: row,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            helperText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: accentColor,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _DoseDetailRow extends StatelessWidget {
  const _DoseDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DoseInlineBadge extends StatelessWidget {
  const _DoseInlineBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final String confidence;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.current;
    final normalized = confidence.toLowerCase().trim();
    late final String label;
    late final Color background;
    late final Color foreground;

    switch (normalized) {
      case 'high':
        label = strings.t('highConfidence');
        background = const Color(0xFFDCFCE7);
        foreground = const Color(0xFF166534);
        break;
      case 'medium':
        label = strings.t('mediumConfidence');
        background = const Color(0xFFFEF3C7);
        foreground = const Color(0xFF92400E);
        break;
      default:
        label = strings.t('lowConfidence');
        background = const Color(0xFFFEE2E2);
        foreground = const Color(0xFF991B1B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _OfficialSourceCard extends StatelessWidget {
  const _OfficialSourceCard({
    required this.source,
    required this.showWhoPahoBadge,
  });

  final OfficialSource source;
  final bool showWhoPahoBadge;

  Future<void> _openSource(String url) async {
    if (url.isEmpty) {
      return;
    }

    await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.current;

    return _SectionCard(
      title: strings.t('officialSource'),
      icon: Icons.verified_outlined,
      child: source.hasContent
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showWhoPahoBadge) ...[
                  _SourceBadge(label: strings.t('whoPahoSourceBadge')),
                  const SizedBox(height: 12),
                ],
                if (source.authority.isNotEmpty)
                  _LabeledValue(
                    label: strings.t('authority'),
                    value: source.authority,
                  ),
                if (source.country.isNotEmpty)
                  _LabeledValue(
                    label: strings.t('country'),
                    value: source.country,
                  ),
                if (source.sourceTitle.isNotEmpty)
                  _LabeledValue(
                    label: strings.t('title'),
                    value: source.sourceTitle,
                  ),
                if (source.url.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: strings.t('openOfficialSource'),
                    onPressed: () => _openSource(source.url),
                  ),
                ],
              ],
            )
          : Text(
              strings.t('noOfficialSourceReceived'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
    );
  }
}

class _ClinicalSourcesCard extends StatelessWidget {
  const _ClinicalSourcesCard({required this.sources});

  final List<ClinicalSource> sources;

  Future<void> _openSource(String url) async {
    if (url.isEmpty) {
      return;
    }

    await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.current;

    return _SectionCard(
      title: strings.t('aiClinicalSources'),
      icon: Icons.library_books_outlined,
      child: Column(
        children: sources
            .map(
              (source) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.link_rounded, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source.title,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            if (source.sourceType.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                source.sourceType,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (source.url.isNotEmpty)
                        TextButton(
                          onPressed: () => _openSource(source.url),
                          child: Text(strings.t('openSource')),
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

class _FallbackMessageCard extends StatelessWidget {
  const _FallbackMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.current;

    return _SectionCard(
      title: strings.t('officialSource'),
      icon: Icons.info_outline_rounded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Text(
          strings.t('fallbackSourceNotice', params: {'message': message}),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF166534),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _TypeIllustration extends StatelessWidget {
  const _TypeIllustration({required this.type});

  final MedicationVisualType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      width: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Icon(
        AnalysisResultView._iconForType(type),
        size: 34,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final MedicationVisualType type;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.current;
    final label = switch (type) {
      MedicationVisualType.tablet => strings.t('pillCapsule'),
      MedicationVisualType.liquid => strings.t('liquidDrops'),
      MedicationVisualType.topical => strings.t('topical'),
      MedicationVisualType.injectable => strings.t('injectable'),
      MedicationVisualType.medicine => strings.t('medicine'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _SubsectionTitle extends StatelessWidget {
  const _SubsectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _BulletedList extends StatelessWidget {
  const _BulletedList({
    required this.items,
    required this.emptyLabel,
  });

  final List<String> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (emptyLabel.isEmpty && items.isEmpty) {
      return const SizedBox.shrink();
    }

    if (items.isEmpty) {
      return Text(
        emptyLabel,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.circle, size: 8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
