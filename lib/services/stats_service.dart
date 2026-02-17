import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid).collection('meta').doc('stats');

  Future<Map<String, dynamic>?> fetch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final snap = await _doc(user.uid).get();
    return snap.data();
  }

  Stream<Map<String, dynamic>?> stream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return _doc(user.uid).snapshots().map((s) => s.data());
  }

  Future<void> setStats({int? steps, int? calories, int? minutes}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _doc(user.uid);
    await ref.set({
      if (steps != null) 'steps': steps,
      if (calories != null) 'calories': calories,
      if (minutes != null) 'activeMinutes': minutes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> seedIfMissing() async {
    // Intentionally no-op: avoid demo data. Stats will appear only after a real sync.
  }

  Future<void> update({
    int stepsDelta = 0,
    int caloriesDelta = 0,
    int minutesDelta = 0,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _doc(user.uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final steps = (data['steps'] ?? 0) as int;
      final calories = (data['calories'] ?? 0) as int;
      final minutes = (data['activeMinutes'] ?? 0) as int;
      tx.set(ref, {
        'steps': steps + stepsDelta,
        'calories': calories + caloriesDelta,
        'activeMinutes': minutes + minutesDelta,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
