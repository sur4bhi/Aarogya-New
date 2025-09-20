import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _currentUser;
  String? _lastError;

  // Phone auth state
  String? _verificationId;
  int? _resendToken;

  AuthProvider() {
    _currentUser = _auth.currentUser;
    _auth.userChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  // Getters
  bool get isLoggedIn => _currentUser != null;
  String? get userId => _currentUser?.uid;
  User? get currentUser => _currentUser;
  String? get lastError => _lastError;

  // Email/Password Sign In
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _lastError = null;
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = cred.user;
      notifyListeners();
      return cred;
    } on FirebaseAuthException catch (e) {
      _lastError = _mapAuthError(e);
      notifyListeners();
      rethrow;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Email/Password Registration
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _lastError = null;
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = cred.user;
      notifyListeners();
      return cred;
    } on FirebaseAuthException catch (e) {
      _lastError = _mapAuthError(e);
      notifyListeners();
      rethrow;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Phone Auth: Send OTP
  Future<void> sendOtp(String phoneNumber) async {
    _lastError = null;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval on Android
          final cred = await _auth.signInWithCredential(credential);
          _currentUser = cred.user;
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          _lastError = _mapAuthError(e);
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      _lastError = _mapAuthError(e);
      notifyListeners();
      rethrow;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Phone Auth: Verify OTP
  Future<UserCredential> verifyOtp(String smsCode) async {
    try {
      if (_verificationId == null) {
        throw FirebaseAuthException(
          code: 'invalid-verification-id',
          message: 'No verification ID. Please request OTP again.',
        );
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final cred = await _auth.signInWithCredential(credential);
      _currentUser = cred.user;
      notifyListeners();
      return cred;
    } on FirebaseAuthException catch (e) {
      _lastError = _mapAuthError(e);
      notifyListeners();
      rethrow;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  String _mapAuthError(FirebaseAuthException e) {
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
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}
