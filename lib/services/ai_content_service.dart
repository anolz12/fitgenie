import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/wellness_session.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';

class AIContentService {
  AIContentService._();
  static final AIContentService instance = AIContentService._();

  final http.Client _client = http.Client();

  static const String _chatEndpoint = String.fromEnvironment(
    'FITGENIE_CHAT_ENDPOINT',
    defaultValue: '',
  );

  Uri? _endpointFor(String path) {
    if (_chatEndpoint.isEmpty) return null;
    final base = Uri.parse(_chatEndpoint);
    return base.replace(path: path.startsWith('/') ? path : '/$path');
  }

  Future<WorkoutPlan?> generateWorkoutPlan({
    required String goal,
    required String equipment,
    required String timePerSession,
    required String fitnessLevel,
  }) async {
    final uri = _endpointFor('/generate-workouts');
    if (uri == null) return null;
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'goal': goal,
        'equipment': equipment,
        'timePerSession': timePerSession,
        'fitnessLevel': fitnessLevel,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final itemsRaw = (data['workouts'] as List<dynamic>? ?? []);
    final items = itemsRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return WorkoutPlanItem(
        label: (m['focus'] as String? ?? 'Session'),
        detail:
            '${m['title'] as String? ?? 'Workout'} · ${(m['durationMinutes'] as num? ?? 30).round()} min',
      );
    }).toList();
    if (items.isEmpty) return null;
    return WorkoutPlan(
      title: 'AI Plan · $fitnessLevel',
      nextSync: 'Next sync: Sun 7:00 PM',
      items: items.take(6).toList(),
    );
  }

  Future<List<Workout>> generateWorkouts({
    required String goal,
    required String equipment,
    required String timePerSession,
    required String fitnessLevel,
  }) async {
    final uri = _endpointFor('/generate-workouts');
    if (uri == null) return [];
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'goal': goal,
        'equipment': equipment,
        'timePerSession': timePerSession,
        'fitnessLevel': fitnessLevel,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final workouts = (data['workouts'] as List<dynamic>? ?? []);
    final now = DateTime.now();
    return workouts.map((e) {
      final m = e as Map<String, dynamic>;
      return Workout(
        id: '',
        title: (m['title'] as String? ?? 'AI Workout').trim(),
        focus: (m['focus'] as String? ?? 'General').trim(),
        durationMinutes: (m['durationMinutes'] as num? ?? 30).round(),
        createdAt: now,
        completedAt: null,
      );
    }).toList();
  }

  Future<List<WellnessSession>> generateWellness({
    String goal = 'Stress relief',
  }) async {
    final uri = _endpointFor('/generate-wellness');
    if (uri == null) return [];
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'goal': goal}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final sessions = (data['sessions'] as List<dynamic>? ?? []);
    return sessions.map((e) {
      final m = e as Map<String, dynamic>;
      return WellnessSession(
        title: (m['title'] as String? ?? 'AI Session').trim(),
        duration: (m['duration'] as String? ?? '5 min').trim(),
        description: (m['description'] as String? ?? 'Guided wellness.').trim(),
        accent: _colorForCategory((m['category'] as String? ?? 'Meditation')),
      );
    }).toList();
  }

  Color _colorForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('breath')) return const Color(0xFF4CC9F0);
    if (c.contains('sleep')) return const Color(0xFF7C5CFF);
    if (c.contains('mobility')) return const Color(0xFF22C6A3);
    return const Color(0xFFFFD166);
  }
}
