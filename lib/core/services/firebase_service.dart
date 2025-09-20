import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Authentication Methods
  
  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailPassword(
    String email, 
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Register with email and password
  static Future<UserCredential?> registerWithEmailPassword(
    String email, 
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Update FirebaseAuth user's basic profile (displayName, photoURL)
  static Future<void> updateAuthProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
    }
  }
  
  // Firestore Methods
  
  // Create document
  static Future<void> createDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(documentId).set(data);
  }
  
  // Update document
  static Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(documentId).update(data);
  }
  
  // Get document
  static Future<DocumentSnapshot> getDocument(
    String collection,
    String documentId,
  ) async {
    return await _firestore.collection(collection).doc(documentId).get();
  }
  
  // Delete document
  static Future<void> deleteDocument(
    String collection,
    String documentId,
  ) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }
  
  // Get collection
  static Future<QuerySnapshot> getCollection(String collection) async {
    return await _firestore.collection(collection).get();
  }
  
  // Get collection with query
  static Future<QuerySnapshot> getCollectionWithQuery(
    String collection,
    List<QueryFilter> filters,
  ) async {
    Query query = _firestore.collection(collection);
    
    for (final filter in filters) {
      query = query.where(filter.field, isEqualTo: filter.value);
    }
    
    return await query.get();
  }
  
  // Stream document
  static Stream<DocumentSnapshot> streamDocument(
    String collection,
    String documentId,
  ) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }
  
  // Stream collection
  static Stream<QuerySnapshot> streamCollection(String collection) {
    return _firestore.collection(collection).snapshots();
  }
  
  // Stream collection with query
  static Stream<QuerySnapshot> streamCollectionWithQuery(
    String collection,
    List<QueryFilter> filters,
  ) {
    Query query = _firestore.collection(collection);
    
    for (final filter in filters) {
      query = query.where(filter.field, isEqualTo: filter.value);
    }
    
    return query.snapshots();
  }
  
  // Add document to collection
  static Future<DocumentReference> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    return await _firestore.collection(collection).add(data);
  }
  
  // Batch write
  static Future<void> batchWrite(List<BatchOperation> operations) async {
    final batch = _firestore.batch();
    
    for (final operation in operations) {
      final docRef = _firestore.collection(operation.collection).doc(operation.documentId);
      
      switch (operation.type) {
        case BatchOperationType.set:
          batch.set(docRef, operation.data!);
          break;
        case BatchOperationType.update:
          batch.update(docRef, operation.data!);
          break;
        case BatchOperationType.delete:
          batch.delete(docRef);
          break;
      }
    }
    
    await batch.commit();
  }
  
  // Storage Methods
  
  // Upload file
  static Future<String> uploadFile(
    String path,
    File file,
  ) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
  
  // Upload file with metadata
  static Future<String> uploadFileWithMetadata(
    String path,
    File file,
    SettableMetadata metadata,
  ) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
  
  // Delete file
  static Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }
  
  // Get download URL
  static Future<String> getDownloadURL(String path) async {
    final ref = _storage.ref().child(path);
    return await ref.getDownloadURL();
  }
  
  // User-specific methods
  
  // Create user profile
  static Future<void> createUserProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    await createDocument('users', userId, {
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Update user profile
  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    await updateDocument('users', userId, {
      ...userData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Get user profile
  static Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await getDocument('users', userId);
  }
  
  // Stream user profile
  static Stream<DocumentSnapshot> streamUserProfile(String userId) {
    return streamDocument('users', userId);
  }
  
  // Vitals methods
  
  // Add vitals record
  static Future<void> addVitalsRecord(
    String userId,
    Map<String, dynamic> vitalsData,
  ) async {
    await addDocument('users/$userId/vitals', {
      ...vitalsData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  // Get user vitals
  static Future<QuerySnapshot> getUserVitals(String userId) async {
    return await _firestore
        .collection('users/$userId/vitals')
        .orderBy('timestamp', descending: true)
        .get();
  }
  
  // Stream user vitals
  static Stream<QuerySnapshot> streamUserVitals(String userId) {
    return _firestore
        .collection('users/$userId/vitals')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  // Chat methods
  
  // Send message
  static Future<void> sendMessage(
    String chatId,
    Map<String, dynamic> messageData,
  ) async {
    await addDocument('chats/$chatId/messages', {
      ...messageData,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // Update chat metadata
    await updateDocument('chats', chatId, {
      'lastMessage': messageData['text'],
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Stream chat messages
  static Stream<QuerySnapshot> streamChatMessages(String chatId) {
    return _firestore
        .collection('chats/$chatId/messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  // Get user chats
  static Stream<QuerySnapshot> streamUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
  
  // Error handling
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}

// Helper classes
class QueryFilter {
  final String field;
  final dynamic value;
  
  QueryFilter({required this.field, required this.value});
}

class BatchOperation {
  final String collection;
  final String documentId;
  final BatchOperationType type;
  final Map<String, dynamic>? data;
  
  BatchOperation({
    required this.collection,
    required this.documentId,
    required this.type,
    this.data,
  });
}

enum BatchOperationType { set, update, delete }
