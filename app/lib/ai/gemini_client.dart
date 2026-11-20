import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Calls the Gemini REST API directly from the phone with the student's own
/// key (bring-your-own-key). No server, no shared quota.
///
/// Model IDs change often, so the model is configuration, not code.
class GeminiClient {
  GeminiClient({
    required this.apiKey,
    this.model = defaultModel,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  /// Free-tier Flash-Lite model (GA May 2026). Override in Settings if Google
  /// renames or retires it.
  static const defaultModel = 'gemini-3.1-flash-lite';
  static const _base = 'https://generativelanguage.googleapis.com/v1beta';

  final String apiKey;
  final String model;
  final http.Client _http;

  Map<String, String> get _headers => {
        'x-goog-api-key': apiKey,
        'content-type': 'application/json',
      };

  /// Cheap call used by the key screen to confirm the key works.
  Future<KeyCheck> checkKey() async {
    try {
      final res = await _http.get(Uri.parse('$_base/models?pageSize=1'), headers: _headers);
      if (res.statusCode == 200) return KeyCheck.ok;
      if (res.statusCode == 400 || res.statusCode == 403) return KeyCheck.invalid;
      if (res.statusCode == 429) return KeyCheck.quotaExhausted;
      return KeyCheck.networkError;
    } catch (_) {
      return KeyCheck.networkError;
    }
  }

  /// Sends text and optional images, and asks for JSON matching [schema].
  Future<Map<String, Object?>> generateJson({
    required String prompt,
    required Map<String, Object?> schema,
    List<ImagePart> images = const [],
  }) async {
    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
            for (final img in images)
              {
                'inline_data': {'mime_type': img.mimeType, 'data': base64Encode(img.bytes)},
              },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
        'responseSchema': schema,
      },
    };
    final res = await _http.post(
      Uri.parse('$_base/models/$model:generateContent'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 429) throw const GeminiException.quota();
    if (res.statusCode != 200) {
      throw GeminiException('Gemini returned ${res.statusCode}: ${res.body}');
    }
    final decoded = jsonDecode(res.body) as Map<String, Object?>;
    final text = _firstText(decoded);
    if (text == null) throw const GeminiException('Gemini returned no content.');
    return jsonDecode(text) as Map<String, Object?>;
  }

  static String? _firstText(Map<String, Object?> response) {
    final candidates = response['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;
    final content = (candidates.first as Map)['content'] as Map?;
    final parts = content?['parts'] as List?;
    if (parts == null) return null;
    for (final p in parts) {
      final t = (p as Map)['text'];
      if (t is String) return t;
    }
    return null;
  }
}

enum KeyCheck { ok, invalid, quotaExhausted, networkError }

class ImagePart {
  const ImagePart(this.bytes, {this.mimeType = 'image/jpeg'});
  final Uint8List bytes;
  final String mimeType;
}

class GeminiException implements Exception {
  const GeminiException(this.message) : isQuota = false;
  const GeminiException.quota()
      : message = 'Today’s free Gemini limit is used up. It resets at midnight Pacific time.',
        isQuota = true;
  final String message;
  final bool isQuota;
  @override
  String toString() => message;
}
