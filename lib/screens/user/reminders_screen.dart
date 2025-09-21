import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/reminder_model.dart';
import '../../providers/reminders_provider.dart';
import '../../l10n/app_localizations.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<void> _shareReminder(BuildContext context, ReminderModel r) async {
    final when = r.scheduledTime;
    final msg = 'Reminder: ${r.title} • ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.reminders ?? 'Reminders')),
      body: Consumer<RemindersProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = provider.reminders;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('No reminders yet'),
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = items[index];
              return ListTile(
                leading: CircleAvatar(child: Text(r.type.icon)),
                title: Text(r.title),
                subtitle: Text(
                  '${r.type.displayName} • ${r.scheduledTime} • ${r.statusText}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: r.isActive,
                      onChanged: (v) => context.read<RemindersProvider>().toggleActive(r.id, v),
                    ),
                    IconButton(
                      tooltip: 'Share via WhatsApp',
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => _shareReminder(context, r),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => context.read<RemindersProvider>().deleteReminder(r.id),
                    ),
                  ],
                ),
                onTap: () => _openEditSheet(context, r),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _ReminderForm(onSubmit: (payload) async {
          await context.read<RemindersProvider>().createReminder(
                userId: 'local',
                title: payload.title,
                type: payload.type,
                scheduledTime: payload.when,
                frequency: payload.frequency,
                medicationName: payload.medicationName,
                dosage: payload.dosage,
                instructions: payload.instructions,
                doctorName: payload.doctorName,
                location: payload.location,
                notes: payload.notes,
                vitalType: payload.vitalType,
                targetValue: payload.targetValue,
                unit: payload.unit,
              );
          if (context.mounted) Navigator.pop(context);
        }),
      ),
    );
  }

  void _openEditSheet(BuildContext context, ReminderModel r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _ReminderForm(
          initial: r,
          onSubmit: (payload) async {
            await context.read<RemindersProvider>().updateReminder(
                  r.copyWith(
                    title: payload.title,
                    type: payload.type,
                    scheduledTime: payload.when,
                    frequency: payload.frequency,
                    medicationName: payload.medicationName,
                    dosage: payload.dosage,
                    instructions: payload.instructions,
                    doctorName: payload.doctorName,
                    location: payload.location,
                    notes: payload.notes,
                    vitalType: payload.vitalType,
                    targetValue: payload.targetValue,
                    unit: payload.unit,
                  ),
                );
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _ReminderFormPayload {
  final String title;
  final ReminderType type;
  final DateTime when;
  final ReminderFrequency frequency;
  final String? medicationName;
  final String? dosage;
  final String? instructions;
  final String? doctorName;
  final String? location;
  final String? notes;
  final String? vitalType;
  final String? targetValue;
  final String? unit;
  _ReminderFormPayload({
    required this.title,
    required this.type,
    required this.when,
    required this.frequency,
    this.medicationName,
    this.dosage,
    this.instructions,
    this.doctorName,
    this.location,
    this.notes,
    this.vitalType,
    this.targetValue,
    this.unit,
  });
}

class _ReminderForm extends StatefulWidget {
  final ReminderModel? initial;
  final ValueChanged<_ReminderFormPayload> onSubmit;
  const _ReminderForm({this.initial, required this.onSubmit});

  @override
  State<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<_ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late ReminderType _type;
  late ReminderFrequency _freq;
  DateTime _when = DateTime.now().add(const Duration(minutes: 5));

  // Optional fields
  final _medicationName = TextEditingController();
  final _dosage = TextEditingController();
  final _instructions = TextEditingController();
  final _doctorName = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();
  final _vitalType = TextEditingController();
  final _targetValue = TextEditingController();
  final _unit = TextEditingController();

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _title = TextEditingController(text: r?.title ?? '');
    _type = r?.type ?? ReminderType.medication;
    _freq = r?.frequency ?? ReminderFrequency.once;
    _when = r?.scheduledTime ?? _when;
    _medicationName.text = r?.medicationName ?? '';
    _dosage.text = r?.dosage ?? '';
    _instructions.text = r?.instructions ?? '';
    _doctorName.text = r?.doctorName ?? '';
    _location.text = r?.location ?? '';
    _notes.text = r?.notes ?? '';
    _vitalType.text = r?.vitalType ?? '';
    _targetValue.text = r?.targetValue ?? '';
    _unit.text = r?.unit ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _medicationName.dispose();
    _dosage.dispose();
    _instructions.dispose();
    _doctorName.dispose();
    _location.dispose();
    _notes.dispose();
    _vitalType.dispose();
    _targetValue.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.initial == null ? 'Create Reminder' : 'Edit Reminder',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReminderType>(
                value: _type,
                items: ReminderType.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.displayName)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReminderFrequency>(
                value: _freq,
                items: ReminderFrequency.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.displayName)))
                    .toList(),
                onChanged: (v) => setState(() => _freq = v ?? _freq),
                decoration: const InputDecoration(labelText: 'Frequency'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('When: ${_when.toLocal()}')),
                  TextButton(
                    onPressed: _pickDateTime,
                    child: const Text('Change'),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (_type == ReminderType.medication) ...[
                TextFormField(controller: _medicationName, decoration: const InputDecoration(labelText: 'Medicine name')),
                TextFormField(controller: _dosage, decoration: const InputDecoration(labelText: 'Dosage')),
                TextFormField(controller: _instructions, decoration: const InputDecoration(labelText: 'Instructions')),
              ] else if (_type == ReminderType.appointment) ...[
                TextFormField(controller: _doctorName, decoration: const InputDecoration(labelText: 'Doctor name')),
                TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
                TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes')),
              ] else if (_type == ReminderType.healthCheck) ...[
                TextFormField(controller: _vitalType, decoration: const InputDecoration(labelText: 'Vital type')),
                TextFormField(controller: _targetValue, decoration: const InputDecoration(labelText: 'Target value')),
                TextFormField(controller: _unit, decoration: const InputDecoration(labelText: 'Unit')),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (time == null) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(_ReminderFormPayload(
      title: _title.text.trim(),
      type: _type,
      when: _when,
      frequency: _freq,
      medicationName: _medicationName.text.trim().isEmpty ? null : _medicationName.text.trim(),
      dosage: _dosage.text.trim().isEmpty ? null : _dosage.text.trim(),
      instructions: _instructions.text.trim().isEmpty ? null : _instructions.text.trim(),
      doctorName: _doctorName.text.trim().isEmpty ? null : _doctorName.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      vitalType: _vitalType.text.trim().isEmpty ? null : _vitalType.text.trim(),
      targetValue: _targetValue.text.trim().isEmpty ? null : _targetValue.text.trim(),
      unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
    ));
  }
}
