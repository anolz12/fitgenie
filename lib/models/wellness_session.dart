import 'package:flutter/material.dart';

class WellnessSession {
  final String title;
  final String duration;
  final String description;
  final Color accent;
  final String? id;

  const WellnessSession({
    this.id,
    required this.title,
    required this.duration,
    required this.description,
    required this.accent,
  });

  static List<WellnessSession> samples() {
    return const [
      WellnessSession(
        id: null,
        title: '4-7-8 Breathing',
        duration: '6 min',
        description: 'Slow your heart rate and prep for sleep.',
        accent: Color(0xFF4CC9F0),
      ),
      WellnessSession(
        id: null,
        title: 'Evening Yoga Reset',
        duration: '12 min',
        description: 'Hip openers, spinal flow, and deep stretch.',
        accent: Color(0xFFFFD166),
      ),
      WellnessSession(
        id: null,
        title: 'Mindset Coach',
        duration: '5 min',
        description: 'Guided mindset reset with breath, focus, and confidence.',
        accent: Color(0xFF00E5A0),
      ),
      WellnessSession(
        id: null,
        title: 'Morning Breathwork',
        duration: '5 min',
        description: 'Energize with box breathing and posture cues.',
        accent: Color(0xFF2C7DD8),
      ),
      WellnessSession(
        id: null,
        title: 'Body Scan',
        duration: '8 min',
        description: 'Release tension head-to-toe and reset focus.',
        accent: Color(0xFF7C5CFF),
      ),
      WellnessSession(
        id: null,
        title: 'Neck + Shoulder Relief',
        duration: '7 min',
        description: 'Guided stretches for desk and device fatigue.',
        accent: Color(0xFF22C6A3),
      ),
    ];
  }

  factory WellnessSession.fromMap(Map<String, dynamic> map, String id) {
    return WellnessSession(
      id: id,
      title: map['title'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
      description: map['description'] as String? ?? '',
      accent: _parseColor(
        map['accent'] as int? ?? const Color(0xFF4CC9F0).value,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'duration': duration,
      'description': description,
      'accent': accent.value,
    };
  }

  static Color _parseColor(int value) => Color(value);
}
