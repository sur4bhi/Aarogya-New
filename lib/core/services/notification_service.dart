import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  
  // Initialize notification service
  static Future<void> init() async {
    if (_initialized) return;
    
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Android initialization settings
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    _initialized = true;
  }
  
  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap based on payload
    final payload = response.payload;
    if (payload != null) {
      // Navigate to appropriate screen based on payload
      _handleNotificationNavigation(payload);
    }
  }
  
  // Handle notification navigation
  static void _handleNotificationNavigation(String payload) {
    // Parse payload and navigate accordingly
    // This will be implemented based on your navigation structure
    print('Notification tapped with payload: $payload');
  }
  
  // Request notification permissions
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return false;
  }
  
  // Check notification permissions
  static Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    } else if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return result?.isEnabled ?? false;
    }
    return false;
  }
  
  // Show instant notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.defaultPriority,
    String? channelId,
    String? channelName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'default_channel',
      channelName ?? 'Default Notifications',
      channelDescription: 'Default notification channel',
      importance: _getAndroidImportance(priority),
      priority: _getAndroidPriority(priority),
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(id, title, body, details, payload: payload);
  }
  
  // Schedule notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationPriority priority = NotificationPriority.defaultPriority,
    String? channelId,
    String? channelName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'scheduled_channel',
      channelName ?? 'Scheduled Notifications',
      channelDescription: 'Scheduled notification channel',
      importance: _getAndroidImportance(priority),
      priority: _getAndroidPriority(priority),
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  // Schedule repeating notification
  static Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required RepeatInterval repeatInterval,
    String? payload,
    NotificationPriority priority = NotificationPriority.defaultPriority,
    String? channelId,
    String? channelName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'repeating_channel',
      channelName ?? 'Repeating Notifications',
      channelDescription: 'Repeating notification channel',
      importance: _getAndroidImportance(priority),
      priority: _getAndroidPriority(priority),
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.periodicallyShow(
      id,
      title,
      body,
      repeatInterval,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
  
  // Schedule daily notification at specific time
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    NotificationPriority priority = NotificationPriority.defaultPriority,
    String? channelId,
    String? channelName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'daily_channel',
      channelName ?? 'Daily Notifications',
      channelDescription: 'Daily notification channel',
      importance: _getAndroidImportance(priority),
      priority: _getAndroidPriority(priority),
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // If the scheduled time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  
  // Cancel notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
  
  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  // Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
  
  // Get active notifications
  static Future<List<ActiveNotification>> getActiveNotifications() async {
    return await _notifications.getActiveNotifications();
  }
  
  // Health-specific notification methods
  
  // Schedule medication reminder
  static Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required DateTime reminderTime,
    String? dosage,
    String? instructions,
  }) async {
    final title = 'Medication Reminder';
    final body = dosage != null 
        ? 'Time to take $medicationName ($dosage)'
        : 'Time to take $medicationName';
    
    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: reminderTime,
      payload: 'medication:$id',
      priority: NotificationPriority.high,
      channelId: 'medication_channel',
      channelName: 'Medication Reminders',
    );
  }
  
  // Schedule vitals reminder
  static Future<void> scheduleVitalsReminder({
    required int id,
    required String vitalType,
    required DateTime reminderTime,
  }) async {
    final title = 'Health Check Reminder';
    final body = 'Time to record your $vitalType';
    
    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: reminderTime,
      payload: 'vitals:$vitalType',
      priority: NotificationPriority.defaultPriority,
      channelId: 'vitals_channel',
      channelName: 'Vitals Reminders',
    );
  }
  
  // Schedule appointment reminder
  static Future<void> scheduleAppointmentReminder({
    required int id,
    required String doctorName,
    required DateTime appointmentTime,
    String? location,
  }) async {
    final title = 'Appointment Reminder';
    final body = location != null
        ? 'Appointment with Dr. $doctorName at $location'
        : 'Appointment with Dr. $doctorName';
    
    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: appointmentTime.subtract(const Duration(hours: 1)),
      payload: 'appointment:$id',
      priority: NotificationPriority.high,
      channelId: 'appointment_channel',
      channelName: 'Appointment Reminders',
    );
  }
  
  // Show health alert
  static Future<void> showHealthAlert({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
      priority: priority,
      channelId: 'health_alerts',
      channelName: 'Health Alerts',
      payload: 'health_alert',
    );
  }
  
  // Show ASHA message notification
  static Future<void> showAshaMessageNotification({
    required String ashaName,
    required String message,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Message from $ashaName',
      body: message,
      priority: NotificationPriority.high,
      channelId: 'asha_messages',
      channelName: 'ASHA Messages',
      payload: 'asha_message',
    );
  }
  
  // Helper methods
  static Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.min:
        return Importance.min;
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.defaultPriority:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.max:
        return Importance.max;
    }
  }
  
  static Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.min:
        return Priority.min;
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.defaultPriority:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
        return Priority.max;
    }
  }
}

// Notification priority enum
enum NotificationPriority {
  min,
  low,
  defaultPriority,
  high,
  max,
}
