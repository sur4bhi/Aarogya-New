import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/services/local_storage.dart';
import '../core/services/notification_service.dart';
import '../models/reminder_model.dart';

class RemindersProvider extends ChangeNotifier {
  final List<ReminderModel> _reminders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReminderModel> get reminders => List.unmodifiable(_reminders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadReminders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final items = LocalStorageService.getAllReminders();
      final parsed = <ReminderModel>[];
      for (final m in items) {
        try {
          parsed.add(ReminderModel.fromJson(m));
        } catch (e) {
          if (kDebugMode) {
            print('Skipping malformed reminder: $e');
          }
        }
      }
      parsed.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      _reminders
        ..clear()
        ..addAll(parsed);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ReminderModel> createReminder({
    required String userId,
    required String title,
    required ReminderType type,
    required DateTime scheduledTime,
    ReminderFrequency frequency = ReminderFrequency.once,
    String? description,
    // Medication specifics
    String? medicationName,
    String? dosage,
    String? instructions,
    // Appointment specifics
    String? doctorName,
    String? location,
    String? notes,
    // Health check specifics
    String? vitalType,
    String? targetValue,
    String? unit,
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final reminder = ReminderModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      type: type,
      scheduledTime: scheduledTime,
      frequency: frequency,
      isActive: true,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      medicationName: medicationName,
      dosage: dosage,
      instructions: instructions,
      doctorName: doctorName,
      location: location,
      notes: notes,
      vitalType: vitalType,
      targetValue: targetValue,
      unit: unit,
    );

    await _persistAndSchedule(reminder);
    _reminders.add(reminder);
    _reminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    notifyListeners();
    return reminder;
  }

  Future<void> updateReminder(ReminderModel updated) async {
    final idx = _reminders.indexWhere((r) => r.id == updated.id);
    if (idx == -1) return;
    final copy = updated.copyWith(updatedAt: DateTime.now());
    _reminders[idx] = copy;
    _reminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    await _persistAndSchedule(copy, replaceExisting: true);
    notifyListeners();
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await LocalStorageService.deleteReminder(id);
    await NotificationService.cancelNotification(id.hashCode);
    notifyListeners();
  }

  Future<void> toggleActive(String id, bool isActive) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final r = _reminders[idx].copyWith(isActive: isActive, updatedAt: DateTime.now());
    _reminders[idx] = r;
    await LocalStorageService.saveReminder(id, r.toJson());
    if (isActive) {
      await _schedule(r);
    } else {
      await NotificationService.cancelNotification(id.hashCode);
    }
    notifyListeners();
  }

  Future<void> markCompleted(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final r = _reminders[idx].copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _reminders[idx] = r;
    await LocalStorageService.saveReminder(id, r.toJson());
    await NotificationService.cancelNotification(id.hashCode);
    notifyListeners();
  }

  Future<void> _persistAndSchedule(ReminderModel r, {bool replaceExisting = false}) async {
    await LocalStorageService.saveReminder(r.id, r.toJson());
    if (replaceExisting) {
      await NotificationService.cancelNotification(r.id.hashCode);
    }
    if (r.isActive && !r.isCompleted) {
      await _schedule(r);
    }
  }

  Future<void> _schedule(ReminderModel r) async {
    // Ensure permissions
    await NotificationService.requestPermissions();

    switch (r.type) {
      case ReminderType.medication:
        await NotificationService.scheduleMedicationReminder(
          id: r.id.hashCode,
          medicationName: r.medicationName ?? r.title,
          reminderTime: r.scheduledTime,
          dosage: r.dosage,
          instructions: r.instructions,
        );
        break;
      case ReminderType.appointment:
        await NotificationService.scheduleAppointmentReminder(
          id: r.id.hashCode,
          doctorName: r.doctorName ?? r.title,
          appointmentTime: r.scheduledTime,
          location: r.location,
        );
        break;
      case ReminderType.healthCheck:
        await NotificationService.scheduleVitalsReminder(
          id: r.id.hashCode,
          vitalType: r.vitalType ?? r.title,
          reminderTime: r.scheduledTime,
        );
        break;
      case ReminderType.exercise:
      case ReminderType.diet:
      case ReminderType.other:
        await NotificationService.scheduleNotification(
          id: r.id.hashCode,
          title: r.title,
          body: r.description ?? 'Reminder',
          scheduledDate: r.scheduledTime,
        );
        break;
    }

    // Handle recurring by scheduling next occurrence as separate notifications if needed.
    final next = r.getNextOccurrence();
    if (next != null) {
      // For MVP, we schedule only the next one upon loading or creation.
      final nextId = (r.id + '_next').hashCode;
      await NotificationService.scheduleNotification(
        id: nextId,
        title: r.title,
        body: r.description ?? 'Reminder',
        scheduledDate: next,
      );
    }
  }
}
