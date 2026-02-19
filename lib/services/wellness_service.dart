import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/wellness_session.dart';

class WellnessService {
  WellnessService._();
  static final WellnessService instance = WellnessService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('wellness');
  }

  Stream<List<WellnessSession>> streamSessions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return _collection(user.uid).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => WellnessSession.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  Future<void> seedIfEmpty() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _collection(user.uid);
    final snap = await ref.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final samples = WellnessSession.samples();
    for (final s in samples) {
      await ref.add(s.toMap());
    }
  }

  Future<void> addSession(WellnessSession session) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _collection(user.uid).add(session.toMap());
  }

  Future<bool> addSessionIfNotDuplicate(WellnessSession session) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final ref = _collection(user.uid);
    final snap = await ref
        .where('title', isEqualTo: session.title)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return false;
    await ref.add(session.toMap());
    return true;
  }
}
