import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/subscription_service.dart';

class AppRouter {
  const AppRouter._();

  static const landing = '/';
  static const login = '/login';
  static const home = '/home';
  static const analysis = '/analysis';
  static const history = '/history';
  static const historyDetail = '/history/detail';
  static const settings = '/settings';
}

class ProtectedRoute extends StatefulWidget {
  const ProtectedRoute({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ProtectedRoute> createState() => _ProtectedRouteState();
}

class _ProtectedRouteState extends State<ProtectedRoute> {
  final _authService = AuthService();
  final _subscriptionService = SubscriptionService();

  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateAccess());
  }

  Future<void> _validateAccess() async {
    final user = _authService.getCurrentUser();

    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.login);
      }
      return;
    }

    final hasActiveSubscription = await _subscriptionService.canAccessApp(user);

    if (!hasActiveSubscription) {
      await _authService.logout();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.login);
      }
      return;
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}
