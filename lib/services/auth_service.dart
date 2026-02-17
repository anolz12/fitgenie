import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(displayName);
    final userId = credential.user!.uid;
    final userRef = _firestore.collection('users').doc(userId);
    await userRef.set({
      'email': email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'goals': [],
    });

    final batch = _firestore.batch();
    final goalRef = userRef.collection('goals').doc();
    final progressRef = userRef.collection('progress').doc();
    final workoutRef = userRef.collection('workouts').doc();

    batch.set(goalRef, {
      'title': 'Consistency 4x/week',
      'progress': 0.25,
      'status': 'Getting started',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(progressRef, {
      'weekStart': FieldValue.serverTimestamp(),
      'loadScore': 52,
      'streakDays': 1,
      'mindfulnessMinutes': 10,
      'calories': 520,
    });

    batch.set(workoutRef, {
      'title': 'Starter Strength',
      'focus': 'Full body',
      'durationMinutes': 25,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': null,
    });

    await batch.commit();
  }

  Future<void> signOut() => _auth.signOut();
}
