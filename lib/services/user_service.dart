import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  UserService._();

  static final UserService instance = UserService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<bool> isOnboardingComplete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final snapshot = await _doc(user.uid).get();
    return snapshot.data()?['onboardingComplete'] == true;
  }

  Future<void> completeOnboarding({
    required String focus,
    required String goal,
    required int sessionsPerWeek,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _doc(user.uid).set({
      'focus': focus,
      'primaryGoal': goal,
      'sessionsPerWeek': sessionsPerWeek,
      'onboardingComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
