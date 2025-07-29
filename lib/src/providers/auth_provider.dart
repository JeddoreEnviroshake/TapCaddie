import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({
    required AuthService authService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService {
    _initialize();
  }

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;

  // Initialize auth state listener
  void _initialize() {
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;
      
      if (user != null) {
        await _loadUserModel(user.uid);
      } else {
        _userModel = null;
      }
      
      notifyListeners();
    });
  }

  // Load user model from Firestore
  Future<void> _loadUserModel(String userId) async {
    try {
      _userModel = await _firestoreService.getUser(userId);
      
      // Create user document if it doesn't exist
      if (_userModel == null && _firebaseUser != null) {
        await _createUserDocument(_firebaseUser!);
      }
    } catch (e) {
      _setError('Failed to load user data: $e');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User firebaseUser) async {
    try {
      final newUser = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );
      
      await _firestoreService.createUser(newUser);
      _userModel = newUser;
    } catch (e) {
      _setError('Failed to create user profile: $e');
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailPassword(String email, String password) async {
    return _handleAuthOperation(() async {
      await _authService.signInWithEmailPassword(email, password);
      return true;
    });
  }

  // Register with email and password
  Future<bool> registerWithEmailPassword(String email, String password, String name) async {
    return _handleAuthOperation(() async {
      await _authService.registerWithEmailPassword(email, password, name);
      return true;
    });
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    return _handleAuthOperation(() async {
      await _authService.signInWithGoogle();
      return true;
    });
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    return _handleAuthOperation(() async {
      await _authService.signInWithApple();
      return true;
    });
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    return _handleAuthOperation(() async {
      await _authService.sendPasswordResetEmail(email);
      return true;
    });
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoUrl,
    List<Club>? clubs,
    Map<String, double>? clubDistances,
  }) async {
    if (_userModel == null || _firebaseUser == null) return false;

    return _handleAuthOperation(() async {
      // Update Firebase Auth profile if needed
      if (displayName != null || photoUrl != null) {
        await _authService.updateProfile(
          displayName: displayName,
          photoURL: photoUrl,
        );
      }

      // Update Firestore document
      final updatedUser = _userModel!.copyWith(
        name: displayName ?? _userModel!.name,
        photoUrl: photoUrl ?? _userModel!.photoUrl,
        clubs: clubs ?? _userModel!.clubs,
        clubDistances: clubDistances ?? _userModel!.clubDistances,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateUser(updatedUser);
      _userModel = updatedUser;
      
      return true;
    });
  }

  // Add or update club
  Future<bool> addOrUpdateClub(Club club) async {
    if (_userModel == null) return false;

    final clubs = List<Club>.from(_userModel!.clubs);
    final existingIndex = clubs.indexWhere((c) => c.id == club.id);
    
    if (existingIndex != -1) {
      clubs[existingIndex] = club;
    } else {
      clubs.add(club);
    }

    return updateUserProfile(clubs: clubs);
  }

  // Remove club
  Future<bool> removeClub(String clubId) async {
    if (_userModel == null) return false;

    final clubs = _userModel!.clubs.where((c) => c.id != clubId).toList();
    return updateUserProfile(clubs: clubs);
  }

  // Update club distances based on shot history
  Future<bool> updateClubDistances(Map<String, double> newDistances) async {
    if (_userModel == null) return false;

    final updatedDistances = Map<String, double>.from(_userModel!.clubDistances);
    updatedDistances.addAll(newDistances);

    return updateUserProfile(clubDistances: updatedDistances);
  }

  // Update email
  Future<bool> updateEmail(String newEmail, String password) async {
    if (_firebaseUser == null) return false;

    return _handleAuthOperation(() async {
      // Reauthenticate first
      await _authService.reauthenticate(password);
      
      // Update email
      await _authService.updateEmail(newEmail);
      
      // Update user model
      if (_userModel != null) {
        final updatedUser = _userModel!.copyWith(
          email: newEmail,
          updatedAt: DateTime.now(),
        );
        await _firestoreService.updateUser(updatedUser);
        _userModel = updatedUser;
      }
      
      return true;
    });
  }

  // Update password
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    if (_firebaseUser == null) return false;

    return _handleAuthOperation(() async {
      // Reauthenticate first
      await _authService.reauthenticate(currentPassword);
      
      // Update password
      await _authService.updatePassword(newPassword);
      
      return true;
    });
  }

  // Delete account
  Future<bool> deleteAccount(String password) async {
    if (_firebaseUser == null) return false;

    return _handleAuthOperation(() async {
      // Reauthenticate first
      await _authService.reauthenticate(password);
      
      // Delete user data from Firestore (should be handled by Cloud Functions in production)
      // For now, we'll just delete the user document
      
      // Delete Firebase Auth account
      await _authService.deleteAccount();
      
      return true;
    });
  }

  // Sign out
  Future<bool> signOut() async {
    return _handleAuthOperation(() async {
      await _authService.signOut();
      _userModel = null;
      return true;
    });
  }

  // Get club by ID
  Club? getClubById(String clubId) {
    if (_userModel == null) return null;
    
    try {
      return _userModel!.clubs.firstWhere((club) => club.id == clubId);
    } catch (e) {
      return null;
    }
  }

  // Get club by NFC tag ID
  Club? getClubByNfcTag(String nfcTagId) {
    if (_userModel == null) return null;
    
    try {
      return _userModel!.clubs.firstWhere((club) => club.nfcTagId == nfcTagId);
    } catch (e) {
      return null;
    }
  }

  // Get club average distance
  double? getClubDistance(String clubId) {
    if (_userModel == null) return null;
    return _userModel!.clubDistances[clubId];
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Handle authentication operations with loading states and error handling
  Future<bool> _handleAuthOperation(Future<bool> Function() operation) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await operation();
      _setLoading(false);
      return result;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void _clearError() {
    _errorMessage = null;
  }
}