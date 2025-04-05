import 'dart:io';
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drone_user_app/exceptions/auth_exceptions.dart';
import 'package:drone_user_app/features/auth/models/user_model.dart';
import 'package:drone_user_app/utils/helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _authSubscription;

  AuthBloc() : super(AuthInitial()) {
    on<InitializeApp>(_initializeApp);
    on<RegisterEvent>(_registerNewUser);
    on<LogoutEvent>(_signOut);
    on<LoginEvent>(_login);
    on<NavigateToWrapper>(_navigateToWrapper);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Trigger initialization when bloc is created
    add(InitializeApp());

    // Set up auth state changes listener
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        add(AuthStateChanged(user));
      } else {
        add(AuthStateChanged(null));
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // Handle auth state changes from Firebase
  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      emit(Authenticated(event.user!));
    } else {
      emit(Unauthenticated());
    }
  }

  // Handle navigation event
  void _navigateToWrapper(NavigateToWrapper event, Emitter<AuthState> emit) {
    emit(NavigationRequested());
  }

  // Initialize app authentication state
  Future<void> _initializeApp(
    InitializeApp event,
    Emitter<AuthState> emit,
  ) async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // Check if user data exists in Firestore
        UserModel? userData = await getUserData(currentUser.uid);

        if (userData != null) {
          emit(Authenticated(currentUser));
        } else {
          // If user auth exists but no data in Firestore, create it
          await _createUserData(currentUser, null, null, null);
          emit(Authenticated(currentUser));
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      print('Error initializing app: $e');
      emit(Unauthenticated());
    }
  }

  // Register new user
  Future<void> _registerNewUser(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: event.email,
            password: event.password,
          );

      User? user = userCredential.user;

      if (user != null) {
        // Create user data in Firestore
        bool success = await _createUserData(
          user,
          event.name,
          event.email,
          event.role,
        );

        if (success) {
          // Force a token refresh
          await user.getIdToken(true);

          // Wait for Firestore write to propagate
          await Future.delayed(const Duration(milliseconds: 500));

          // Preload user data to cache
          await getUserData(user.uid);

          // Emit authenticated state
          emit(Authenticated(user));
        } else {
          emit(AuthError('Failed to create user data'));
        }
      }
    } on FirebaseAuthException catch (error) {
      print(
        'Error registering user: ${mapFirebaseAuthExceptionCodes(errorCode: error.code)}',
      );
      emit(AuthError(mapFirebaseAuthExceptionCodes(errorCode: error.code)));
    } on SocketException catch (e) {
      print("Network Error : $e");
      emit(AuthError("No internet connection. Please check your network."));
    } catch (error) {
      print('Unexpected error registering user: $error');
      emit(AuthError('An unexpected error occurred. Please try again.'));
    }
  }

  // Helper method to create user data in Firestore
  Future<bool> _createUserData(
    User user,
    String? name,
    String? email,
    String? role,
  ) async {
    try {
      UserModel newUser = UserModel(
        uid: user.uid,
        name: name ?? user.displayName ?? 'User',
        email: email ?? user.email ?? '',
        role: role ?? 'Customer',
        imageUrl: user.photoURL ?? '',
      );

      // Use transaction for better reliability
      await _firestore.runTransaction((transaction) async {
        DocumentReference userDoc = _firestore
            .collection('users')
            .doc(user.uid);
        transaction.set(userDoc, newUser.toJson());
      });

      return true;
    } catch (e) {
      print('Error creating user data: $e');
      return false;
    }
  }

  // Login user
  Future<void> _login(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      // Preload user data to cache
      UserModel? userData = await getUserData(userCredential.user!.uid);

      if (userData != null) {
        emit(Authenticated(userCredential.user!));
      } else {
        // If user auth exists but no data in Firestore, create it
        await _createUserData(userCredential.user!, null, event.email, null);
        emit(Authenticated(userCredential.user!));
      }
    } on FirebaseAuthException catch (error) {
      print(
        'Error logging in: ${mapFirebaseAuthExceptionCodes(errorCode: error.code)}',
      );
      emit(AuthError(mapFirebaseAuthExceptionCodes(errorCode: error.code)));
    } on SocketException catch (e) {
      print("Network Error : $e");
      emit(AuthError("No internet connection. Please check your network."));
    } catch (error) {
      print('Unexpected error logging in: $error');
      emit(AuthError('An unexpected error occurred. Please try again.'));
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get user data with cacheing
  Future<UserModel?> getUserData(String uid) async {
    try {
      // Try to get data with caching enabled
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(GetOptions(source: Source.serverAndCache));

      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }

      // If no data in cache or server, try server-only as fallback
      doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(GetOptions(source: Source.server));

      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user data in Firestore
  Future<bool> updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toJson());

      // If Firebase Auth user exists, update profile
      User? currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == user.uid) {
        await currentUser.updateDisplayName(user.name);

        // Only update photo URL if it exists
        if (user.imageUrl != null && user.imageUrl!.isNotEmpty) {
          await currentUser.updatePhotoURL(user.imageUrl);
        }
      }

      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }

  // Sign Out
  Future<void> _signOut(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await _auth.signOut();
      emit(Unauthenticated());
    } on FirebaseAuthException catch (error) {
      print(
        'Error signing out: ${mapFirebaseAuthExceptionCodes(errorCode: error.code)}',
      );
      throw Exception(mapFirebaseAuthExceptionCodes(errorCode: error.code));
    } catch (error) {
      print('Error signing out: $error');
    }
  }
}
