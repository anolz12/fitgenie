import 'package:cloud_firestore/cloud_firestore.dart';

class Workout {
  final String id;
  final String title;
  final String focus;
  final int durationMinutes;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Workout({
    required this.id,
    required this.title,
    required this.focus,
    required this.durationMinutes,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'focus': focus,
      'durationMinutes': durationMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt == null ? null : Timestamp.fromDate(completedAt!),
    };
  }

  factory Workout.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Workout(
      id: doc.id,
      title: data['title'] as String? ?? '',
      focus: data['focus'] as String? ?? '',
      durationMinutes: data['durationMinutes'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}
