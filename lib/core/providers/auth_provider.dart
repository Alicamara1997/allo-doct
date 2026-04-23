import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _authService.userStream.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        setLoading(true);
        _currentUser = await _authService.getUserData(firebaseUser.uid);
        setLoading(false);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> refreshUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _currentUser = await _authService.getUserData(firebaseUser.uid);
      notifyListeners();
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    setLoading(true);
    clearError();
    try {
      _currentUser = await _authService.signInWithEmailAndPassword(email, password);
      return _currentUser != null;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String name, String role) async {
    setLoading(true);
    clearError();
    try {
      _currentUser = await _authService.registerWithEmailAndPassword(email, password, name, role);
      return _currentUser != null;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
