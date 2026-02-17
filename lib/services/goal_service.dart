import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/goal.dart';

class GoalService {
  GoalService._();

  static final GoalService instance = GoalService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('goals');
  }

  Stream<List<Goal>> streamGoals() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return _collection(user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Goal.fromDoc).toList());
  }

  Future<void> seedIfEmpty() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _collection(user.uid);
    final snap = await ref.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final now = DateTime.now();
    final samples = [
      Goal(
        id: '',
        title: 'Run 5K under 28 min',
        progress: 0.45,
        status: 'On pace',
        createdAt: now,
      ),
      Goal(
        id: '',
        title: 'Consistency 4x/week',
        progress: 0.7,
        status: 'Great',
        createdAt: now,
      ),
    ];
    for (final g in samples) {
      await ref.add(g.toMap());
    }
  }

  Future<void> addGoal(Goal goal) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _collection(user.uid).add(goal.toMap());
  }

  Future<void> updateGoal(Goal goal) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _collection(user.uid).doc(goal.id).set(goal.toMap(), SetOptions(merge: true));
  }
}
