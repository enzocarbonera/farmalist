import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/config/app_router.dart';
import '../../../../core/config/app_strings.dart';
import '../../../../core/services/analysis_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input.dart';
import '../../../../shared/widgets/info_card.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../widgets/analysis_result_view.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final _formKey = GlobalKey<FormState>();
  final _medicationController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _analysisService = AnalysisService();

  bool _isLoading = false;
  int _loadingMessageIndex = 0;
  Timer? _loadingTimer;
  String? _selectedSex;
  String? _selectedCountry;
  MedicationAnalysisResponse? _response;

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _medicationController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  List<_SelectOption> _sexOptions(BuildContext context) {
    final strings = context.strings;
    return [
      _SelectOption(value: 'Masculino', label: strings.t('male')),
      _SelectOption(value: 'Femenino', label: strings.t('female')),
      _SelectOption(value: 'Otro', label: strings.t('other')),
      _SelectOption(value: 'No informar', label: strings.t('preferNotToSay')),
    ];
  }

  List<_SelectOption> _countryOptions(BuildContext context) {
    final strings = context.strings;
    return [
      _SelectOption(value: 'Brasil', label: strings.t('countryBrazil')),
      _SelectOption(value: 'México', label: strings.t('countryMexico')),
      _SelectOption(value: 'Argentina', label: strings.t('countryArgentina')),
      _SelectOption(value: 'Colombia', label: strings.t('countryColombia')),
      _SelectOption(value: 'Chile', label: strings.t('countryChile')),
      _SelectOption(value: 'Perú', label: strings.t('countryPeru')),
      _SelectOption(
        value: 'Estados Unidos',
        label: strings.t('countryUnitedStates'),
      ),
      _SelectOption(value: 'Europa', label: strings.t('countryEurope')),
      _SelectOption(value: 'Otro', label: strings.t('countryOther')),
    ];
  }

  List<String> _loadingMessages(BuildContext context) {
    final strings = context.strings;
    return [
      strings.t('loadingStep1'),
      strings.t('loadingStep2'),
      strings.t('loadingStep3'),
      strings.t('loadingStep4'),
    ];
  }

  Future<void> _submit({
    String? selectedSourceUrl,
    String? countryOverride,
  }) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _startLoadingState();

    try {
      final response = await _analysisService.analyzeMedication(
        medication: _medicationController.text,
        age: _ageController.text,
        weight: _weightController.text,
        sex: _selectedSex ?? '',
        country: countryOverride ?? _selectedCountry,
        selectedSourceUrl: selectedSourceUrl,
      );

      if (!mounted) {
        return;
      }

      if (response.status == 'subscription_required') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.landing,
          (route) => false,
        );
        return;
      }

      setState(() => _response = response);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) {
        _stopLoadingState();
      }
    }
  }

  void _startLoadingState() {
    _loadingTimer?.cancel();
    setState(() {
      _isLoading = true;
      _loadingMessageIndex = 0;
    });

    _loadingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) {
        return;
      }

      final totalMessages = _loadingMessages(context).length;
      setState(() {
        _loadingMessageIndex = (_loadingMessageIndex + 1) % totalMessages;
      });
    });
  }

  void _stopLoadingState() {
    _loadingTimer?.cancel();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.current;
    final loadingMessages = _loadingMessages(context);
    final languageKey = context.localeService.language.name;

    return Scaffold(
      key: ValueKey('analysis-page-$languageKey'),
      appBar: AppBar(
        title: Text(strings.t('analysisTitle')),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: LanguageSelector()),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.t('analysisTitle'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.t('analysisSubtitle'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 28),
                      InfoCard(
                        child: Form(
                          key: _formKey,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 760;

                              if (isMobile) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _medicationField(),
                                    const SizedBox(height: 16),
                                    _ageField(),
                                    const SizedBox(height: 16),
                                    _weightField(),
                                    const SizedBox(height: 16),
                                    _sexField(),
                                    const SizedBox(height: 16),
                                    _countryField(),
                                    const SizedBox(height: 24),
                                    _submitButton(),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _medicationField(),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _ageField()),
                                      const SizedBox(width: 16),
                                      Expanded(child: _weightField()),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _sexField()),
                                      const SizedBox(width: 16),
                                      Expanded(child: _countryField()),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _submitButton(),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      if (_response != null) ...[
                        const SizedBox(height: 24),
                        _ResponseSection(
                          response: _response!,
                          onChooseSource: (option) {
                            _submit(
                              selectedSourceUrl: option.url,
                              countryOverride: option.country.isNotEmpty
                                  ? option.country
                                  : _selectedCountry,
                            );
                          },
                          onSelectSuggestion: (suggestion) {
                            setState(() {
                              _medicationController.text = suggestion;
                            });
                          },
                          onRetrySource: () {
                            setState(() {
                              _response = null;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: AbsorbPointer(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                                  blurRadius: 32,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 30,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 68,
                                    width: 68,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      height: 34,
                                      width: 34,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3.2,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    strings.t('analyzingMedication'),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 10),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 350),
                                    child: Text(
                                      loadingMessages[_loadingMessageIndex],
                                      key: ValueKey<int>(_loadingMessageIndex),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Colors.grey.shade700,
                                            height: 1.6,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _medicationField() {
    final strings = context.strings;
    return AppInput(
      controller: _medicationController,
      label: strings.t('medicationOrActiveIngredient'),
      hintText: strings.t('medicationHint'),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return strings.t('completeThisField');
        }
        return null;
      },
    );
  }

  Widget _ageField() {
    final strings = context.strings;
    return AppInput(
      controller: _ageController,
      label: strings.t('age'),
      hintText: strings.t('ageHint'),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return strings.t('completeThisField');
        }
        return null;
      },
    );
  }

  Widget _weightField() {
    final strings = context.strings;
    return AppInput(
      controller: _weightController,
      label: strings.t('weightKg'),
      hintText: strings.t('weightHint'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return strings.t('completeThisField');
        }
        return null;
      },
    );
  }

  Widget _sexField() {
    final strings = context.strings;
    return _DropdownField(
      label: strings.t('sex'),
      value: _selectedSex,
      items: _sexOptions(context),
      onChanged: (value) => setState(() => _selectedSex = value),
      validator: (value) => value == null ? strings.t('selectOption') : null,
    );
  }

  Widget _countryField() {
    final strings = context.strings;
    return _DropdownField(
      label: strings.t('countryOrPreferredSource'),
      value: _selectedCountry,
      items: _countryOptions(context),
      onChanged: (value) => setState(() => _selectedCountry = value),
    );
  }

  Widget _submitButton() {
    final strings = context.strings;
    return AppButton(
      label: strings.t('analyzeMedication'),
      icon: Icons.analytics_rounded,
      onPressed: _isLoading ? null : _submit,
      isLoading: _isLoading,
    );
  }
}

class _SelectOption {
  const _SelectOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
  });

  final String label;
  final List<_SelectOption> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.value,
              child: Text(item.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class _ResponseSection extends StatelessWidget {
  const _ResponseSection({
    required this.response,
    required this.onChooseSource,
    required this.onSelectSuggestion,
    required this.onRetrySource,
  });

  final MedicationAnalysisResponse response;
  final ValueChanged<AnalysisOption> onChooseSource;
  final ValueChanged<String> onSelectSuggestion;
  final VoidCallback onRetrySource;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.current;

    if (response.status == 'no_source_for_country') {
      return _SelectionCard(
        title: strings.t('noSourceCountryTitle'),
        message: strings.t('noSourceCountryMessage'),
        options: response.sources,
        onChooseSource: onChooseSource,
      );
    }

    if (response.status == 'choose_source') {
      return _SelectionCard(
        title: strings.t('selectOfficialSource'),
        message: response.message,
        options: response.sources,
        onChooseSource: onChooseSource,
      );
    }

    if (response.status == 'not_found') {
      return _SectionCard(
        title: strings.t('suggestions'),
        icon: Icons.search_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.t('medicationNotFoundTitle'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              strings.t('medicationNotFoundHint'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            if (response.suggestions.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: response.suggestions
                    .map(
                      (suggestion) => ActionChip(
                        label: Text(suggestion),
                        onPressed: () => onSelectSuggestion(suggestion),
                      ),
                    )
                    .toList(),
              )
            else
              Text(
                strings.t('noSuggestionsFound'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
          ],
        ),
      );
    }

    if (response.status == 'source_required') {
      return _SectionCard(
        title: strings.t('sourceRequired'),
        icon: Icons.info_outline_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.t('sourceRequiredMessage'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            if (response.message.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                response.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: strings.t('tryAnotherCountryOrSource'),
              onPressed: onRetrySource,
            ),
          ],
        ),
      );
    }

    if (response.isSuccess && response.result != null) {
      return AnalysisResultView(
        key: ValueKey('analysis-result-${context.localeService.language.name}'),
        result: response.result!,
      );
    }

    return _SectionCard(
      title: strings.t('result'),
      icon: Icons.info_outline_rounded,
      child: Text(response.message),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.message,
    required this.options,
    required this.onChooseSource,
  });

  final String title;
  final String message;
  final List<AnalysisOption> options;
  final ValueChanged<AnalysisOption> onChooseSource;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return _SectionCard(
      title: title,
      icon: Icons.library_books_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          if (options.isNotEmpty)
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (option.authority.isNotEmpty)
                        _LabeledValue(
                          label: strings.t('authority'),
                          value: option.authority,
                        ),
                      if (option.country.isNotEmpty)
                        _LabeledValue(
                          label: strings.t('country'),
                          value: option.country,
                        ),
                      if (option.sourceTitle.isNotEmpty)
                        _LabeledValue(
                          label: strings.t('title'),
                          value: option.sourceTitle,
                        ),
                      const SizedBox(height: 8),
                      AppButton(
                        label: option.buttonLabel,
                        onPressed: () => onChooseSource(option),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Text(
              strings.t('noAlternativeSources'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
            ),
        ],
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
