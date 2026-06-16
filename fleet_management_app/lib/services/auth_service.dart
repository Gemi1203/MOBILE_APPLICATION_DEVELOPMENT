import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AppUser? _user;
  String _userRole = '';
  bool _isLoading = true;

  AppUser? get user => _user;
  String get userRole => _userRole;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    try {
      if (firebaseUser == null) {
        _user = null;
        _userRole = '';
        _isLoading = false;
        notifyListeners();
        return;
      }
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        _user = AppUser.fromMap(firebaseUser.uid, doc.data()!);
      } else {
        _user = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? 'Driver',
          role: 'driver',
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(_user!.toMap());
      }

      // ✅ FORCE ADMIN for specific email addresses
      const adminEmails = ['muindigrace403@gmail.com', 'admin@fleet.com'];
      if (_user != null && adminEmails.contains(_user!.email)) {
        _userRole = 'admin';
        // Update Firestore to ensure consistency
        if (_user!.role != 'admin') {
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .update({'role': 'admin'})
              .catchError((e) {
                debugPrint('Error updating admin role: $e');
              });
        }
      } else {
        _userRole = _user?.role ?? 'driver';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error in _onAuthStateChanged: $e');
      _user = null;
      _userRole = '';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        debugPrint('Email or password is empty');
        return false;
      }
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint('User logged in successfully: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'FirebaseAuthException during login: ${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('Generic error during login: $e');
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String name,
    String role,
    String? phone,
  ) async {
    try {
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        debugPrint('Required fields are empty');
        return false;
      }
      if (password.length < 6) {
        debugPrint('Password must be at least 6 characters');
        return false;
      }

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = AppUser(
        id: cred.user!.uid,
        email: email,
        name: name,
        role: role,
        phone: phone,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toMap());
      debugPrint('User registered successfully: $email with role: $role');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'FirebaseAuthException during registration: ${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('Generic error during registration: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _user = null;
      _userRole = '';
      notifyListeners();
      debugPrint('User logged out successfully');
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }
}
