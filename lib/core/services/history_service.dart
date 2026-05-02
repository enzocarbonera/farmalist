import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryService {
  HistoryService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<AnalysisHistoryItem>> fetchUserHistory(String userId) async {
    final response = await _client
        .from('analysis_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response)
        .map(AnalysisHistoryItem.fromJson)
        .toList();
  }
}

class AnalysisHistoryItem {
  AnalysisHistoryItem({
    required this.medication,
    required this.createdAt,
    required this.country,
    required this.hasCalculatedDose,
    required this.hasEstimatedDose,
    required this.resultJson,
  });

  final String medication;
  final DateTime? createdAt;
  final String country;
  final bool hasCalculatedDose;
  final bool hasEstimatedDose;
  final Map<String, dynamic> resultJson;

  factory AnalysisHistoryItem.fromJson(Map<String, dynamic> json) {
    final resultJson = _parseResultJson(json['result_json']);
    final medication = (json['medication'] ??
            resultJson['medication'] ??
            resultJson['drug'] ??
            resultJson['principle_active'] ??
            'Medicamento no especificado')
        .toString();

    final country = (json['country'] ??
            resultJson['country'] ??
            (resultJson['source'] is Map<String, dynamic>
                ? resultJson['source']['country']
                : ''))
        .toString();

    return AnalysisHistoryItem(
      medication: medication,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      country: country,
      hasCalculatedDose: resultJson['dose_calculated'] == true,
      hasEstimatedDose: resultJson['estimated_available'] == true,
      resultJson: resultJson,
    );
  }

  static Map<String, dynamic> _parseResultJson(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is String && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }

    return <String, dynamic>{};
  }
}
