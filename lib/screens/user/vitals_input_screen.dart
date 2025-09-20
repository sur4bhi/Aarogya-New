import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vitals_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/health_utils.dart';
import '../../models/vitals_model.dart';

class VitalsInputScreen extends StatefulWidget {
  const VitalsInputScreen({super.key});

  @override
  State<VitalsInputScreen> createState() => _VitalsInputScreenState();
}

class _VitalsInputScreenState extends State<VitalsInputScreen> {
  final _formKey = GlobalKey<FormState>();

  // Blood Pressure
  final TextEditingController _sysCtrl = TextEditingController();
  final TextEditingController _diaCtrl = TextEditingController();

  // Glucose
  final TextEditingController _glucoseCtrl = TextEditingController();
  String _glucoseType = 'fasting'; // fasting, random, postprandial

  // Weight
  final TextEditingController _weightCtrl = TextEditingController();
  bool _isKg = true; // kg or lbs

  // Date/Time
  DateTime _selectedDateTime = DateTime.now();

  // Notes
  final TextEditingController _notesCtrl = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _sysCtrl.dispose();
    _diaCtrl.dispose();
    _glucoseCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String? _validateSystolic(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final n = int.tryParse(v);
    if (n == null) return 'Enter a valid number';
    if (n < 70 || n > 250) return 'Systolic must be 70-250';
    final d = int.tryParse(_diaCtrl.text);
    if (d != null && n <= d) return 'Systolic must be greater than diastolic';
    return null;
  }

  String? _validateDiastolic(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final n = int.tryParse(v);
    if (n == null) return 'Enter a valid number';
    if (n < 40 || n > 150) return 'Diastolic must be 40-150';
    final s = int.tryParse(_sysCtrl.text);
    if (s != null && n >= s) return 'Diastolic must be less than systolic';
    return null;
  }

  String? _validateGlucose(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final n = int.tryParse(v);
    if (n == null) return 'Enter a valid number';
    if (n < 50 || n > 500) return 'Glucose must be 50-500';
    return null;
  }

  String? _validateWeight(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final val = double.tryParse(v);
    if (val == null) return 'Enter a valid number';
    if (_isKg) {
      if (val < 20 || val > 300) return 'Weight must be 20-300 kg';
    } else {
      final kg = val / 2.20462;
      if (kg < 20 || kg > 300) return 'Weight must be 44-661 lbs';
    }
    return null;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (!_formKey.currentState!.validate()) return;

      if (_selectedDateTime.isAfter(DateTime.now())) {
        throw Exception('Date cannot be in the future');
      }
      if (_selectedDateTime.isBefore(DateTime.now().subtract(const Duration(days: 30)))) {
        throw Exception('Date cannot be older than 30 days');
      }

      final auth = context.read<AuthProvider>();
      final userId = auth.userId ?? 'local_user';

      // Build vitals records for fields that are filled
      final now = DateTime.now();
      final List<VitalsModel> toSave = [];

      // Blood Pressure
      final s = int.tryParse(_sysCtrl.text.trim());
      final d = int.tryParse(_diaCtrl.text.trim());
      if (s != null && d != null) {
        toSave.add(VitalsModel(
          id: 'bp_${_selectedDateTime.millisecondsSinceEpoch}',
          userId: userId,
          timestamp: _selectedDateTime,
          type: VitalType.bloodPressure,
          values: {
            'systolic': s.toDouble(),
            'diastolic': d.toDouble(),
          },
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          isManualEntry: true,
          isSynced: false,
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Glucose
      final g = int.tryParse(_glucoseCtrl.text.trim());
      if (g != null) {
        toSave.add(VitalsModel(
          id: 'glucose_${_selectedDateTime.millisecondsSinceEpoch}',
          userId: userId,
          timestamp: _selectedDateTime,
          type: VitalType.bloodGlucose,
          values: {
            'bloodGlucose': g.toDouble(),
            'glucoseType': _glucoseType,
          },
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          isManualEntry: true,
          isSynced: false,
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Weight
      final w = double.tryParse(_weightCtrl.text.trim());
      if (w != null) {
        final weightKg = _isKg ? w : (w / 2.20462);
        toSave.add(VitalsModel(
          id: 'weight_${_selectedDateTime.millisecondsSinceEpoch}',
          userId: userId,
          timestamp: _selectedDateTime,
          type: VitalType.weight,
          values: {
            'weight': weightKg,
          },
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          isManualEntry: true,
          isSynced: false,
          createdAt: now,
          updatedAt: now,
        ));
      }

      if (toSave.isEmpty) {
        throw Exception('Please enter at least one vital reading');
      }

      final provider = context.read<VitalsProvider>();
      for (final v in toSave) {
        await provider.addVitalsRecord(v);
      }

      // Immediate sync attempt if online (provider.add handles, but ensure)
      if (SyncService.isOnline) {
        await SyncService.syncVitalsData();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vitals saved successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Vitals')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle('Blood Pressure (mmHg)'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sysCtrl,
                          decoration: const InputDecoration(labelText: 'Systolic'),
                          keyboardType: TextInputType.number,
                          validator: _validateSystolic,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _diaCtrl,
                          decoration: const InputDecoration(labelText: 'Diastolic'),
                          keyboardType: TextInputType.number,
                          validator: _validateDiastolic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _sectionTitle('Blood Sugar (mg/dL)'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _glucoseCtrl,
                          decoration: const InputDecoration(labelText: 'Glucose'),
                          keyboardType: TextInputType.number,
                          validator: _validateGlucose,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _glucoseType,
                          items: const [
                            DropdownMenuItem(value: 'fasting', child: Text('Fasting')),
                            DropdownMenuItem(value: 'random', child: Text('Random')),
                            DropdownMenuItem(value: 'postprandial', child: Text('Post-meal')),
                          ],
                          onChanged: (v) => setState(() => _glucoseType = v ?? 'fasting'),
                          decoration: const InputDecoration(labelText: 'Type'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _sectionTitle('Weight'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightCtrl,
                          decoration: InputDecoration(labelText: _isKg ? 'kg' : 'lbs'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: _validateWeight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ToggleButtons(
                        isSelected: [_isKg, !_isKg],
                        onPressed: (i) => setState(() => _isKg = (i == 0)),
                        children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('kg')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('lbs'))],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _sectionTitle('Date & Time'),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDateTime.toLocal().toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickDateTime,
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _sectionTitle('Notes (optional)'),
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(hintText: 'Add any notes'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),

                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save Vitals'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
  }
}
