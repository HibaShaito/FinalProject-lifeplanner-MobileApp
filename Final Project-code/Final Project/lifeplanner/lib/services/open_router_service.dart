import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenRouterService {
  final String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  final String apiKey;

  OpenRouterService({required this.apiKey});

  Future<String> sendMessage(String userMessage) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'meta-llama/llama-3.3-8b-instruct:free',
        'messages': [
          {
            'role': 'system',
            'content': 'You are an assistant for a Life Planner app.',
          },
          {'role': 'user', 'content': userMessage},
        ],
      }),
    );

    // Always log the raw body if it's not 200
    if (response.statusCode != 200) {
      debugPrint('OpenRouter ERROR ${response.statusCode}: ${response.body}');
      throw Exception(
        'OpenRouter HTTP ${response.statusCode}: ${response.body}',
      );
    }

    // Try to parse JSON
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to decode JSON from OpenRouter: ${response.body}');
      throw Exception('Invalid JSON from OpenRouter: $e');
    }

    // Safely extract the reply
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      debugPrint('No choices in response: $body');
      throw Exception('No response choices returned by OpenRouter');
    }

    final first = choices[0] as Map<String, dynamic>?;
    final message = first?['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;

    if (content == null) {
      debugPrint('Malformed choice[0]: $first');
      throw Exception('Malformed response from OpenRouter: missing content');
    }

    return content;
  }
}
