import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ChatbotService {
  ChatbotService._();

  static final ChatbotService instance = ChatbotService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _client = http.Client();

  /// Configure at runtime:
  /// flutter run --dart-define=FITGENIE_CHAT_ENDPOINT=https://us-central1-<project-id>.cloudfunctions.net/fitgenieChat
  static const String _apiEndpoint = String.fromEnvironment(
    'FITGENIE_CHAT_ENDPOINT',
    defaultValue: '',
  );

  Future<String> sendMessage(String message) async {
    await _storeMessage(message, isUser: true);

    final history = await _fetchRecentHistory(limit: 8);

    if (_apiEndpoint.isNotEmpty) {
      try {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        final response = await _client.post(
          Uri.parse(_apiEndpoint),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'message': message, 'history': history}),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final reply = data['reply'] as String? ?? _fallbackReply(message);
          await _storeMessage(reply, isUser: false);
          return reply;
        }
      } catch (_) {
        // Fall back to local response below.
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    final reply = _fallbackReply(message);
    await _storeMessage(reply, isUser: false);
    return reply;
  }

  Future<void> _storeMessage(String text, {required bool isUser}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('chat').add({
      'text': text,
      'isUser': isUser,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, String>>> _fetchRecentHistory({int limit = 8}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final snap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chat')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    final messages = snap.docs.reversed.map((d) {
      final data = d.data();
      final isUser = data['isUser'] == true;
      final text = data['text'] as String? ?? '';
      return {'role': isUser ? 'user' : 'assistant', 'content': text};
    }).toList();
    return messages;
  }

  String _fallbackReply(String message) {
    if (message.toLowerCase().contains('knee')) {
      return 'Swap lunges for step-ups and reduce squat depth. I will adjust tempo and warm-up too.';
    }
    if (message.toLowerCase().contains('motivation')) {
      return 'You are on track. I can shorten today\'s session to keep momentum.';
    }
    return 'Got it. I can tailor a 25-minute plan with strength and recovery. Want a focus on upper or lower body?';
  }
}
