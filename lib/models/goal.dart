import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id;
  final String title;
  final double progress;
  final String status;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.title,
    required this.progress,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'progress': progress,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Goal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Goal(
      id: doc.id,
      title: data['title'] as String? ?? '',
      progress: (data['progress'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
