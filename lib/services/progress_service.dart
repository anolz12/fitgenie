import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/progress_snapshot.dart';

class ProgressService {
  ProgressService._();

  static final ProgressService instance = ProgressService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('progress');
  }

  Stream<List<ProgressSnapshot>> streamSnapshots() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return _collection(user.uid)
        .orderBy('weekStart', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ProgressSnapshot.fromDoc).toList());
  }

  Future<void> seedIfEmpty() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _collection(user.uid);
    final snap = await ref.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final now = DateTime.now();
    await ref.add(
      ProgressSnapshot(
        id: '',
        weekStart: now.subtract(const Duration(days: 6)),
        loadScore: 68,
        streakDays: 5,
        mindfulnessMinutes: 42,
        calories: 1840,
      ).toMap(),
    );
  }

  Future<void> addSnapshot(ProgressSnapshot snapshot) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _collection(user.uid).add(snapshot.toMap());
  }

  Future<void> updateSnapshot(ProgressSnapshot snapshot) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _collection(user.uid).doc(snapshot.id).set(snapshot.toMap(), SetOptions(merge: true));
  }
}
