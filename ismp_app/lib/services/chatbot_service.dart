import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatbotService {
  static const String _backendUrl =
      'https://iotacluster-rag-narok-backend.hf.space';

  /// Sends a message to the RAGnarok chatbot and returns the response.
  static Future<String> sendMessage({
    required String message,
    String? sessionId,
    List<Map<String, String>>? chatHistory,
  }) async {
    try {
      final uri = Uri.parse('$_backendUrl/api/chat');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
          if (chatHistory != null) 'chat_history': chatHistory,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The API may return different field names; try common ones.
        return data['response'] ??
            data['answer'] ??
            data['message'] ??
            data.toString();
      } else {
        debugPrint('Chat API error: ${response.statusCode} ${response.body}');
        return 'Sorry, I could not get a response right now. (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('Chat API exception: $e');
      return 'Unable to reach the chatbot server. Please check your connection.';
    }
  }

  /// Quick health check.
  static Future<bool> isHealthy() async {
    try {
      final uri = Uri.parse('$_backendUrl/health');
      final response =
          await http.get(uri, headers: {'Content-Type': 'application/json'});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
