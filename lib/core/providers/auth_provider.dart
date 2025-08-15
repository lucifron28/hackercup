import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  AppUser? _userData;
  AuthState _authState = AuthState.initial;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  AppUser? get userData => _userData;
  AuthState get authState => _authState;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _authState == AuthState.loading;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    AuthService.userStream.listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _loadUserData();
      } else {
        _userData = null;
        _setAuthState(AuthState.unauthenticated);
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      _userData = await AuthService.getCurrentUserData();
      _setAuthState(AuthState.authenticated);
    } catch (e) {
      _setError('Failed to load user data: $e');
    }
  }

  void _setAuthState(AuthState state) {
    _authState = state;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _authState = AuthState.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Authentication methods
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setAuthState(AuthState.loading);
    clearError();

    try {
      final result = await AuthService.signInWithEmailPassword(email: email, password: password);
      if (result.isSuccess) {
        return true;
      } else {
        _setError(result.error ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    }
  }

  Future<bool> registerDriver({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String licenseNumber,
    required String jeepneyPlateNumber,
    required String routeId,
  }) async {
    _setAuthState(AuthState.loading);
    clearError();

    try {
      final result = await AuthService.registerDriver(
        email: email,
        password: password,
        name: name,
        phone: phone,
        licenseNumber: licenseNumber,
        jeepneyPlateNumber: jeepneyPlateNumber,
        routeId: routeId,
      );

      if (result.isSuccess) {
        return true;
      } else {
        _setError(result.error ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    }
  }

  Future<bool> registerCommuter({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    _setAuthState(AuthState.loading);
    clearError();

    try {
      final result = await AuthService.registerCommuter(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (result.isSuccess) {
        return true;
      } else {
        _setError(result.error ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    _setAuthState(AuthState.loading);
    clearError();

    try {
      final result = await AuthService.signInAnonymously();
      if (result.isSuccess) {
        return true;
      } else {
        _setError(result.error ?? 'Anonymous login failed');
        return false;
      }
    } catch (e) {
      _setError('Anonymous login failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await AuthService.signOut();
      _userData = null;
      _setAuthState(AuthState.unauthenticated);
    } catch (e) {
      _setError('Sign out failed: $e');
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      return await AuthService.resetPassword(email);
    } catch (e) {
      _setError('Password reset failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
