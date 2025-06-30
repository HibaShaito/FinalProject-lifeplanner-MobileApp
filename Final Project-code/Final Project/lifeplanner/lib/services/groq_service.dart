import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class GroqService {
  final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
  final String apiKey;

  GroqService({required this.apiKey});

  Future<String> sendMessage(String userMessage) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      "model": "meta-llama/llama-4-scout-17b-16e-instruct",
      "messages": [
        {"role": "user", "content": userMessage},
      ],
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      debugPrint('Groq ERROR ${response.statusCode}: ${response.body}');
      throw Exception('Groq HTTP ${response.statusCode}: ${response.body}');
    }

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('Groq API failed: ${response.body}');
    }
  }
}
