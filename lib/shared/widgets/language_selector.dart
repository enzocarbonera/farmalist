import 'package:flutter/material.dart';

import '../../core/config/app_strings.dart';
import '../../core/services/locale_service.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = context.localeService;
    final strings = context.strings;

    return PopupMenuButton<AppLanguage>(
      tooltip: strings.t('language'),
      initialValue: localeService.language,
      onSelected: (language) {
        localeService.setLanguage(language);
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<AppLanguage>(
            value: AppLanguage.spanish,
            child: Text(strings.t('spanishLatam')),
          ),
          PopupMenuItem<AppLanguage>(
            value: AppLanguage.portugueseBrazil,
            child: Text(strings.t('portugueseBrazil')),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 18),
            const SizedBox(width: 8),
            Text(
              localeService.language == AppLanguage.spanish
                  ? 'ES'
                  : 'PT-BR',
            ),
          ],
        ),
      ),
    );
  }
}
