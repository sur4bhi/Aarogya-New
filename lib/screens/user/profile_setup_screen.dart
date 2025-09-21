import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../core/utils/date_utils.dart' as du;
import 'package:provider/provider.dart';
import '../../providers/profile_setup_provider.dart';
import '../../core/utils/profile_validators.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../core/services/speech_service.dart';
import '../../providers/language_provider.dart';

/// Profile Setup Screen
/// - Captures basic profile and health info.
/// - Validates required fields and saves via `UserProvider.createProfile`.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKeys = List<GlobalKey<FormState>>.generate(5, (_) => GlobalKey<FormState>());
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  String? _gender;
  final _phoneCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  bool _isInitialized = false;

  // Address
  final _addressCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  String _stateValue = 'Maharashtra';
  final _pincodeCtrl = TextEditingController();

  // Health
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _bloodGroup = 'Unknown';

  // Medical history
  final _allergiesCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _familyHistoryCtrl = TextEditingController();
  final Set<String> _conditions = {};

  // Goals & consent
  final Set<String> _goals = {};
  bool _consent = false;
  String _ashaPreference = 'later';

  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    if (!_isInitialized) {
      debugPrint('ProfileSetupScreen: Initializing provider');
      try {
        final provider = context.read<ProfileSetupProvider>();
        await provider.loadDraftProfile().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('ProfileSetupScreen: Initialization timeout');
          },
        );
        debugPrint('ProfileSetupScreen: Provider initialized');
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          debugPrint('ProfileSetupScreen: State updated, _isInitialized = true');
        }
      } catch (e) {
        debugPrint('ProfileSetupScreen: Initialization error: $e');
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _medicationsCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _pincodeCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _allergiesCtrl.dispose();
    _familyHistoryCtrl.dispose();
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

  void _persistDraft(ProfileSetupProvider p) => p.saveProfile();

  Future<void> _voiceFill(TextEditingController controller, {bool numericOnly = false}) async {
    final langCode = mounted ? context.read<LanguageProvider>().languageCode : 'en';
    final localeId = _mapLangToLocale(langCode);
    final text = await SpeechService.listenOnce(localeId: localeId);
    if (text != null && text.trim().isNotEmpty) {
      controller.text = numericOnly ? text.replaceAll(RegExp(r'[^0-9]'), '') : text;
    }
  }

  String _mapLangToLocale(String code) {
    switch (code) {
      case 'hi':
        return 'hi-IN';
      case 'mr':
        return 'mr-IN';
      case 'bn':
        return 'bn-IN';
      case 'te':
        return 'te-IN';
      case 'ta':
        return 'ta-IN';
      case 'gu':
        return 'gu-IN';
      case 'kn':
        return 'kn-IN';
      default:
        return 'en-IN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ProfileSetupProvider>();
    final currentStep = provider.currentStep.clamp(0, 4); // Ensure step is within bounds
    final totalSteps = 5;
    final progress = ((currentStep + 1) / totalSteps);
    
    debugPrint('ProfileSetupScreen: Building - _isInitialized: $_isInitialized, provider.isLoading: ${provider.isLoading}');
    
    // Show loading screen while provider is initializing
    if (provider.isLoading) {
      debugPrint('ProfileSetupScreen: Showing loading screen');
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.complete),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile setup...'),
            ],
          ),
        ),
      );
    }
    
    debugPrint('ProfileSetupScreen: Showing main content');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.complete),
        actions: [
          TextButton(
            onPressed: () {
              // Skip profile setup: leave onboarding incomplete and go to dashboard
              AppRoutes.navigateToUserDashboard(context);
            },
            child: const Text('Skip'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: _buildStepHeader(context, l10n, currentStep, totalSteps),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
                child: _buildCurrentStep(context, l10n, provider, currentStep),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: _buildNavBar(context, l10n, provider, currentStep, totalSteps),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, AppLocalizations l10n, ProfileSetupProvider provider, int currentStep) {
    try {
      switch (currentStep) {
        case 0:
          return _stepPersonalInfo(context, l10n, provider);
        case 1:
          return _stepAddress(context, l10n, provider);
        case 2:
          return _stepHealth(context, l10n, provider);
        case 3:
          return _stepMedicalHistory(context, l10n, provider);
        case 4:
          return _stepGoalsConsent(context, l10n, provider);
        default:
          return _stepPersonalInfo(context, l10n, provider);
      }
    } catch (e) {
      debugPrint('ProfileSetupScreen: Error building step $currentStep: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading form step. Please try again.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStepHeader(BuildContext context, AppLocalizations l10n, int current, int total) {
    final titles = [
      l10n.personalInformation,
      l10n.addressInformation,
      l10n.healthInformation,
      l10n.medicalHistory,
      l10n.healthGoals,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.step} ${current + 1} ${l10n.ofLabel} $total', style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(titles[current], style: AppTextStyles.headline3),
      ],
    );
  }

  Widget _buildNavBar(BuildContext context, AppLocalizations l10n, ProfileSetupProvider p, int current, int total) {
    return Row(
      children: [
        if (current > 0)
          OutlinedButton(
            onPressed: () => p.previousStep(),
            child: Text(l10n.previous),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: () async {
            final valid = _formKeys[current].currentState?.validate() ?? true;
            if (!valid) return;
            // Update provider with current step data
            switch (current) {
              case 0:
                p.updatePersonalInfo({
                  'fullName': _nameCtrl.text.trim(),
                  'dateOfBirth': _dobCtrl.text.trim(),
                  'gender': _gender,
                  'phoneNumber': _phoneCtrl.text.trim(),
                  'emergencyContact': _emergencyNameCtrl.text.trim(),
                  'emergencyContactPhone': _emergencyPhoneCtrl.text.trim(),
                });
                break;
              case 1:
                p.updateAddressInfo({
                  'address': _addressCtrl.text.trim(),
                  'village': _villageCtrl.text.trim(),
                  'district': _districtCtrl.text.trim(),
                  'state': _stateValue,
                  'pincode': _pincodeCtrl.text.trim(),
                });
                break;
              case 2:
                p.updateHealthInfo({
                  'height': num.tryParse(_heightCtrl.text.trim())?.toDouble(),
                  'weight': num.tryParse(_weightCtrl.text.trim())?.toDouble(),
                  'bloodGroup': _bloodGroup,
                });
                break;
              case 3:
                p.updateMedicalHistory({
                  'chronicConditions': _conditions.toList(),
                  'allergies': _allergiesCtrl.text.trim().isEmpty ? [] : _allergiesCtrl.text.trim().split(','),
                  'currentMedications': _medicationsCtrl.text.trim().isEmpty ? [] : _medicationsCtrl.text.trim().split(','),
                  'familyMedicalHistory': _familyHistoryCtrl.text.trim(),
                });
                break;
              case 4:
                p.updateGoalsAndConsent({
                  'healthGoals': _goals.toList(),
                  'preferredLanguage': null,
                  'consentDataSharing': _consent,
                  'ashaPreference': _ashaPreference,
                });
                break;
            }
            _persistDraft(p);
            if (current < total - 1) {
              p.nextStep();
            } else {
              // Completion: build UserModel and persist to UserProvider
              try {
                final data = p.data;
                final now = DateTime.now();
                final parsedDob = du.AppDateUtils.parseDate(data['dateOfBirth']?.toString() ?? '') ?? now;
                final user = UserModel(
                  id: '',
                  email: '',
                  name: (data['fullName'] ?? '').toString(),
                  phoneNumber: (data['phoneNumber'] ?? '').toString(),
                  dateOfBirth: parsedDob,
                  gender: (data['gender'] ?? '').toString(),
                  userType: UserType.patient,
                  createdAt: now,
                  updatedAt: now,
                  height: (data['height'] is num) ? (data['height'] as num).toDouble() : null,
                  weight: (data['weight'] is num) ? (data['weight'] as num).toDouble() : null,
                  bloodGroup: (data['bloodGroup'] ?? '').toString().isEmpty ? null : (data['bloodGroup'] ?? '').toString(),
                  allergies: List<String>.from(data['allergies'] ?? const <String>[]),
                  chronicConditions: List<String>.from(data['chronicConditions'] ?? const <String>[]),
                  medications: List<String>.from(data['currentMedications'] ?? const <String>[]),
                  emergencyContactName: (data['emergencyContact'] ?? '').toString(),
                  emergencyContactPhone: (data['emergencyContactPhone'] ?? '').toString(),
                  address: (data['address'] ?? '').toString(),
                  city: (data['village'] ?? '').toString(),
                  state: (data['state'] ?? '').toString(),
                  pincode: (data['pincode'] ?? '').toString(),
                  connectedAshaId: null,
                  hasCompletedOnboarding: true,
                  preferredLanguage: context.read<UserProvider>().currentUser.preferredLanguage,
                );
                await context.read<UserProvider>().updateUserProfile(user);
                await p.submitCompleteProfile();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save profile: $e')),
                );
                return;
              }

              if (!mounted) return;
              // Based on preference, go to ASHA connect or dashboard
              final ashaPref = p.data['ashaPreference']?.toString() ?? 'later';
              if (ashaPref == 'yes') {
                AppRoutes.navigateToAshaConnect(context);
              } else {
                AppRoutes.navigateToUserDashboard(context);
              }
            }
          },
          child: Text(current < total - 1 ? l10n.next : l10n.complete),
        ),
      ],
    );
  }

  Widget _stepPersonalInfo(BuildContext context, AppLocalizations l10n, ProfileSetupProvider p) {
    return Form(
      key: _formKeys[0],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.fullName,
                suffixIcon: IconButton(
                  tooltip: 'Speak',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => _voiceFill(_nameCtrl),
                ),
              ),
              validator: ProfileValidators.validateName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dobCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: l10n.dateOfBirth,
                suffixIcon: const Icon(Icons.date_range),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              items: [
                DropdownMenuItem(value: 'male', child: Text(l10n.male)),
                DropdownMenuItem(value: 'female', child: Text(l10n.female)),
                DropdownMenuItem(value: 'other', child: Text(l10n.other)),
              ],
              onChanged: (v) => setState(() => _gender = v),
              decoration: InputDecoration(labelText: l10n.gender),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number +91',
                suffixIcon: Icon(Icons.phone),
              ),
              validator: ProfileValidators.validatePhone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyNameCtrl,
              decoration: InputDecoration(
                labelText: l10n.emergencyContact,
                suffixIcon: IconButton(
                  tooltip: 'Speak',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => _voiceFill(_emergencyNameCtrl),
                ),
              ),
              validator: ProfileValidators.validateName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Emergency Phone +91',
                suffixIcon: Icon(Icons.phone),
              ),
              validator: ProfileValidators.validatePhone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepAddress(BuildContext context, AppLocalizations l10n, ProfileSetupProvider p) {
    return Form(
      key: _formKeys[1],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                labelText: l10n.address,
                suffixIcon: IconButton(
                  tooltip: 'Speak',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => _voiceFill(_addressCtrl),
                ),
              ),
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _villageCtrl,
              decoration: InputDecoration(
                labelText: l10n.village,
                suffixIcon: IconButton(
                  tooltip: 'Speak',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => _voiceFill(_villageCtrl),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _districtCtrl,
              decoration: InputDecoration(
                labelText: l10n.district,
                suffixIcon: IconButton(
                  tooltip: 'Speak',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => _voiceFill(_districtCtrl),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _stateValue,
              items: const [
                DropdownMenuItem(value: 'Maharashtra', child: Text('Maharashtra')),
                DropdownMenuItem(value: 'Gujarat', child: Text('Gujarat')),
                DropdownMenuItem(value: 'Karnataka', child: Text('Karnataka')),
              ],
              onChanged: (v) => setState(() => _stateValue = v ?? 'Maharashtra'),
              decoration: InputDecoration(labelText: l10n.state),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pincodeCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.pincode,
                suffixIcon: IconButton(
                  tooltip: 'Speak',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => _voiceFill(_pincodeCtrl, numericOnly: true),
                ),
              ),
              validator: ProfileValidators.validatePincode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepHealth(BuildContext context, AppLocalizations l10n, ProfileSetupProvider p) {
    return Form(
      key: _formKeys[2],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _heightCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.heightLabel,
                suffixText: 'cm',
                suffixIcon: IconButton(
                  tooltip: 'Speak',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => _voiceFill(_heightCtrl, numericOnly: true),
                ),
              ),
              validator: ProfileValidators.validateHeight,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.weightLabel,
                suffixText: 'kg',
                suffixIcon: IconButton(
                  tooltip: 'Speak',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => _voiceFill(_weightCtrl, numericOnly: true),
                ),
              ),
              validator: ProfileValidators.validateWeight,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _bloodGroup,
              items: const [
                DropdownMenuItem(value: 'A+', child: Text('A+')),
                DropdownMenuItem(value: 'A-', child: Text('A-')),
                DropdownMenuItem(value: 'B+', child: Text('B+')),
                DropdownMenuItem(value: 'B-', child: Text('B-')),
                DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                DropdownMenuItem(value: 'O+', child: Text('O+')),
                DropdownMenuItem(value: 'O-', child: Text('O-')),
                DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
              ],
              onChanged: (v) => setState(() => _bloodGroup = v ?? 'Unknown'),
              decoration: InputDecoration(labelText: l10n.bloodGroup),
              validator: (v) => ProfileValidators.isValidBloodGroup(v) ? null : 'Select blood group',
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepMedicalHistory(BuildContext context, AppLocalizations l10n, ProfileSetupProvider p) {
    final conditions = [
      'diabetes', 'hypertension', 'heartDisease', 'asthma', 'kidneyDisease', 'thyroid', 'arthritis', 'other'
    ];
    String localize(String key) {
      switch (key) {
        case 'diabetes': return l10n.diabetes;
        case 'hypertension': return l10n.hypertension;
        case 'heartDisease': return l10n.heartDisease;
        case 'asthma': return l10n.asthma;
        case 'kidneyDisease': return l10n.kidneyDisease;
        case 'thyroid': return l10n.thyroid;
        default: return 'Other';
      }
    }
    return Form(
      key: _formKeys[3],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.chronicConditions, style: AppTextStyles.headline3),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: conditions.map((c) {
                final selected = _conditions.contains(c);
                return FilterChip(
                  label: Text(localize(c)),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _conditions.add(c);
                    } else {
                      _conditions.remove(c);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _allergiesCtrl,
              decoration: InputDecoration(
                labelText: l10n.allergies,
                hintText: 'comma separated',
                suffixIcon: IconButton(
                  tooltip: 'Speak',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => _voiceFill(_allergiesCtrl),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _medicationsCtrl,
              decoration: InputDecoration(
                labelText: l10n.currentMedications,
                hintText: 'comma separated',
                suffixIcon: IconButton(
                  tooltip: 'Speak',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => _voiceFill(_medicationsCtrl),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _familyHistoryCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.familyMedicalHistory,
                suffixIcon: IconButton(
                  tooltip: 'Speak',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => _voiceFill(_familyHistoryCtrl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepGoalsConsent(BuildContext context, AppLocalizations l10n, ProfileSetupProvider p) {
    final goalOptions = [
      'bp_control', 'diabetes_management', 'weight_management', 'wellness', 'med_adherence', 'regular_checkups'
    ];
    Map<String, String> labels = {
      'bp_control': 'Control Blood Pressure',
      'diabetes_management': 'Manage Diabetes',
      'weight_management': 'Weight Management',
      'wellness': 'General Wellness',
      'med_adherence': 'Medication Adherence',
      'regular_checkups': 'Regular Checkups',
    };
    return Form(
      key: _formKeys[4],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.healthGoals, style: AppTextStyles.headline3),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: goalOptions.map((g) {
                final selected = _goals.contains(g);
                return FilterChip(
                  label: Text(labels[g] ?? g),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _goals.add(g);
                    } else {
                      _goals.remove(g);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              title: Text(l10n.dataConsent),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _ashaPreference,
              items: const [
                DropdownMenuItem(value: 'yes', child: Text('Connect ASHA now')),
                DropdownMenuItem(value: 'later', child: Text('Maybe later')),
                DropdownMenuItem(value: 'no', child: Text('No')),                
              ],
              onChanged: (v) => setState(() => _ashaPreference = v ?? 'later'),
              decoration: const InputDecoration(labelText: 'ASHA Connection Preference'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
