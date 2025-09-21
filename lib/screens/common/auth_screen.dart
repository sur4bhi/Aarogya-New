import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../core/utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/services/local_storage.dart';

/// Auth screen with two flows: Phone OTP and Email login.
/// - Validates inputs via `Validators`.
/// - Shows loading and error states.
/// - TODOs indicate where to wire `AuthProvider` methods.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Phone
  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  bool _phoneLoading = false;
  String? _phoneError;
  bool _showInlineOtp = false;
  final _otpCtrl = TextEditingController();
  final _countryCodeCtrl = TextEditingController(text: '+91');
  int _resendSeconds = 60;
  Timer? _resendTimer;

  // Email
  final _emailFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _emailLoading = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _countryCodeCtrl.dispose();
    _resendTimer?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _phoneLoading = true;
      _phoneError = null;
    });
    try {
      if (!_phoneFormKey.currentState!.validate()) return;
      final phone = _phoneCtrl.text.trim();
      final cc = _countryCodeCtrl.text.trim();
      final full = '$cc$phone'.replaceAll(' ', '');
      final ok = await context.read<AuthProvider>().sendOtp(full);
      if (!mounted) return;
      if (ok) {
        setState(() {
          _showInlineOtp = true;
          _startResendCountdown();
        });
      } else {
        setState(() => _phoneError = context.read<AuthProvider>().lastError ?? 'Failed to send OTP');
      }
    } catch (e) {
      setState(() => _phoneError = e.toString());
    } finally {
      setState(() => _phoneLoading = false);
    }
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSeconds == 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;
    await _sendOtp();
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _phoneLoading = true;
      _phoneError = null;
    });
    try {
      final otp = _otpCtrl.text.trim();
      await context.read<AuthProvider>().verifyOtp(otp);
      if (!mounted) return;

      // After successful login, enforce startup flow: Language -> Role -> Dashboard
      if (LocalStorageService.isFirstTimeLaunch()) {
        AppRoutes.navigateToLanguage(context);
        return;
      }

      // If language already set but role not selected, go to role select
      final role = LocalStorageService.getSetting('user_role');
      if (role == null) {
        AppRoutes.navigateToRoleSelect(context);
        return;
      }

      // Otherwise go directly to respective dashboard
      if (role == 'asha') {
        AppRoutes.navigateToAshaDashboard(context);
      } else {
        AppRoutes.navigateToUserDashboard(context);
      }
    } catch (e) {
      setState(() => _phoneError = e.toString());
    } finally {
      setState(() => _phoneLoading = false);
    }
  }

  Future<void> _loginEmail() async {
    setState(() {
      _emailLoading = true;
      _emailError = null;
    });
    try {
      if (!_emailFormKey.currentState!.validate()) return;
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text.trim();
      await context
          .read<AuthProvider>()
          .signInWithEmailAndPassword(email: email, password: password);
      if (!mounted) return;
      
      // After successful login, enforce startup flow: Language -> Role -> Dashboard
      if (LocalStorageService.isFirstTimeLaunch()) {
        AppRoutes.navigateToLanguage(context);
        return;
      }

      final role = LocalStorageService.getSetting('user_role');
      if (role == null) {
        AppRoutes.navigateToRoleSelect(context);
        return;
      }

      if (role == 'asha') {
        AppRoutes.navigateToAshaDashboard(context);
      } else {
        AppRoutes.navigateToUserDashboard(context);
      }
    } catch (e) {
      setState(() => _emailError = e.toString());
    } finally {
      setState(() => _emailLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Phone'),
            Tab(text: 'Email'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Change language',
            onPressed: () => AppRoutes.navigateToLanguage(context),
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPhoneTab(context),
          _buildEmailTab(context),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextButton(
            onPressed: () {
              AppRoutes.navigateToUserDashboard(context);
            },
            child: const Text('Continue as guest'),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Enter your mobile number', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('We will send you a 6-digit verification code', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          Form(
            key: _phoneFormKey,
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: TextFormField(
                    controller: _countryCodeCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Code'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: '10-digit number',
                    ),
                    validator: Validators.validatePhoneNumber,
                  ),
                ),
              ],
            ),
          ),
          if (_phoneError != null) ...[
            const SizedBox(height: 8),
            Text(_phoneError!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          CustomButton(
            label: _showInlineOtp ? (_resendSeconds > 0 ? 'Send OTP' : 'Resend OTP') : 'Send OTP',
            onPressed: _phoneLoading
                ? null
                : () {
                    if (_showInlineOtp && _resendSeconds == 0) {
                      _resendOtp();
                    } else if (!_showInlineOtp) {
                      _sendOtp();
                    }
                  },
          ),
          if (_showInlineOtp) ...[
            const SizedBox(height: 20),
            const Text('Enter the 6-digit code', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _OtpSixBox(controller: _otpCtrl),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_resendSeconds > 0 ? 'Resend in 00:${_resendSeconds.toString().padLeft(2, '0')}' : 'You can resend now',
                    style: const TextStyle(color: Colors.black54)),
                TextButton(
                  onPressed: _resendSeconds == 0 && !_phoneLoading ? _resendOtp : null,
                  child: const Text('Resend OTP'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Verify & Continue',
              onPressed: _phoneLoading ? null : _verifyOtp,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmailTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: SingleChildScrollView(
        child: Form(
          key: _emailFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email', // TODO
                ),
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password', // TODO
                ),
                validator: Validators.validatePassword,
              ),
              if (_emailError != null) ...[
                const SizedBox(height: 12),
                Text(_emailError!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _emailLoading ? null : _loginEmail,
                child: _emailLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'), // TODO
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to registration_screen if present
                },
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpSixBox extends StatefulWidget {
  final TextEditingController controller;
  const _OtpSixBox({required this.controller});

  @override
  State<_OtpSixBox> createState() => _OtpSixBoxState();
}

class _OtpSixBoxState extends State<_OtpSixBox> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final digits = text.padRight(6, ' ');
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_focusNode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              final char = digits[i];
              return Container(
                width: 48,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  char.trim(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              );
            }),
          ),
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(counterText: '', border: InputBorder.none, isCollapsed: true),
            style: const TextStyle(color: Colors.transparent, height: 0.01),
            cursorColor: Colors.transparent,
          ),
        ],
      ),
    );
  }
}
