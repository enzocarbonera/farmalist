import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_strings.dart';

class SubscriptionService {
  static const _adminEmail = 'gustavo_carbonera@hotmail.com';

  SubscriptionService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<bool> canAccessApp(User user) async {
    if (_isAdminUser(user)) {
      return true;
    }

    return hasActiveSubscription(user.id);
  }

  Future<bool> hasActiveSubscription(String userId) async {
    final response = await _client
        .from('subscriptions')
        .select('plan, status, expires_at')
        .eq('user_id', userId);

    final subscriptions = List<Map<String, dynamic>>.from(response);

    if (subscriptions.isEmpty) {
      return false;
    }

    return subscriptions.any(_isSubscriptionActive);
  }

  Future<SubscriptionAccessInfo> fetchAccessInfo(User user) async {
    if (_isAdminUser(user)) {
      return SubscriptionAccessInfo(
        planName: AppStrings.current.t('adminAccess'),
        statusLabel: AppStrings.current.t('fullAccess'),
        expiresAtLabel: AppStrings.current.t('noExpirationDate'),
      );
    }

    final response = await _client
        .from('subscriptions')
        .select('plan, status, expires_at')
        .eq('user_id', user.id)
        .order('expires_at', ascending: false)
        .limit(1);

    final subscriptions = List<Map<String, dynamic>>.from(response);

    if (subscriptions.isEmpty) {
      return SubscriptionAccessInfo(
        planName: AppStrings.current.t('noPlan'),
        statusLabel: AppStrings.current.t('inactive'),
        expiresAtLabel: AppStrings.current.t('notAvailable'),
      );
    }

    final item = subscriptions.first;
    return SubscriptionAccessInfo(
      planName: _mapPlan(item['plan']?.toString()),
      statusLabel: _mapStatus(item['status']?.toString()),
      expiresAtLabel: _formatExpiresAt(item['expires_at']?.toString()),
    );
  }

  bool _isAdminUser(User user) {
    return user.email?.toLowerCase().trim() == _adminEmail;
  }

  bool _isSubscriptionActive(Map<String, dynamic> subscription) {
    final status = (subscription['status'] ?? '').toString().toLowerCase().trim();
    final expiresAtRaw = subscription['expires_at']?.toString();
    final expiresAt =
        expiresAtRaw == null || expiresAtRaw.isEmpty ? null : DateTime.tryParse(expiresAtRaw);
    final now = DateTime.now().toUtc();
    final hasFutureExpiration = expiresAt != null && expiresAt.toUtc().isAfter(now);

    if (status == 'refunded' ||
        status == 'chargeback' ||
        status == 'inactive' ||
        status == 'free') {
      return false;
    }

    if (status == 'active') {
      return expiresAt == null || hasFutureExpiration;
    }

    if (status == 'canceled') {
      return hasFutureExpiration;
    }

    return false;
  }

  String _mapPlan(String? plan) {
    final value = (plan ?? '').toLowerCase().trim();
    switch (value) {
      case 'monthly':
      case 'mensual':
        return AppStrings.current.t('monthlyPlanLabel');
      case 'annual':
      case 'anual':
        return AppStrings.current.t('annualPlanLabel');
      case '':
        return AppStrings.current.t('planNotSpecified');
      default:
        return plan ?? AppStrings.current.t('planNotSpecified');
    }
  }

  String _mapStatus(String? status) {
    final value = (status ?? '').toLowerCase().trim();
    switch (value) {
      case 'active':
        return AppStrings.current.t('active');
      case 'canceled':
        return AppStrings.current.t('canceledActiveAccess');
      case 'refunded':
        return AppStrings.current.t('refunded');
      case 'chargeback':
        return AppStrings.current.t('chargeback');
      case 'inactive':
        return AppStrings.current.t('inactive');
      case 'free':
        return AppStrings.current.t('noPlan');
      default:
        return status?.isNotEmpty == true ? status! : AppStrings.current.t('notAvailable');
    }
  }

  String _formatExpiresAt(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.current.t('noExpirationDate');
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return AppStrings.current.t('notAvailable');
    }

    final date = parsed.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class SubscriptionAccessInfo {
  const SubscriptionAccessInfo({
    required this.planName,
    required this.statusLabel,
    required this.expiresAtLabel,
  });

  final String planName;
  final String statusLabel;
  final String expiresAtLabel;
}
