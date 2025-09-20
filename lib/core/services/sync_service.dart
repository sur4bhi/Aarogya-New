import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'local_storage.dart';
import '../constants.dart';

class SyncService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static Timer? _syncTimer;
  static bool _isOnline = false;
  static bool _isSyncing = false;
  
  // Sync status callback
  static Function(SyncStatus)? onSyncStatusChanged;
  
  // Initialize sync service
  static Future<void> init() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    
    // Start periodic sync
    _startPeriodicSync();
    
    // Perform initial sync if online
    if (_isOnline) {
      await syncAll();
    }
  }
  
  // Dispose sync service
  static void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
  
  // Handle connectivity changes
  static void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final wasOnline = _isOnline;
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    if (!wasOnline && _isOnline) {
      // Just came online, sync all pending data
      await syncAll();
    }
    
    onSyncStatusChanged?.call(
      _isOnline ? SyncStatus.online : SyncStatus.offline,
    );
  }
  
  // Start periodic sync
  static void _startPeriodicSync() {
    _syncTimer = Timer.periodic(
      const Duration(minutes: AppConstants.syncIntervalMinutes),
      (timer) async {
        if (_isOnline && !_isSyncing) {
          await syncAll();
        }
      },
    );
  }
  
  // Check if device is online
  static bool get isOnline => _isOnline;
  
  // Check if currently syncing
  static bool get isSyncing => _isSyncing;
  
  // Sync all data
  static Future<void> syncAll() async {
    if (_isSyncing || !_isOnline) return;
    
    _isSyncing = true;
    onSyncStatusChanged?.call(SyncStatus.syncing);
    
    try {
      // Sync in order of priority
      await syncUserProfile();
      await syncVitalsData();
      await syncReminders();
      await syncReports();
      await syncChatMessages();
      
      // Update last sync time
      await LocalStorageService.saveLastSyncTime(DateTime.now());
      
      onSyncStatusChanged?.call(SyncStatus.synced);
    } catch (e) {
      onSyncStatusChanged?.call(SyncStatus.error);
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  // Sync user profile
  static Future<void> syncUserProfile() async {
    final user = FirebaseService.getCurrentUser();
    if (user == null) return;
    
    try {
      // Get local user data
      final localUserData = LocalStorageService.getUserProfile();
      
      if (localUserData != null) {
        // Check if local data needs to be uploaded
        final needsUpload = localUserData['needsSync'] == true;
        
        if (needsUpload) {
          // Upload local changes to Firebase
          await FirebaseService.updateUserProfile(user.uid, localUserData);
          
          // Mark as synced
          localUserData['needsSync'] = false;
          await LocalStorageService.saveUserProfile(localUserData);
        }
      }
      
      // Download latest data from Firebase
      final remoteUserData = await FirebaseService.getUserProfile(user.uid);
      if (remoteUserData.exists) {
        final data = remoteUserData.data() as Map<String, dynamic>;
        await LocalStorageService.saveUserProfile(data);
      }
    } catch (e) {
      print('User profile sync error: $e');
    }
  }
  
  // Sync vitals data
  static Future<void> syncVitalsData() async {
    final user = FirebaseService.getCurrentUser();
    if (user == null) return;
    
    try {
      // Upload pending vitals records
      final localVitals = LocalStorageService.getAllVitalsRecords();
      
      for (final vital in localVitals) {
        if (vital['needsSync'] == true) {
          await FirebaseService.addVitalsRecord(user.uid, vital);
          
          // Mark as synced
          vital['needsSync'] = false;
          await LocalStorageService.saveVitalsRecord(vital['id'], vital);
        }
      }
      
      // Download recent vitals from Firebase
      final lastSyncTime = LocalStorageService.getLastSyncTime();
      final remoteVitals = await FirebaseService.getUserVitals(user.uid);
      
      for (final doc in remoteVitals.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Normalize Firestore Timestamp to DateTime if present
        DateTime? ts;
        final rawTs = data['timestamp'];
        if (rawTs is Timestamp) {
          ts = rawTs.toDate();
        } else if (rawTs is String) {
          ts = DateTime.tryParse(rawTs);
        } else if (rawTs is DateTime) {
          ts = rawTs;
        }

        // Only save if it's newer than last sync
        if (lastSyncTime == null || (ts != null && ts.isAfter(lastSyncTime))) {
          await LocalStorageService.saveVitalsRecord(doc.id, data);
        }
      }
    } catch (e) {
      print('Vitals sync error: $e');
    }
  }
  
  // Sync reminders
  static Future<void> syncReminders() async {
    final user = FirebaseService.getCurrentUser();
    if (user == null) return;
    
    try {
      // Upload pending reminders
      final localReminders = LocalStorageService.getAllReminders();
      
      for (final reminder in localReminders) {
        if (reminder['needsSync'] == true) {
          if (reminder['id'] != null) {
            // Update existing reminder
            await FirebaseService.updateDocument(
              'users/${user.uid}/reminders',
              reminder['id'],
              reminder,
            );
          } else {
            // Create new reminder
            final docRef = await FirebaseService.addDocument(
              'users/${user.uid}/reminders',
              reminder,
            );
            reminder['id'] = docRef.id;
          }
          
          // Mark as synced
          reminder['needsSync'] = false;
          await LocalStorageService.saveReminder(reminder['id'], reminder);
        }
      }
      
      // Download reminders from Firebase
      final remoteReminders = await FirebaseService.getCollection(
        'users/${user.uid}/reminders',
      );
      
      for (final doc in remoteReminders.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        await LocalStorageService.saveReminder(doc.id, data);
      }
    } catch (e) {
      print('Reminders sync error: $e');
    }
  }
  
  // Sync reports
  static Future<void> syncReports() async {
    final user = FirebaseService.getCurrentUser();
    if (user == null) return;
    
    try {
      // Upload pending reports
      final localReports = LocalStorageService.getAllReports();
      
      for (final report in localReports) {
        if (report['needsSync'] == true) {
          if (report['id'] != null) {
            // Update existing report
            await FirebaseService.updateDocument(
              'users/${user.uid}/reports',
              report['id'],
              report,
            );
          } else {
            // Create new report
            final docRef = await FirebaseService.addDocument(
              'users/${user.uid}/reports',
              report,
            );
            report['id'] = docRef.id;
          }
          
          // Mark as synced
          report['needsSync'] = false;
          await LocalStorageService.saveReport(report['id'], report);
        }
      }
      
      // Download reports from Firebase
      final remoteReports = await FirebaseService.getCollection(
        'users/${user.uid}/reports',
      );
      
      for (final doc in remoteReports.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        await LocalStorageService.saveReport(doc.id, data);
      }
    } catch (e) {
      print('Reports sync error: $e');
    }
  }
  
  // Sync chat messages
  static Future<void> syncChatMessages() async {
    final user = FirebaseService.getCurrentUser();
    if (user == null) return;
    
    try {
      // Get pending offline messages
      final offlineData = await LocalStorageService.getAllOfflineData();
      final pendingMessages = offlineData
          .where((data) => data['type'] == 'chat_message')
          .toList();
      
      // Upload pending messages
      for (final messageData in pendingMessages) {
        final chatId = messageData['chatId'];
        final message = messageData['message'];
        
        await FirebaseService.sendMessage(chatId, message);
        
        // Remove from offline storage
        await LocalStorageService.saveOfflineData(messageData['id'], {});
      }
    } catch (e) {
      print('Chat messages sync error: $e');
    }
  }
  
  // Save data for offline sync
  static Future<void> saveForOfflineSync(
    String type,
    Map<String, dynamic> data,
  ) async {
    data['type'] = type;
    data['needsSync'] = true;
    data['offlineTimestamp'] = DateTime.now().toIso8601String();
    
    final id = '${type}_${DateTime.now().millisecondsSinceEpoch}';
    await LocalStorageService.saveOfflineData(id, data);
    
    // Try to sync immediately if online
    if (_isOnline) {
      await syncAll();
    }
  }
  
  // Force sync
  static Future<void> forceSync() async {
    if (!_isOnline) {
      throw Exception('Cannot sync while offline');
    }
    
    await syncAll();
  }
  
  // Get sync status
  static SyncStatus getSyncStatus() {
    if (!_isOnline) return SyncStatus.offline;
    if (_isSyncing) return SyncStatus.syncing;
    
    final lastSyncTime = LocalStorageService.getLastSyncTime();
    if (lastSyncTime == null) return SyncStatus.never;
    
    final timeSinceSync = DateTime.now().difference(lastSyncTime);
    if (timeSinceSync.inMinutes < 5) {
      return SyncStatus.synced;
    } else {
      return SyncStatus.stale;
    }
  }
  
  // Get last sync time
  static DateTime? getLastSyncTime() {
    return LocalStorageService.getLastSyncTime();
  }
  
  // Get sync statistics
  static Future<Map<String, dynamic>> getSyncStats() async {
    final offlineData = await LocalStorageService.getAllOfflineData();
    final pendingSync = offlineData.where((data) => data['needsSync'] == true).length;
    
    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'lastSyncTime': getLastSyncTime()?.toIso8601String(),
      'pendingSyncItems': pendingSync,
      'syncStatus': getSyncStatus().toString(),
    };
  }
  
  // Clear sync data
  static Future<void> clearSyncData() async {
    await LocalStorageService.clearOfflineData();
    await LocalStorageService.remove('last_sync_time');
  }
  
  // Retry failed sync
  static Future<void> retrySync() async {
    if (_isOnline && !_isSyncing) {
      await syncAll();
    }
  }
}

// Sync status enum
enum SyncStatus {
  online,
  offline,
  syncing,
  synced,
  error,
  never,
  stale,
}
