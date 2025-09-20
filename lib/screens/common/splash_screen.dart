/// Splash Screen
///
/// Purpose: Show app logo with a fade-in animation while performing boot tasks
/// (localization load, auth check, minimal prefetch). Navigates to `/auth` if
/// not logged in, or `/user/dashboard` if logged in.
///
/// Data flow:
/// - Reads auth state from `AuthProvider` (TODO)
/// - Initializes `LocalStorageService.init()`
/// - Optionally prefetch minimal data via `UserProvider` (TODO)
/// - Uses `AppRoutes` to navigate
/// - Localization strings reference: context.l10n.splashWelcome (TODO)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../core/services/local_storage.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Optional branding delay
      await Future<void>.delayed(const Duration(seconds: 2));

      // Determine first-time and auth state
      final isFirstTime = LocalStorageService.isFirstTimeLaunch();
      final isLoggedIn = context.read<AuthProvider>().isLoggedIn;

      if (!mounted) return;
      if (isFirstTime) {
        AppRoutes.navigateToLanguage(context);
        return;
      }

      if (isLoggedIn) {
        AppRoutes.navigateToUserDashboard(context);
      } else {
        AppRoutes.navigateToAuth(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = context.l10n; // TODO: use generated l10n
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'App logo', // TODO: l10n.appLogoAlt
                  child: FadeTransition(
                    opacity: _fade,
                    child: Icon(
                      Icons.health_and_safety,
                      color: AppColors.primary,
                      size: 96,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  AppConstants.appName, // TODO: l10n.appName
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome', // TODO: l10n.splashWelcome
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_isLoading && _error == null) ...[
                  const CircularProgressIndicator(),
                ] else if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _init,
                      child: const Text('Retry'), // TODO: l10n.retry
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
