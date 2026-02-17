import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressSnapshot {
  final String id;
  final DateTime weekStart;
  final int loadScore;
  final int streakDays;
  final int mindfulnessMinutes;
  final int calories;

  const ProgressSnapshot({
    required this.id,
    required this.weekStart,
    required this.loadScore,
    required this.streakDays,
    required this.mindfulnessMinutes,
    required this.calories,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekStart': Timestamp.fromDate(weekStart),
      'loadScore': loadScore,
      'streakDays': streakDays,
      'mindfulnessMinutes': mindfulnessMinutes,
      'calories': calories,
    };
  }

  factory ProgressSnapshot.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ProgressSnapshot(
      id: doc.id,
      weekStart: (data['weekStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      loadScore: data['loadScore'] as int? ?? 0,
      streakDays: data['streakDays'] as int? ?? 0,
      mindfulnessMinutes: data['mindfulnessMinutes'] as int? ?? 0,
      calories: data['calories'] as int? ?? 0,
    );
  }
}
