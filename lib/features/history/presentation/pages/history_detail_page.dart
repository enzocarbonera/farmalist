import 'package:flutter/material.dart';

import '../../../../core/config/app_strings.dart';
import '../../../../core/services/analysis_service.dart';
import '../../../../core/services/history_service.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../../../analysis/presentation/widgets/analysis_result_view.dart';

class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({
    super.key,
    required this.item,
  });

  final AnalysisHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final result = MedicationAnalysisResult.fromJson(item.resultJson);
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('analysisDetail')),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: LanguageSelector()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: AnalysisResultView(result: result),
            ),
          ),
        ),
      ),
    );
  }
}
