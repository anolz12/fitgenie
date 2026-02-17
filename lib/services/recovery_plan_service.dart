import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Backend for Smart Recovery, Smart Notifications prefs, and plan highlights.
/// Firestore: users/{uid}/meta/recovery_plan
/// Your backend (e.g. Cloud Functions) can write restDayAlert, overtrainingStatus,
/// nextRestDay, etc. This service reads them and the UI updates in real time.
class RecoveryPlanService {
  RecoveryPlanService._();

  static final RecoveryPlanService instance = RecoveryPlanService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid).collection('meta').doc('recovery_plan');

  Stream<RecoveryPlanData> stream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(RecoveryPlanData.defaults());
    return _doc(user.uid).snapshots().map((snap) {
      final data = snap.data();
      return data != null ? RecoveryPlanData.fromMap(data) : RecoveryPlanData.defaults();
    });
  }

  Future<void> setRecovery({
    String? restDayAlert,
    String? overtrainingStatus,
    DateTime? nextRestDay,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _doc(user.uid).set({
      if (restDayAlert != null) 'restDayAlert': restDayAlert,
      if (overtrainingStatus != null) 'overtrainingStatus': overtrainingStatus,
      if (nextRestDay != null) 'nextRestDay': Timestamp.fromDate(nextRestDay),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setNotificationPrefs({
    bool? aiMotivation,
    bool? workoutReminders,
    bool? streakProtection,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _doc(user.uid).set({
      if (aiMotivation != null) 'aiMotivation': aiMotivation,
      if (workoutReminders != null) 'workoutReminders': workoutReminders,
      if (streakProtection != null) 'streakProtection': streakProtection,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setPlanHighlights({
    String? adaptiveDifficulty,
    String? homeGymWorkouts,
    String? restDayRecommendations,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _doc(user.uid).set({
      if (adaptiveDifficulty != null) 'adaptiveDifficulty': adaptiveDifficulty,
      if (homeGymWorkouts != null) 'homeGymWorkouts': homeGymWorkouts,
      if (restDayRecommendations != null) 'restDayRecommendations': restDayRecommendations,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class RecoveryPlanData {
  final String restDayAlert;
  final String overtrainingStatus;
  final bool aiMotivation;
  final bool workoutReminders;
  final bool streakProtection;
  final String adaptiveDifficulty;
  final String homeGymWorkouts;
  final String restDayRecommendations;

  const RecoveryPlanData({
    this.restDayAlert = 'Tomorrow suggested',
    this.overtrainingStatus = 'All clear',
    this.aiMotivation = true,
    this.workoutReminders = true,
    this.streakProtection = true,
    this.adaptiveDifficulty = 'Auto-adjusts weekly',
    this.homeGymWorkouts = 'Both supported',
    this.restDayRecommendations = 'Built into plan',
  });

  factory RecoveryPlanData.defaults() => const RecoveryPlanData();

  factory RecoveryPlanData.fromMap(Map<String, dynamic> map) {
    String restDay = map['restDayAlert'] as String? ?? 'Tomorrow suggested';
    String overtraining = map['overtrainingStatus'] as String? ?? 'All clear';
    bool aiMotivation = map['aiMotivation'] as bool? ?? true;
    bool workoutReminders = map['workoutReminders'] as bool? ?? true;
    bool streakProtection = map['streakProtection'] as bool? ?? true;
    String adaptive = map['adaptiveDifficulty'] as String? ?? 'Auto-adjusts weekly';
    String homeGym = map['homeGymWorkouts'] as String? ?? 'Both supported';
    String restRec = map['restDayRecommendations'] as String? ?? 'Built into plan';
    return RecoveryPlanData(
      restDayAlert: restDay,
      overtrainingStatus: overtraining,
      aiMotivation: aiMotivation,
      workoutReminders: workoutReminders,
      streakProtection: streakProtection,
      adaptiveDifficulty: adaptive,
      homeGymWorkouts: homeGym,
      restDayRecommendations: restRec,
    );
  }
}
