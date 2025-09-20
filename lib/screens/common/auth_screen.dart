import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../core/utils/validators.dart';

// TODO: import 'package:provider/provider.dart';
// TODO: import '../../providers/auth_provider.dart';

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
      // TODO: await context.read<AuthProvider>().sendOtp(phone);
      setState(() => _showInlineOtp = true);
    } catch (e) {
      setState(() => _phoneError = e.toString());
    } finally {
      setState(() => _phoneLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _phoneLoading = true;
      _phoneError = null;
    });
    try {
      final otp = _otpCtrl.text.trim();
      // TODO: await context.read<AuthProvider>().verifyOtp(otp);
      if (!mounted) return;
      AppRoutes.navigateToUserDashboard(context);
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
      // TODO: await context.read<AuthProvider>().signInWithEmail(email, password);
      if (!mounted) return;
      AppRoutes.navigateToUserDashboard(context);
    } catch (e) {
      setState(() => _emailError = e.toString());
    } finally {
      setState(() => _emailLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = context.l10n; // TODO
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login / Register'), // TODO: l10n.authTitle
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Phone'), // TODO: l10n.authPhone
            Tab(text: 'Email'), // TODO: l10n.authEmail
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Change language', // TODO
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
              // TODO: Allow guest mode? If yes, set a guest flag in AuthProvider
              AppRoutes.navigateToUserDashboard(context);
            },
            child: const Text('Continue as guest'), // TODO: l10n.continueGuest
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
          Form(
            key: _phoneFormKey,
            child: TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number', // TODO
                prefixText: '+91 ', // TODO: country selector
                hintText: '10-digit number',
              ),
              validator: Validators.validatePhoneNumber,
            ),
          ),
          const SizedBox(height: 12),
          if (_phoneError != null)
            Text(_phoneError!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _phoneLoading ? null : _sendOtp,
            child: _phoneLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send OTP'), // TODO
          ),
          if (_showInlineOtp) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter OTP', // TODO
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _phoneLoading ? null : _verifyOtp,
              child: _phoneLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify & Continue'),
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
