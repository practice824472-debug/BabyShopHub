import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../Models/address_model.dart';

class AuthController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // Lazily created: constructing GoogleSignIn() eagerly on Flutter Web
  // triggers plugin initialization immediately, which throws an assertion
  // error if no Google Sign-In web client ID is configured (see
  // web/index.html). Deferring construction until Google sign-in is
  // actually used avoids that crash on app startup for users who never
  // tap "Sign in with Google" (e.g. on Android/iOS, which read their
  // config from google-services.json / GoogleService-Info.plist instead).
  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn => _googleSignInInstance ??= GoogleSignIn();

  User? _user;
  String? _userRole; // 'user' or 'admin'
  bool _isLoading = false;
  String? _error;

  // Profile state
  String _userName = '';
  String _userPhone = '';
  String _photoUrl = '';
  List<AddressModel> _addresses = [];

  User? get user => _user;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _userRole == 'admin';

  String get userName => _userName;
  String get userPhone => _userPhone;
  String get photoUrl => _photoUrl;
  List<AddressModel> get addresses => List.unmodifiable(_addresses);

  // Check if user is already logged in
  void checkAuthStatus() {
    _user = _auth.currentUser;
    if (_user != null) {
      _loadUserRole();
    }
    notifyListeners();
  }

  // Load user role and profile from Firestore
  Future<void> _loadUserRole() async {
    if (_user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      final data = doc.data() ?? {};
      _userRole = data['role'] ?? 'user';
      _userName = data['name'] ?? '';
      _userPhone = data['phone'] ?? '';
      _photoUrl = data['photoUrl'] ?? '';
      _addresses = List<dynamic>.from(data['addresses'] ?? [])
          .map(AddressModel.fromDynamic)
          .toList();
      notifyListeners();
    } catch (e) {
      _userRole = 'user';
      notifyListeners();
    }
  }

  /// Ensures the current user's role/profile is loaded
  Future<void> ensureUserLoaded() async {
    _user = _auth.currentUser;
    if (_user == null) return;
    if (_userRole == null) {
      await _loadUserRole();
    }
  }

  // ── Profile ──────────────────────────────

  /// Fetches the latest profile data from Firestore.
  Future<void> fetchUserProfile() async {
    if (_user == null) return;
    try {
      final doc =
      await _firestore.collection('users').doc(_user!.uid).get();
      final data = doc.data() ?? {};
      _userName = data['name'] ?? '';
      _userPhone = data['phone'] ?? '';
      _photoUrl = data['photoUrl'] ?? '';
      _addresses = List<dynamic>.from(data['addresses'] ?? [])
          .map(AddressModel.fromDynamic)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  /// Uploads [bytes] to Firebase Storage and stores its URL on the user
  Future<bool> updateProfilePicture(Uint8List bytes) async {
    if (_user == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ref = _storage.ref().child('profile_pictures/${_user!.uid}.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      await _firestore.collection('users').doc(_user!.uid).update({
        'photoUrl': url,
      });
      _photoUrl = url;
      return true;
    } catch (e) {
      _error = 'Failed to upload profile picture.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates name and phone in Firestore.
  Future<bool> updateProfile(String name, String phone) async {
    if (_user == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': name.trim(),
        'phone': phone.trim(),
      });
      _userName = name.trim();
      _userPhone = phone.trim();
      return true;
    } catch (e) {
      _error = 'Failed to update profile.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-authenticates then changes the password.
  Future<bool> updatePassword(
      String currentPassword, String newPassword) async {
    if (_user == null || _user!.email == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      await _user!.reauthenticateWithCredential(cred);
      await _user!.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      return false;
    } catch (e) {
      _error = 'Failed to change password.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Addresses ────────────────────────────

  /// Adds a new address and persists to Firestore.
  Future<bool> addAddress(AddressModel address) async {
    if (_user == null) return false;
    if (address.street.trim().isEmpty) return false;

    try {
      final updated = [..._addresses, address];
      await _firestore.collection('users').doc(_user!.uid).update({
        'addresses': updated.map((a) => a.toMap()).toList(),
      });
      _addresses = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save address.';
      notifyListeners();
      return false;
    }
  }

  /// Removes the address at [index] and persists to Firestore.
  Future<bool> deleteAddress(int index) async {
    if (_user == null || index < 0 || index >= _addresses.length) return false;

    try {
      final updated = [..._addresses]..removeAt(index);
      await _firestore.collection('users').doc(_user!.uid).update({
        'addresses': updated.map((a) => a.toMap()).toList(),
      });
      _addresses = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete address.';
      notifyListeners();
      return false;
    }
  }

  // Login method for both admin and user
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Sign in with Firebase Auth
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      _user = result.user;

      // Load user role from Firestore
      if (_user != null) {
        await _loadUserRole();

        // Block disabled accounts
        final disabled = await isUserDisabled();
        if (disabled) {
          await _auth.signOut();
          _user = null;
          _userRole = null;
          _error = 'Your account has been disabled. Please contact support.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Google Sign-In ──────────────────────

  /// Sign in with Google
  Future<bool> loginWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Sign in with Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _error = 'Google sign-in was cancelled';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      _user = result.user;

      if (_user != null) {
        // Check if user exists in Firestore
        final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
        
        if (!userDoc.exists) {
          // Create new user profile
          await _firestore.collection('users').doc(_user!.uid).set({
            'name': _user!.displayName ?? '',
            'email': _user!.email ?? '',
            'phone': '', // Phone will be filled by user later
            'role': 'user',
            'addresses': [],
            'paymentMethods': [],
            'photoUrl': _user!.photoURL ?? '',
            'isDisabled': false,
            'totalOrders': 0,
            'totalSpent': 0,
            'createdAt': DateTime.now().toIso8601String(),
            'lastLogin': DateTime.now().toIso8601String(),
          });
        } else {
          // Update last login
          await _firestore.collection('users').doc(_user!.uid).update({
            'lastLogin': DateTime.now().toIso8601String(),
          });
        }

        await _loadUserRole();

        // Check if user is disabled
        final disabled = await isUserDisabled();
        if (disabled) {
          await _auth.signOut();
          _user = null;
          _userRole = null;
          _error = 'Your account has been disabled. Please contact support.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to sign in with Google: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register method for users
  Future<bool> register(
      String name,
      String email,
      String password, [
        String phone = '',
      ]) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create user in Firebase Auth
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      _user = result.user;

      if (_user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(_user!.uid).set({
          'name': name,
          'email': email,
          'phone': phone,
          'role': 'user',
          'addresses': [],
          'paymentMethods': [],
          'isDisabled': false,
          'totalOrders': 0,
          'totalSpent': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'lastLogin': DateTime.now().toIso8601String(),
        });

        _userRole = 'user';
        _userName = name;
        _userPhone = phone;
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      // Best-effort: Google sign-out is only relevant if the user actually
      // signed in with Google, and on an unconfigured web build it can
      // throw before it even reaches the network call. Never let that
      // block the real (Firebase) logout that already succeeded above.
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore — Firebase sign-out above is what actually matters.
      }
      _user = null;
      _userRole = null;
      _error = null;
      _userName = '';
      _userPhone = '';
      _photoUrl = '';
      _addresses = [];
      notifyListeners();
    } catch (e) {
      _error = 'Error logging out';
      notifyListeners();
    }
  }

  Future<String> logoutUser() async {
    await logout();
    return error ?? 'Logged out successfully';
  }

  // Forgot password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email.trim());

      _isLoading = false;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check if user is disabled
  Future<bool> isUserDisabled() async {
    if (_user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      return doc.data()?['isDisabled'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get Firebase error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'Email is already registered.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-not-found':
        return 'User not found. Please check your email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'Account exists with different credentials.';
      case 'invalid-credential':
        return 'Invalid credentials.';
      default:
        return 'Authentication error: $code';
    }
  }
}