import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Logger _logger = Logger();

  static Stream<User?> get userStream => _auth.authStateChanges();
  
  static User? get currentUser => _auth.currentUser;
  
  static Future<AppUser?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      print('Attempting to fetch user data for: ${user.uid}');
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        print('User data found: ${doc.data()}');
        return AppUser.fromJson({...doc.data()!, 'id': doc.id});
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      if (e.toString().contains('permission-denied')) {
        print('PERMISSION DENIED - Check Firestore security rules!');
        print('Go to: https://console.firebase.google.com/project/jeepgo-96087/firestore/rules');
        _logger.w('Permission denied accessing Firestore. Check security rules.');
      } else if (e.toString().contains('NOT_FOUND') || e.toString().contains('does not exist')) {
        _logger.w('Firestore database not yet created for project. Please create it in Firebase Console.');
        print('⚠Firestore database not created. Visit: https://console.cloud.google.com/datastore/setup?project=jeepgo-96087');
      } else {
        _logger.e('Error fetching user data: $e');
      }
    }
    return null;
  }

  static Future<AuthResult> registerDriver({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String licenseNumber,
    required String jeepneyPlateNumber,
    required String routeId,
  }) async {
    try {
      print('DRIVER REGISTRATION STARTED: $email');
      _logger.i('Registering driver: $email');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        print('✅ Firebase Auth Success: ${credential.user!.uid}');
        
        await credential.user!.updateDisplayName(name);
        print('✅ Display name updated: $name');
        
        try {
          final driverData = DriverModel(
            id: credential.user!.uid,
            name: name,
            email: email,
            phone: phone,
            licenseNumber: licenseNumber,
            jeepneyPlateNumber: jeepneyPlateNumber,
            routeId: routeId,
            isActive: true,
            isOnline: false,
            rating: 5.0,
            totalTrips: 0,
            joinedAt: DateTime.now(),
          );

          await _firestore.collection('users').doc(credential.user!.uid).set({
            'userType': 'driver',
            'name': name,
            'email': email,
            'phone': phone,
            'createdAt': FieldValue.serverTimestamp(),
          });

          print('✅ User document created in Firestore');

          await _firestore.collection('drivers').doc(credential.user!.uid).set(
            driverData.toJson()
          );

          print('✅ Driver profile created in Firestore: ${credential.user!.uid}');
          _logger.i('Driver profile created in Firestore: ${credential.user!.uid}');
          
        } catch (firestoreError) {
          print('⚠️ Firestore error during registration: $firestoreError');
          if (firestoreError.toString().contains('permission-denied')) {
            print('🚨 PERMISSION DENIED - Check Firestore security rules!');
            print('📋 Go to: https://console.firebase.google.com/project/jeepgo-96087/firestore/rules');
            print('⚠️ Registration will continue with Firebase Auth only...');
          }
          _logger.w('Firestore unavailable during registration: $firestoreError');
        }

        try {
          print('✅ Backend registration would happen here for: ${credential.user!.uid}');
          _logger.i('Backend registration would happen here for: ${credential.user!.uid}');
        } catch (backendError) {
          print('⚠️ Backend registration failed: $backendError');
          _logger.w('Backend registration failed: $backendError');
        }

        print('DRIVER REGISTRATION COMPLETED: ${credential.user!.uid}');
        _logger.i('Driver registered successfully: ${credential.user!.uid}');
        return AuthResult.success(credential.user!);
      }
      
      return AuthResult.error('Failed to create account');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      _logger.e('Firebase Auth error: ${e.message}');
      return AuthResult.error(_handleFirebaseAuthError(e));
    } catch (e) {
      print('❌ Registration Error: $e');
      _logger.e('Registration error: $e');
      return AuthResult.error('Registration failed: $e');
    }
  }

  static Future<AuthResult> registerCommuter({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      _logger.i('Registering commuter: $email');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'userType': 'commuter',
          'name': name,
          'email': email,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _logger.i('Commuter registered successfully: ${credential.user!.uid}');
        return AuthResult.success(credential.user!);
      }
      
      return AuthResult.error('Failed to create account');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleFirebaseAuthError(e));
    } catch (e) {
      return AuthResult.error('Registration failed: $e');
    }
  }

  static Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('LOGIN STARTED: $email');
      _logger.i('Signing in user: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        print('✅ LOGIN SUCCESS: ${credential.user!.uid}');
        _logger.i('User signed in successfully: ${credential.user!.uid}');
        
        try {
          final userData = await getCurrentUserData();
          print('✅ User data loaded: ${userData?.userType}');
          _logger.i('User data loaded: ${userData?.userType}');
        } catch (firestoreError) {
          print('⚠️ Could not load user data from Firestore: $firestoreError');
          print('⚠️ Continuing login without Firestore verification...');
          _logger.w('Could not load user data from Firestore: $firestoreError');
        }
        
        return AuthResult.success(credential.user!);
      }
      
      return AuthResult.error('Sign in failed');
    } on FirebaseAuthException catch (e) {
      print('❌ LOGIN ERROR: ${e.code} - ${e.message}');
      return AuthResult.error(_handleFirebaseAuthError(e));
    } catch (e) {
      print('❌ LOGIN ERROR: $e');
      return AuthResult.error('Sign in failed: $e');
    }
  }

  static Future<AuthResult> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'userType': 'commuter',
          'name': 'Anonymous User',
          'isAnonymous': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        return AuthResult.success(credential.user!);
      }
      
      return AuthResult.error('Anonymous sign in failed');
    } catch (e) {
      return AuthResult.error('Anonymous sign in failed: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      print('🚪 SIGN OUT STARTED');
      
      // Try to update driver status but don't let it block logout
      try {
        final userData = await getCurrentUserData().timeout(Duration(seconds: 5));
        if (userData?.userType == 'driver') {
          print('🚗 Updating driver status to offline...');
          await updateDriverOnlineStatus(false).timeout(Duration(seconds: 8));
        }
      } catch (e) {
        print('⚠️ Failed to update driver status during logout: $e');
        // Continue with logout anyway
      }
      
      // Always attempt Firebase Auth signout
      await _auth.signOut().timeout(Duration(seconds: 10));
      print('✅ USER SIGNED OUT SUCCESSFULLY');
      _logger.i('User signed out successfully');
    } catch (e) {
      print('❌ Sign out error: $e');
      _logger.e('Sign out error: $e');
    }
  }

  static Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _logger.e('Password reset error: $e');
      return false;
    }
  }

  static Future<void> updateDriverOnlineStatus(bool isOnline) async {
    final user = currentUser;
    if (user != null) {
      await _firestore.collection('drivers').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<DriverModel?> getDriverData(String driverId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(driverId).get();
      if (doc.exists) {
        return DriverModel.fromJson({...doc.data()!, 'id': doc.id});
      }
    } catch (e) {
      _logger.e('Error fetching driver data: $e');
    }
    return null;
  }

  static String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? error;

  AuthResult._({required this.isSuccess, this.user, this.error});

  factory AuthResult.success(User user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.error(String error) {
    return AuthResult._(isSuccess: false, error: error);
  }
}
