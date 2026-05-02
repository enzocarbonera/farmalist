import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../config/app_strings.dart';
import 'auth_service.dart';
import 'locale_service.dart';

class AnalysisService {
  AnalysisService({
    http.Client? httpClient,
    AuthService? authService,
  })  : _httpClient = httpClient ?? http.Client(),
        _authService = authService ?? AuthService();

  final http.Client _httpClient;
  final AuthService _authService;

  Future<MedicationAnalysisResponse> analyzeMedication({
    required String medication,
    required String age,
    required String weight,
    required String sex,
    String? country,
    String? selectedSourceUrl,
  }) async {
    final session = _authService.getCurrentSession();
    final currentLanguageCode = LocaleService.instance.analysisLanguageCode;

    if (session == null) {
      throw Exception(AppStrings.current.t('sessionExpired'));
    }

    final response = await _httpClient.post(
      Uri.parse('${AppConfig.apiUrl}/analyze-medication'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': AppConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        'medication': medication.trim(),
        'age': age.trim(),
        'weight': weight.trim(),
        'sex': sex.trim(),
        'language': currentLanguageCode,
        if (country != null && country.trim().isNotEmpty) 'country': country.trim(),
        if (selectedSourceUrl != null && selectedSourceUrl.trim().isNotEmpty)
          'selected_source_url': selectedSourceUrl.trim(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(AppStrings.current.t('analysisRequestError'));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return MedicationAnalysisResponse.fromJson(decoded);
  }
}

class MedicationAnalysisResponse {
  MedicationAnalysisResponse({
    required this.status,
    required this.message,
    required this.result,
    required this.sources,
    required this.suggestions,
    required this.rawData,
  });

  final String status;
  final String message;
  final MedicationAnalysisResult? result;
  final List<AnalysisOption> sources;
  final List<String> suggestions;
  final Map<String, dynamic> rawData;

  bool get isSuccess => status == 'success' && result != null;

  factory MedicationAnalysisResponse.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? 'success').toString();
    final resultData = _extractResultMap(json);

    return MedicationAnalysisResponse(
      status: status,
      message: (json['message'] ??
              json['detail'] ??
              json['summary'] ??
              _defaultMessage(status))
          .toString(),
      result: resultData == null ? null : MedicationAnalysisResult.fromJson(resultData),
      sources: _parseOptions(
        json['available_sources'] ??
            json['sources'] ??
            json['authorities'] ??
            json['options'],
      ),
      suggestions: _parseStringList(
        json['suggestions'] ?? json['alternatives'] ?? json['matches'],
      ),
      rawData: json,
    );
  }

  static Map<String, dynamic>? _extractResultMap(Map<String, dynamic> json) {
    final direct = json['result'];
    if (direct is Map<String, dynamic>) {
      return direct;
    }

    if (json.containsKey('medication') ||
        json.containsKey('dose_mg') ||
        json.containsKey('dose_calculated') ||
        json.containsKey('estimated_available')) {
      return json;
    }

    return null;
  }

  static List<AnalysisOption> _parseOptions(dynamic value) {
    if (value is List) {
      return value
          .map((item) => AnalysisOption.fromDynamic(item))
          .whereType<AnalysisOption>()
          .toList();
    }

    return const [];
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  static String _defaultMessage(String status) {
    switch (status) {
      case 'choose_source':
        return AppStrings.current.t('selectOfficialSource');
      case 'no_source_for_country':
        return AppStrings.current.t('noSourceCountryMessage');
      case 'not_found':
        return AppStrings.current.t('suggestions');
      case 'source_required':
        return AppStrings.current.t('sourceRequired');
      case 'subscription_required':
        return AppStrings.current.t('noActiveSubscription');
      default:
        return AppStrings.current.t('result');
    }
  }
}

class AnalysisOption {
  const AnalysisOption({
    required this.authority,
    required this.country,
    required this.sourceTitle,
    required this.url,
    required this.value,
  });

  final String authority;
  final String country;
  final String sourceTitle;
  final String url;
  final String value;

  String get buttonLabel => AppStrings.current.t('useThisSource');

  static AnalysisOption? fromDynamic(dynamic item) {
    if (item is String) {
      return AnalysisOption(
        authority: item,
        country: '',
        sourceTitle: '',
        url: '',
        value: item,
      );
    }

    if (item is Map<String, dynamic>) {
      final authority = (item['authority'] ?? item['name'] ?? item['label'] ?? '').toString();
      final country = (item['country'] ?? '').toString();
      final sourceTitle = (item['source_title'] ?? item['title'] ?? '').toString();
      final url = (item['url'] ?? item['source_url'] ?? item['link'] ?? '').toString();
      final value = (item['value'] ?? item['authority'] ?? authority).toString();

      return AnalysisOption(
        authority: authority,
        country: country,
        sourceTitle: sourceTitle,
        url: url,
        value: value,
      );
    }

    return null;
  }
}

class MedicationAnalysisResult {
  MedicationAnalysisResult({
    required this.medication,
    required this.therapeuticClass,
    required this.mechanismSummary,
    required this.indicationSummary,
    required this.commonUses,
    required this.commonSymptomsOrSituations,
    required this.doseCalculated,
    required this.doseMg,
    required this.frequency,
    required this.duration,
    required this.maxDailyDoseMg,
    required this.estimatedDoseMg,
    required this.estimatedAvailable,
    required this.estimatedConfidence,
    required this.estimatedFrequency,
    required this.estimatedDuration,
    required this.estimatedDetails,
    required this.calculationSteps,
    required this.alerts,
    required this.explanation,
    required this.officialSource,
    required this.clinicalSources,
    required this.disclaimer,
  });

  final String medication;
  final String therapeuticClass;
  final String mechanismSummary;
  final String indicationSummary;
  final List<String> commonUses;
  final List<String> commonSymptomsOrSituations;
  final bool doseCalculated;
  final double? doseMg;
  final String frequency;
  final String duration;
  final double? maxDailyDoseMg;
  final double? estimatedDoseMg;
  final bool estimatedAvailable;
  final String estimatedConfidence;
  final String estimatedFrequency;
  final String estimatedDuration;
  final EstimatedDetails estimatedDetails;
  final List<String> calculationSteps;
  final List<String> alerts;
  final String explanation;
  final OfficialSource officialSource;
  final List<ClinicalSource> clinicalSources;
  final String disclaimer;

  factory MedicationAnalysisResult.fromJson(Map<String, dynamic> json) {
    final officialSource = OfficialSource.fromDynamic(
      json['source'] ?? json['official_source'],
    );
    final estimatedDetails = EstimatedDetails.fromDynamic(json['estimated_details']);

    return MedicationAnalysisResult(
      medication: (json['medication'] ??
              json['drug'] ??
              json['principle_active'] ??
              AppStrings.current.t('medicine'))
          .toString(),
      therapeuticClass: (json['therapeutic_class'] ?? '').toString(),
      mechanismSummary: (json['mechanism_summary'] ?? '').toString(),
      indicationSummary: (json['indication_summary'] ?? '').toString(),
      commonUses: _parseStringList(json['common_uses']),
      commonSymptomsOrSituations: _parseStringList(
        json['common_symptoms_or_situations'],
      ),
      doseCalculated: json['dose_calculated'] == true,
      doseMg: _parseDouble(json['dose_mg']),
      frequency: (json['frequency'] ?? '').toString(),
      duration: (json['duration'] ?? '').toString(),
      maxDailyDoseMg: _parseDouble(json['max_daily_dose_mg']),
      estimatedDoseMg: _parseDouble(json['estimated_dose_mg']),
      estimatedAvailable: json['estimated_available'] == true,
      estimatedConfidence: (json['estimated_confidence'] ?? '').toString(),
      estimatedFrequency: (json['estimated_frequency'] ?? '').toString(),
      estimatedDuration: (json['estimated_duration'] ?? '').toString(),
      estimatedDetails: estimatedDetails,
      calculationSteps: _parseStringList(
        json['calculation_steps'] ?? json['steps'] ?? json['step_by_step'],
      ),
      alerts: _parseStringList(json['alerts'] ?? json['warnings'] ?? json['risks']),
      explanation: (json['explanation'] ??
              json['detailed_explanation'] ??
              json['analysis'] ??
              AppStrings.current.t('explanation'))
          .toString(),
      officialSource: officialSource,
      clinicalSources: ClinicalSource.fromDynamicList(
        estimatedDetails.sourcesRaw ?? json['clinical_sources'],
      ),
      disclaimer: (json['disclaimer'] ??
              json['educational_notice'] ??
              json['notice'] ??
              AppStrings.current.t('legalNotice'))
          .toString(),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }

    return null;
  }
}

class EstimatedDetails {
  const EstimatedDetails({
    required this.minEstimatedDoseMg,
    required this.maxEstimatedDoseMg,
    required this.sourcesRaw,
  });

  final double? minEstimatedDoseMg;
  final double? maxEstimatedDoseMg;
  final dynamic sourcesRaw;

  factory EstimatedDetails.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return EstimatedDetails(
        minEstimatedDoseMg: _parseDouble(
          value['min_estimated_dose_mg'] ?? value['minDoseMg'],
        ),
        maxEstimatedDoseMg: _parseDouble(
          value['max_estimated_dose_mg'] ?? value['maxDoseMg'],
        ),
        sourcesRaw: value['sources'] ?? value['clinical_sources'] ?? value['references'],
      );
    }

    return const EstimatedDetails(
      minEstimatedDoseMg: null,
      maxEstimatedDoseMg: null,
      sourcesRaw: null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }

    return null;
  }
}

class OfficialSource {
  const OfficialSource({
    required this.authority,
    required this.country,
    required this.sourceTitle,
    required this.url,
  });

  final String authority;
  final String country;
  final String sourceTitle;
  final String url;

  factory OfficialSource.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return OfficialSource(
        authority: (value['authority'] ?? '').toString(),
        country: (value['country'] ?? '').toString(),
        sourceTitle: (value['source_title'] ?? value['title'] ?? '').toString(),
        url: (value['url'] ?? value['source_url'] ?? value['link'] ?? '').toString(),
      );
    }

    if (value is String) {
      return OfficialSource(
        authority: value,
        country: '',
        sourceTitle: '',
        url: '',
      );
    }

    return const OfficialSource(
      authority: '',
      country: '',
      sourceTitle: '',
      url: '',
    );
  }

  bool get hasContent =>
      authority.isNotEmpty || country.isNotEmpty || sourceTitle.isNotEmpty || url.isNotEmpty;
}

class ClinicalSource {
  const ClinicalSource({
    required this.title,
    required this.sourceType,
    required this.url,
  });

  final String title;
  final String sourceType;
  final String url;

  static List<ClinicalSource> fromDynamicList(dynamic value) {
    if (value is List) {
      return value
          .map((item) {
            if (item is String) {
              return ClinicalSource(
                title: item,
                sourceType: '',
                url: '',
              );
            }

            if (item is Map<String, dynamic>) {
              return ClinicalSource(
                title: (item['title'] ??
                        item['source_title'] ??
                        item['name'] ??
                        AppStrings.current.t('clinicalSource'))
                    .toString(),
                sourceType: (item['source_type'] ?? item['type'] ?? '').toString(),
                url: (item['url'] ?? item['link'] ?? item['source_url'] ?? '').toString(),
              );
            }

            return null;
          })
          .whereType<ClinicalSource>()
          .toList();
    }

    return const [];
  }
}
