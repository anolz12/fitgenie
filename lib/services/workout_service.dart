import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/workout.dart';

class WorkoutService {
  WorkoutService._();

  static final WorkoutService instance = WorkoutService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('workouts');
  }

  Stream<List<Workout>> streamWorkouts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return _collection(user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Workout.fromDoc).toList());
  }

  Future<void> seedIfEmpty() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _collection(user.uid);
    final snap = await ref.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final now = DateTime.now();
    final samples = [
      Workout(
        id: '',
        title: 'Strength Training',
        focus: 'High intensity',
        durationMinutes: 45,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Cardio Blast',
        focus: 'Endurance',
        durationMinutes: 30,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Mobility Flow',
        focus: 'Recovery',
        durationMinutes: 20,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'HIIT Burner',
        focus: 'Intervals',
        durationMinutes: 25,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Upper Body Sculpt',
        focus: 'Strength',
        durationMinutes: 35,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Core & Balance',
        focus: 'Core',
        durationMinutes: 20,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Run Prep',
        focus: 'Performance',
        durationMinutes: 28,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Low Impact Cardio',
        focus: 'Cardio',
        durationMinutes: 24,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'No-Equipment HIIT',
        focus: 'No-equipment',
        durationMinutes: 18,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Band Strength Circuit',
        focus: 'Resistance band',
        durationMinutes: 22,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Dumbbell Power',
        focus: 'Dumbbells',
        durationMinutes: 32,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Mobility Reset',
        focus: 'Mobility',
        durationMinutes: 16,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Core Ignite',
        focus: 'Core',
        durationMinutes: 15,
        createdAt: now,
        completedAt: null,
      ),
    ];
    for (final w in samples) {
      await ref.add(w.toMap());
    }
  }

  Future<void> ensureLibrary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _collection(user.uid);
    final snap = await ref.get();
    final existing = snap.docs
        .map((d) => (d.data()['focus'] as String? ?? '').toLowerCase())
        .toSet();
    final now = DateTime.now();
    final candidates = [
      Workout(
        id: '',
        title: 'Cardio Blast',
        focus: 'Cardio',
        durationMinutes: 30,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Core Ignite',
        focus: 'Core',
        durationMinutes: 15,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'No-Equipment HIIT',
        focus: 'No-equipment',
        durationMinutes: 18,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Band Strength Circuit',
        focus: 'Resistance band',
        durationMinutes: 22,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Dumbbell Power',
        focus: 'Dumbbells',
        durationMinutes: 32,
        createdAt: now,
        completedAt: null,
      ),
      Workout(
        id: '',
        title: 'Mobility Reset',
        focus: 'Mobility',
        durationMinutes: 16,
        createdAt: now,
        completedAt: null,
      ),
    ];
    for (final w in candidates) {
      final key = w.focus.toLowerCase();
      if (existing.any((e) => e.contains(key.split(' ').first))) continue;
      await ref.add(w.toMap());
    }
  }

  Future<void> addWorkout(Workout workout) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _collection(user.uid).add(workout.toMap());
  }

  Future<void> updateWorkout(Workout workout) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _collection(
      user.uid,
    ).doc(workout.id).set(workout.toMap(), SetOptions(merge: true));
  }
}
