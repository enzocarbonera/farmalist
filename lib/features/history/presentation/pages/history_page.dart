import 'package:flutter/material.dart';

import '../../../../core/config/app_strings.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/history_service.dart';
import '../../../../shared/widgets/language_selector.dart';
import 'history_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _authService = AuthService();
  final _historyService = HistoryService();

  late final Future<List<AnalysisHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    final userId = _authService.getCurrentUser()!.id;
    _historyFuture = _historyService.fetchUserHistory(userId);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('historyTitle')),
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
              constraints: const BoxConstraints(maxWidth: 980),
              child: FutureBuilder<List<AnalysisHistoryItem>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text(strings.t('historyLoadError')));
                  }

                  final items = snapshot.data ?? const [];
                  if (items.isEmpty) {
                    return Center(child: Text(strings.t('historyEmpty')));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.medication,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 10),
                              Text('${strings.t('date')}: ${_formatDate(item.createdAt)}'),
                              if (item.country.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('${strings.t('countryOrSource')}: ${item.country}'),
                              ],
                              const SizedBox(height: 6),
                              Text(_resultLabel(strings, item)),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => HistoryDetailPage(item: item),
                                      ),
                                    );
                                  },
                                  child: Text(strings.t('viewAnalysis')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return AppStrings.current.t('notAvailable');
    }

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }

  String _resultLabel(AppStrings strings, AnalysisHistoryItem item) {
    if (item.hasCalculatedDose) {
      return strings.t('calculatedDoseResult');
    }
    if (item.hasEstimatedDose) {
      return strings.t('estimatedDoseResult');
    }
    return strings.t('infoForReviewResult');
  }
}
