import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../core/utils/date_utils.dart' as du;

// TODO: import 'package:provider/provider.dart';
// TODO: import '../../providers/user_provider.dart';

/// Profile Setup Screen
/// - Captures basic profile and health info.
/// - Validates required fields and saves via `UserProvider.createProfile`.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _genderCtrl = ValueNotifier<String?>('');
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _genderCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _conditionsCtrl.dispose();
    _medicationsCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = now.subtract(const Duration(days: 365 * 20));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      _dobCtrl.text = du.AppDateUtils.formatDate(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = {
        'name': _nameCtrl.text.trim(),
        'dob': _dobCtrl.text.trim(),
        'gender': _genderCtrl.value,
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'conditions': _conditionsCtrl.text.trim(),
        'medications': _medicationsCtrl.text.trim(),
        'emergencyName': _emergencyNameCtrl.text.trim(),
        'emergencyPhone': _emergencyPhoneCtrl.text.trim(),
      };
      // TODO: await context.read<UserProvider>().createProfile(profile);
      if (!mounted) return;
      AppRoutes.navigateToUserDashboard(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = context.l10n; // TODO
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')), // TODO
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'), // TODO
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                // DOB
                TextFormField(
                  controller: _dobCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth', // TODO
                    suffixIcon: Icon(Icons.date_range),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                // Gender
                ValueListenableBuilder<String?>(
                  valueListenable: _genderCtrl,
                  builder: (_, value, __) => DropdownButtonFormField<String>(
                    value: value?.isEmpty == true ? null : value,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => _genderCtrl.value = v,
                    decoration: const InputDecoration(labelText: 'Gender'), // TODO
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 12),
                // Contact
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Contact Number'), // TODO
                  validator: (v) => (v == null || v.length != 10) ? 'Enter valid phone' : null,
                ),
                const SizedBox(height: 12),
                // Address
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address'), // TODO
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                // Conditions
                TextFormField(
                  controller: _conditionsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Known Conditions (comma separated)', // TODO
                  ),
                ),
                const SizedBox(height: 12),
                // Medications
                TextFormField(
                  controller: _medicationsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medications', // TODO
                  ),
                ),
                const SizedBox(height: 12),
                // Emergency contact
                TextFormField(
                  controller: _emergencyNameCtrl,
                  decoration: const InputDecoration(labelText: 'Emergency Contact Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emergencyPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Emergency Contact Phone'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save & Continue'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // TODO: Ask to connect ASHA now (dialog) then navigate
                    AppRoutes.navigateToAshaConnect(context);
                  },
                  child: const Text('Connect to ASHA now?'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
