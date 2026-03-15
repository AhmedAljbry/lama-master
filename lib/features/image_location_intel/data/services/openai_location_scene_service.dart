import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:lama/core/config/app_config.dart';

class AiSceneLocationInsight {
  final bool enabled;
  final bool success;
  final String status;
  final String? summary;
  final String? bestLocationGuess;
  final String? bestLocationQuery;
  final String? searchQuery;
  final double? confidenceScore;
  final List<String> visualClues;
  final String? sceneType;
  final String? country;
  final String? region;
  final String? cityOrArea;
  final String? caution;
  final String? reasoning;
  final String? error;

  const AiSceneLocationInsight({
    required this.enabled,
    required this.success,
    required this.status,
    required this.summary,
    required this.bestLocationGuess,
    required this.bestLocationQuery,
    required this.searchQuery,
    required this.confidenceScore,
    required this.visualClues,
    required this.sceneType,
    required this.country,
    required this.region,
    required this.cityOrArea,
    required this.caution,
    required this.reasoning,
    required this.error,
  });

  factory AiSceneLocationInsight.disabled() {
    return const AiSceneLocationInsight(
      enabled: false,
      success: false,
      status: 'disabled',
      summary: null,
      bestLocationGuess: null,
      bestLocationQuery: null,
      searchQuery: null,
      confidenceScore: null,
      visualClues: <String>[],
      sceneType: null,
      country: null,
      region: null,
      cityOrArea: null,
      caution: null,
      reasoning: null,
      error: null,
    );
  }

  factory AiSceneLocationInsight.failed(String error) {
    return AiSceneLocationInsight(
      enabled: true,
      success: false,
      status: 'failed',
      summary: null,
      bestLocationGuess: null,
      bestLocationQuery: null,
      searchQuery: null,
      confidenceScore: null,
      visualClues: const <String>[],
      sceneType: null,
      country: null,
      region: null,
      cityOrArea: null,
      caution: null,
      reasoning: null,
      error: error,
    );
  }
}

class OpenAiLocationSceneService {
  final AppConfig config;
  final http.Client _client;

  OpenAiLocationSceneService(
    this.config, {
    http.Client? client,
  }) : _client = client ?? http.Client();

  bool get isConfigured => (config.openAIApiKey ?? '').trim().isNotEmpty;

  Future<AiSceneLocationInsight> analyzeScene({
    required Uint8List imageBytes,
    String? ocrText,
    String? existingAddress,
    double? latitude,
    double? longitude,
    String? localLocationSummary,
  }) async {
    if (!isConfigured) {
      return AiSceneLocationInsight.disabled();
    }

    try {
      final imageDataUrl = _buildImageDataUrl(imageBytes);
      final response = await _client
          .post(
            Uri.parse('${config.openAIBaseUrl}/responses'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.openAIApiKey}',
            },
            body: jsonEncode(_buildRequestBody(
              imageDataUrl: imageDataUrl,
              ocrText: ocrText,
              existingAddress: existingAddress,
              latitude: latitude,
              longitude: longitude,
              localLocationSummary: localLocationSummary,
            )),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AiSceneLocationInsight.failed(
          'OpenAI HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rawText = _extractOutputText(decoded);
      if (rawText == null || rawText.trim().isEmpty) {
        return AiSceneLocationInsight.failed(
          'OpenAI response did not contain output text.',
        );
      }

      final payload = jsonDecode(rawText) as Map<String, dynamic>;
      return AiSceneLocationInsight(
        enabled: true,
        success: true,
        status: 'ready',
        summary: _cleanString(payload['scene_summary']),
        bestLocationGuess: _cleanString(payload['best_location_guess']),
        bestLocationQuery: _cleanString(payload['best_location_query']),
        searchQuery: _cleanString(payload['search_query']),
        confidenceScore: _coerceDouble(payload['confidence']),
        visualClues: _cleanStringList(payload['visual_clues']),
        sceneType: _cleanString(payload['scene_type']),
        country: _cleanString(payload['country']),
        region: _cleanString(payload['region']),
        cityOrArea: _cleanString(payload['city_or_area']),
        caution: _cleanString(payload['caution']),
        reasoning: _cleanString(payload['reasoning']),
        error: null,
      );
    } catch (error) {
      return AiSceneLocationInsight.failed(error.toString());
    }
  }

  Map<String, Object?> _buildRequestBody({
    required String imageDataUrl,
    required String? ocrText,
    required String? existingAddress,
    required double? latitude,
    required double? longitude,
    required String? localLocationSummary,
  }) {
    final prompt = StringBuffer()
      ..writeln(
        'You are a cautious geolocation analyst for photos. Infer likely location from architecture, vegetation, terrain, climate, roads, skyline, landmarks, signage, and visible scene context.',
      )
      ..writeln(
        'Use OCR text, address hints, and coordinates only as supporting evidence. Never invent certainty. If exact GPS exists, treat it as stronger than visual inference.',
      )
      ..writeln(
        'Return concise JSON only that matches the provided schema.',
      );

    if ((ocrText ?? '').trim().isNotEmpty) {
      prompt.writeln('OCR text: ${ocrText!.trim()}');
    }
    if ((existingAddress ?? '').trim().isNotEmpty) {
      prompt.writeln('Resolved address hint: ${existingAddress!.trim()}');
    }
    if (latitude != null && longitude != null) {
      prompt.writeln(
        'Known coordinates hint: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
      );
    }
    if ((localLocationSummary ?? '').trim().isNotEmpty) {
      prompt.writeln('Local analyzer summary: ${localLocationSummary!.trim()}');
    }

    return <String, Object?>{
      'model': config.openAIVisionModel,
      'input': <Object>[
        <String, Object?>{
          'role': 'user',
          'content': <Object>[
            <String, Object?>{
              'type': 'input_text',
              'text': prompt.toString(),
            },
            <String, Object?>{
              'type': 'input_image',
              'image_url': imageDataUrl,
              'detail': config.openAIVisionDetail,
            },
          ],
        },
      ],
      'max_output_tokens': 700,
      'text': <String, Object?>{
        'format': <String, Object?>{
          'type': 'json_schema',
          'name': 'scene_location_analysis',
          'strict': true,
          'schema': <String, Object?>{
            'type': 'object',
            'additionalProperties': false,
            'properties': <String, Object?>{
              'scene_summary': <String, Object?>{'type': 'string'},
              'scene_type': <String, Object?>{'type': 'string'},
              'best_location_guess': <String, Object?>{'type': 'string'},
              'best_location_query': <String, Object?>{'type': 'string'},
              'search_query': <String, Object?>{'type': 'string'},
              'country': <String, Object?>{'type': 'string'},
              'region': <String, Object?>{'type': 'string'},
              'city_or_area': <String, Object?>{'type': 'string'},
              'confidence': <String, Object?>{
                'type': 'number',
                'minimum': 0,
                'maximum': 1,
              },
              'visual_clues': <String, Object?>{
                'type': 'array',
                'items': <String, Object?>{'type': 'string'},
              },
              'reasoning': <String, Object?>{'type': 'string'},
              'caution': <String, Object?>{'type': 'string'},
            },
            'required': <String>[
              'scene_summary',
              'scene_type',
              'best_location_guess',
              'best_location_query',
              'search_query',
              'country',
              'region',
              'city_or_area',
              'confidence',
              'visual_clues',
              'reasoning',
              'caution',
            ],
          },
        },
      },
    };
  }

  String _buildImageDataUrl(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode the image for AI analysis.');
    }

    final longest = mathMax(decoded.width, decoded.height);
    final resized = longest > 1536
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 1536 : null,
            height: decoded.height > decoded.width ? 1536 : null,
          )
        : decoded;

    final jpg = img.encodeJpg(resized, quality: 84);
    final base64Data = base64Encode(jpg);
    return 'data:image/jpeg;base64,$base64Data';
  }

  String? _extractOutputText(Map<String, dynamic> payload) {
    final direct = payload['output_text'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct;
    }

    final output = payload['output'];
    if (output is! List) {
      return null;
    }

    final chunks = <String>[];
    for (final item in output) {
      if (item is! Map) {
        continue;
      }
      final content = item['content'];
      if (content is! List) {
        continue;
      }
      for (final part in content) {
        if (part is! Map) {
          continue;
        }
        final type = '${part['type']}';
        if ((type == 'output_text' || type == 'text') &&
            part['text'] is String &&
            (part['text'] as String).trim().isNotEmpty) {
          chunks.add((part['text'] as String).trim());
        }
      }
    }

    if (chunks.isEmpty) {
      return null;
    }
    return chunks.join('\n');
  }

  String? _cleanString(Object? value) {
    final text = '$value'.trim();
    if (text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }

  List<String> _cleanStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((entry) => _cleanString(entry))
        .whereType<String>()
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  double? _coerceDouble(Object? value) {
    if (value is num) {
      return value.toDouble().clamp(0.0, 1.0);
    }
    return double.tryParse('$value')?.clamp(0.0, 1.0);
  }
}

int mathMax(int a, int b) => a > b ? a : b;
