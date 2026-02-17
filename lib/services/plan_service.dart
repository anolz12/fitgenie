import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/workout_plan.dart';

/// Persists AI workout plan preferences and generated plan to Firestore.
/// Path: users/{uid}/meta/ai_plan
/// Backend (e.g. Cloud Functions) can read this and push adaptive updates.
class PlanService {
  PlanService._();

  static final PlanService instance = PlanService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid).collection('meta').doc('ai_plan');

  Stream<SavedPlanData?> stream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);
    return _doc(user.uid).snapshots().map((snap) {
      final data = snap.data();
      return data != null ? SavedPlanData.fromMap(data) : null;
    });
  }

  Future<void> savePreferences({
    required String goal,
    required String equipment,
    required String timePerSession,
    required String fitnessLevel,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _doc(user.uid).set({
      'goal': goal,
      'equipment': equipment,
      'timePerSession': timePerSession,
      'fitnessLevel': fitnessLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveGeneratedPlan({
    required String title,
    required String nextSync,
    required List<WorkoutPlanItem> items,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _doc(user.uid).set({
      'planTitle': title,
      'nextSync': nextSync,
      'planItems': items.map((e) => {'label': e.label, 'detail': e.detail}).toList(),
      'planUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class SavedPlanData {
  final String goal;
  final String equipment;
  final String timePerSession;
  final String fitnessLevel;
  final String? planTitle;
  final String? nextSync;
  final List<WorkoutPlanItem> planItems;

  const SavedPlanData({
    this.goal = 'Build muscle',
    this.equipment = 'Dumbbells',
    this.timePerSession = '45 min',
    this.fitnessLevel = 'Intermediate',
    this.planTitle,
    this.nextSync,
    this.planItems = const [],
  });

  factory SavedPlanData.fromMap(Map<String, dynamic> map) {
    final itemsRaw = map['planItems'] as List<dynamic>? ?? [];
    final planItems = itemsRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return WorkoutPlanItem(
        label: m['label'] as String? ?? '',
        detail: m['detail'] as String? ?? '',
      );
    }).toList();
    return SavedPlanData(
      goal: map['goal'] as String? ?? 'Build muscle',
      equipment: map['equipment'] as String? ?? 'Dumbbells',
      timePerSession: map['timePerSession'] as String? ?? '45 min',
      fitnessLevel: map['fitnessLevel'] as String? ?? 'Intermediate',
      planTitle: map['planTitle'] as String?,
      nextSync: map['nextSync'] as String?,
      planItems: planItems,
    );
  }

  WorkoutPlan? toWorkoutPlan() {
    if (planTitle == null || planTitle!.isEmpty) return null;
    return WorkoutPlan(
      title: planTitle!,
      nextSync: nextSync ?? 'Next sync: Sun 7:00 PM',
      items: planItems,
    );
  }
}
