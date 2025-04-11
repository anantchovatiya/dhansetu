import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_data.dart';

class UserAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  UserData? _userData;
  bool _isLoading = true;

  UserAuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        try {
          // Get initial user data
          final preferences = await _authService.getUserPreferences(user.uid);
          _userData = UserData(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoURL: user.photoURL,
            createdAt: DateTime.now(),
            preferences: preferences,
          );
          
          // Listen for updates
          _authService.userDataStream(user.uid).listen((UserData? userData) {
            if (userData != null) {
              _userData = userData;
            }
            _isLoading = false;
            notifyListeners();
          });
        } catch (e) {
          print('Error initializing user data: $e');
          _isLoading = false;
          notifyListeners();
        }
      } else {
        _userData = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  User? get user => _user;
  UserData? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<bool> signInWithGoogle() async {
    try {
      final result = await _authService.signInWithGoogle();
      return result != null;
    } catch (e) {
      print('Error in signInWithGoogle: $e');
      return false;
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    if (_user == null) return;
    try {
      await _authService.updateUserPreferences(_user!.uid, preferences);
      _userData = _userData?.copyWith(preferences: preferences);
      notifyListeners();
    } catch (e) {
      print('Error updating preferences: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPreferences() async {
    if (_user == null) return {};
    try {
      return await _authService.getUserPreferences(_user!.uid);
    } catch (e) {
      print('Error getting preferences: $e');
      return {};
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
} 