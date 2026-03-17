import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:lama/core/config/app_config.dart';
import 'package:lama/features/image_location_intel/data/services/openai_location_scene_service.dart';
import 'package:native_exif/native_exif.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lama/core/ui/AppL10n.dart';
import '../../../../core/routing/app_routes.dart';
import 'package:go_router/go_router.dart';

enum AnalyzeMode {
  existingImage,
  newCaptureWithGuaranteedGps,
}

class LocationClue {
  final String title;
  final String value;
  final String detail;
  final bool isStrong;

  const LocationClue({
    required this.title,
    required this.value,
    required this.detail,
    required this.isStrong,
  });
}

class AnalysisResult {
  final String imagePath;
  final AnalyzeMode mode;
  final double? latitude;
  final double? longitude;
  final String locationMode;
  final String locationSource;
  final String? address;
  final String? mapQuery;
  final String? searchQuery;
  final String locationSummary;
  final double confidenceScore;
  final List<LocationClue> locationClues;
  final AiSceneLocationInsight aiInsight;
  final Map<String, Object?> exif;
  final String? ocrText;
  final int faceCount;
  final double? blurScore;
  final Color? averageColor;
  final List<Color> dominantColors;
  final String? warning;

  const AnalysisResult({
    required this.imagePath,
    required this.mode,
    required this.latitude,
    required this.longitude,
    required this.locationMode,
    required this.locationSource,
    required this.address,
    required this.mapQuery,
    required this.searchQuery,
    required this.locationSummary,
    required this.confidenceScore,
    required this.locationClues,
    required this.aiInsight,
    required this.exif,
    required this.ocrText,
    required this.faceCount,
    required this.blurScore,
    required this.averageColor,
    required this.dominantColors,
    required this.warning,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasMapQuery => (mapQuery ?? '').trim().isNotEmpty;

  bool get hasSearchQuery => (searchQuery ?? '').trim().isNotEmpty;
}

class ImageLocationIntelPage extends StatefulWidget {
  const ImageLocationIntelPage({super.key});

  @override
  State<ImageLocationIntelPage> createState() => _ImageLocationIntelPageState();
}

class _ImageLocationIntelPageState extends State<ImageLocationIntelPage> {
  final ImagePicker _picker = ImagePicker();

  bool _busy = false;
  AnalysisResult? _result;
  String? _error;


  bool get _isSupportedPlatform {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _analyzeExistingImage() async {
    final l10n = AppL10n.of(context);
    if (!_isSupportedPlatform) {
      setState(() => _error = l10n.get('intel_mobile_only'));
      return;
    }

    try {
      setState(() {
        _busy = true;
        _result = null;
        _error = null;
      });

      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) {
        return;
      }

      final result = await _analyzeImage(
        imagePath: file.path,
        mode: AnalyzeMode.existingImage,
      );

      if (!mounted) {
        return;
      }
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _captureNewImageWithGuaranteedGps() async {
    final l10n = AppL10n.of(context);
    if (!_isSupportedPlatform) {
      setState(() => _error = l10n.get('intel_mobile_only'));
      return;
    }

    try {
      setState(() {
        _busy = true;
        _result = null;
        _error = null;
      });

      final position = await _getCurrentPreciseLocation();
      final XFile? file = await _picker.pickImage(source: ImageSource.camera);
      if (file == null) {
        return;
      }

      final result = await _analyzeImage(
        imagePath: file.path,
        mode: AnalyzeMode.newCaptureWithGuaranteedGps,
        forcedLatitude: position.latitude,
        forcedLongitude: position.longitude,
      );

      if (!mounted) {
        return;
      }
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<Position> _getCurrentPreciseLocation() async {
    final l10n = AppL10n.of(context);
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(l10n.get('intel_location_service_off'));
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(l10n.get('intel_location_permission_denied'));
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(l10n.get('intel_location_permission_denied_forever'));
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );
  }

  Future<AnalysisResult> _analyzeImage({
    required String imagePath,
    required AnalyzeMode mode,
    double? forcedLatitude,
    double? forcedLongitude,
  }) async {
    final l10n = AppL10n.of(context);
    final appConfig = context.read<AppConfig>();
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final exifReader = await Exif.fromPath(imagePath);

    try {
      final exifMap = Map<String, Object?>.from(
        await exifReader.getAttributes() ?? <String, Object?>{},
      );

      double? exifLatitude;
      double? exifLongitude;

      try {
        final dynamic latLong = await exifReader.getLatLong();
        if (latLong != null) {
          exifLatitude = latLong.latitude as double?;
          exifLongitude = latLong.longitude as double?;
        }
      } catch (_) {
        // Keep analyzing the image even if EXIF GPS parsing fails.
      }

      final addressFuture = exifLatitude != null && exifLongitude != null
          ? _reverseGeocode(exifLatitude, exifLongitude)
          : Future<String?>.value(null);
      final ocrFuture = _extractText(imagePath);
      final faceFuture = _detectFaces(imagePath);
      final visual = _analyzePixels(bytes);

      final baseAddress = await addressFuture;
      final ocrText = await ocrFuture;
      final faceCount = await faceFuture;

      final resolvedLocation = await _resolveLocation(
        l10n: l10n,
        exifLatitude: exifLatitude,
        exifLongitude: exifLongitude,
        baseAddress: baseAddress,
        forcedLatitude: forcedLatitude,
        forcedLongitude: forcedLongitude,
        ocrText: ocrText,
        exif: exifMap,
      );

      final aiInsight = await OpenAiLocationSceneService(
        appConfig,
      ).analyzeScene(
        imageBytes: bytes,
        ocrText: ocrText,
        existingAddress: baseAddress,
        latitude: null,
        longitude: null,
        localLocationSummary: null,
      );

      final resolvedLocationFinal = await _mergeAiLocation(
        l10n: l10n,
        base: resolvedLocation,
        aiInsight: aiInsight,
      );

      return AnalysisResult(
        imagePath: imagePath,
        mode: mode,
        latitude: resolvedLocation.latitude,
        longitude: resolvedLocation.longitude,
        locationMode: resolvedLocation.locationMode,
        locationSource: resolvedLocation.locationSource,
        address: resolvedLocation.address,
        mapQuery: resolvedLocation.mapQuery,
        searchQuery: resolvedLocation.searchQuery,
        locationSummary: resolvedLocation.locationSummary,
        confidenceScore: resolvedLocation.confidenceScore,
        locationClues: resolvedLocation.clues,
        aiInsight: aiInsight,
        exif: exifMap,
        ocrText: ocrText,
        faceCount: faceCount,
        blurScore: visual.blurScore,
        averageColor: visual.averageColor,
        dominantColors: visual.dominantColors,
        warning: resolvedLocation.warning,
      );
    } catch (error) {
      throw Exception('${l10n.get('intel_analysis_failed_prefix')}$error');
    } finally {
      await exifReader.close();
    }
  }

  Future<_ResolvedLocation> _resolveLocation({
    required AppL10n l10n,
    required double? exifLatitude,
    required double? exifLongitude,
    required String? baseAddress,
    required double? forcedLatitude,
    required double? forcedLongitude,
    required String? ocrText,
    required Map<String, Object?> exif,
  }) async {
    final clues = <LocationClue>[];
    double? latitude = exifLatitude;
    double? longitude = exifLongitude;
    String? address = baseAddress;
    String? mapQuery;
    String? searchQuery;
    String? warning;
    var locationMode = 'unknown';
    var locationSource = 'none';
    var confidenceScore = 0.08;

    if (latitude != null && longitude != null) {
      locationMode = 'exact';
      locationSource = 'exif_gps';
      confidenceScore = 0.99;
      clues.add(
        LocationClue(
          title: l10n.get('intel_exif_gps_clue_title'),
          value:
              '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
          detail: l10n.get('intel_exif_gps_clue_detail'),
          isStrong: true,
        ),
      );
    } else if (forcedLatitude != null && forcedLongitude != null) {
      latitude = forcedLatitude;
      longitude = forcedLongitude;
      locationMode = 'exact';
      locationSource = 'live_gps';
      confidenceScore = 0.96;
      warning = l10n.get('intel_live_gps_warning');
      clues.add(
        LocationClue(
          title: l10n.get('intel_live_gps_clue_title'),
          value:
              '${forcedLatitude.toStringAsFixed(6)}, ${forcedLongitude.toStringAsFixed(6)}',
          detail: l10n.get('intel_live_gps_clue_detail'),
          isStrong: true,
        ),
      );
    }

    final exifTextClues = _extractExifTextClues(exif);
    if (exifTextClues.isNotEmpty) {
      clues.add(
        LocationClue(
          title: l10n.get('intel_exif_text_clue_title'),
          value: _truncate(exifTextClues.first, 96),
          detail: l10n.get('intel_exif_text_clue_detail'),
          isStrong: false,
        ),
      );
    }

    final combinedText = [
      if ((ocrText ?? '').trim().isNotEmpty) ocrText!.trim(),
      ...exifTextClues,
    ].join('\n');

    final readableLines = _extractReadableLines(combinedText);
    if (readableLines.isNotEmpty) {
      clues.add(
        LocationClue(
          title: l10n.get('intel_detected_text_clue_title'),
          value: _truncate(readableLines.take(2).join(' | '), 96),
          detail: l10n.get('intel_detected_text_clue_detail'),
          isStrong: false,
        ),
      );
    }

    final coordinateMatches = _extractCoordinatesFromText(combinedText);
    if (coordinateMatches.isNotEmpty) {
      final coordinate = coordinateMatches.first;
      clues.add(
        LocationClue(
          title: l10n.get('intel_text_coordinates_clue_title'),
          value:
              '${coordinate.latitude.toStringAsFixed(6)}, ${coordinate.longitude.toStringAsFixed(6)}',
          detail: l10n.get('intel_text_coordinates_clue_detail'),
          isStrong: true,
        ),
      );

      if (locationMode != 'exact') {
        latitude = coordinate.latitude;
        longitude = coordinate.longitude;
        locationMode = 'estimated';
        locationSource = 'text_coordinates';
        confidenceScore = 0.88;
      }
    }

    final placeQueries = _extractPlaceQueries(combinedText);
    if (placeQueries.isNotEmpty) {
      mapQuery = placeQueries.first;
      searchQuery = placeQueries.first;
      clues.add(
        LocationClue(
          title: l10n.get('intel_search_query_clue_title'),
          value: placeQueries.first,
          detail: l10n.get('intel_search_query_clue_detail'),
          isStrong: _containsLocationKeyword(placeQueries.first),
        ),
      );
    }

    final geocoded = await _resolveBestQuery(placeQueries);
    if (geocoded != null) {
      clues.add(
        LocationClue(
          title: l10n.get('intel_geocoded_place_clue_title'),
          value: geocoded.resolvedAddress ?? geocoded.query,
          detail: l10n.intelGeocodedPlaceClueDetail(geocoded.query),
          isStrong: true,
        ),
      );

      mapQuery = geocoded.query;
      searchQuery = geocoded.query;

      if (locationMode != 'exact' && coordinateMatches.isEmpty) {
        latitude = geocoded.latitude;
        longitude = geocoded.longitude;
        locationMode = 'estimated';
        locationSource = 'text_geocode';
        confidenceScore = math.max(confidenceScore, geocoded.score);
      }
    }

    if (latitude != null && longitude != null && address == null) {
      address = await _reverseGeocode(latitude, longitude);
    }

    if (locationMode == 'unknown' && searchQuery != null) {
      locationMode = 'estimated';
      locationSource = 'text_query';
      confidenceScore = 0.46;
    }

    if (address != null && mapQuery == null) {
      mapQuery = address;
      searchQuery ??= address;
    }

    final locationSummary = _buildLocationSummary(
      l10n: l10n,
      locationMode: locationMode,
      locationSource: locationSource,
      address: address,
      mapQuery: mapQuery,
      clueCount: clues.length,
    );

    return _ResolvedLocation(
      latitude: latitude,
      longitude: longitude,
      locationMode: locationMode,
      locationSource: locationSource,
      address: address,
      mapQuery: mapQuery,
      searchQuery: searchQuery,
      locationSummary: locationSummary,
      confidenceScore: confidenceScore,
      clues: clues,
      warning: warning,
    );
  }

  Future<_ResolvedLocation> _mergeAiLocation({
    required AppL10n l10n,
    required _ResolvedLocation base,
    required AiSceneLocationInsight aiInsight,
  }) async {
    if (!aiInsight.success) {
      return base;
    }

    var latitude = base.latitude;
    var longitude = base.longitude;
    var address = base.address;
    var mapQuery = base.mapQuery;
    var searchQuery = base.searchQuery;
    var locationMode = base.locationMode;
    var locationSource = base.locationSource;
    var locationSummary = base.locationSummary;
    var confidenceScore = base.confidenceScore;
    var warning = base.warning;
    final clues = <LocationClue>[...base.clues];

    if ((aiInsight.summary ?? '').trim().isNotEmpty) {
      clues.add(
        LocationClue(
          title: l10n.get('intel_ai_scene_summary_clue_title'),
          value: _truncate(aiInsight.summary!, 110),
          detail: l10n.get('intel_ai_scene_summary_clue_detail'),
          isStrong: false,
        ),
      );
    }

    for (final visualClue in aiInsight.visualClues.take(4)) {
      clues.add(
        LocationClue(
          title: l10n.get('intel_ai_visual_clue_title'),
          value: _truncate(visualClue, 96),
          detail: l10n.get('intel_ai_visual_clue_detail'),
          isStrong: false,
        ),
      );
    }

    final aiQuery = (aiInsight.bestLocationQuery ?? '').trim().isNotEmpty
        ? aiInsight.bestLocationQuery!.trim()
        : (aiInsight.searchQuery ?? '').trim().isNotEmpty
            ? aiInsight.searchQuery!.trim()
            : null;

    if (aiQuery != null) {
      clues.add(
        LocationClue(
          title: l10n.get('intel_ai_location_guess_clue_title'),
          value: _truncate(aiInsight.bestLocationGuess ?? aiQuery, 96),
          detail: l10n.get('intel_ai_location_guess_clue_detail'),
          isStrong: (aiInsight.confidenceScore ?? 0) >= 0.55,
        ),
      );
    }

    if (base.locationMode != 'exact' && aiQuery != null) {
      mapQuery = aiQuery;
      searchQuery = aiInsight.searchQuery ?? aiQuery;

      try {
        final aiLocations = await locationFromAddress(aiQuery);
        if (aiLocations.isNotEmpty) {
          final aiBest = aiLocations.first;
          latitude = aiBest.latitude;
          longitude = aiBest.longitude;
          address ??= await _reverseGeocode(latitude, longitude);
          locationMode = 'estimated';
          locationSource = 'ai_scene';
          confidenceScore = math.max(
            confidenceScore,
            (aiInsight.confidenceScore ?? 0.58).clamp(0.45, 0.84),
          );
          locationSummary = l10n.intelAiSceneSummary(address ?? aiQuery);
        }
      } catch (_) {
        if (base.locationMode == 'unknown') {
          locationMode = 'estimated';
          locationSource = 'ai_scene_query';
          confidenceScore = math.max(
            confidenceScore,
            (aiInsight.confidenceScore ?? 0.44).clamp(0.35, 0.72),
          );
          locationSummary = l10n.intelAiSceneQuerySummary(aiQuery);
        }
      }
    } else if (base.locationMode == 'exact' && aiQuery != null) {
      locationSummary = l10n.intelAiSupportsExactSummary(base.locationSummary);
    }

    if (aiInsight.caution != null &&
        aiInsight.caution!.trim().isNotEmpty &&
        warning == null) {
      warning = aiInsight.caution;
    }

    return _ResolvedLocation(
      latitude: latitude,
      longitude: longitude,
      locationMode: locationMode,
      locationSource: locationSource,
      address: address,
      mapQuery: mapQuery,
      searchQuery: searchQuery,
      locationSummary: locationSummary,
      confidenceScore: confidenceScore,
      clues: clues,
      warning: warning,
    );
  }

  String _buildLocationSummary({
    required AppL10n l10n,
    required String locationMode,
    required String locationSource,
    required String? address,
    required String? mapQuery,
    required int clueCount,
  }) {
    switch (locationSource) {
      case 'exif_gps':
        return l10n.intelExactGpsSummary(address);
      case 'live_gps':
        return l10n.intelLiveGpsSummary(address);
      case 'text_coordinates':
        return l10n.intelTextCoordinatesSummary(address ?? mapQuery);
      case 'text_geocode':
        return l10n.intelTextGeocodeSummary(address ?? mapQuery);
      case 'text_query':
        return l10n.intelTextQuerySummary(mapQuery);
      default:
        if (locationMode == 'estimated' && mapQuery != null) {
          return l10n.intelTextQuerySummary(mapQuery);
        }
        if (clueCount > 0) {
          return l10n.get('intel_weak_clues_summary');
        }
        return l10n.get('intel_no_location_summary');
    }
  }

  List<String> _extractExifTextClues(Map<String, Object?> exif) {
    const interestingKeyHints = <String>[
      'description',
      'comment',
      'artist',
      'subject',
      'gpsdest',
      'gpsarea',
      'caption',
      'title',
    ];

    final candidates = <String>{};
    for (final entry in exif.entries) {
      final key = entry.key.toLowerCase();
      if (!interestingKeyHints.any(key.contains)) {
        continue;
      }

      final value = '${entry.value}'.trim();
      if (value.isEmpty || value.length < 3) {
        continue;
      }

      candidates.add(value.replaceAll(RegExp(r'\s+'), ' ').trim());
    }

    return candidates.toList();
  }

  List<_CoordinateMatch> _extractCoordinatesFromText(String text) {
    if (text.trim().isEmpty) {
      return const <_CoordinateMatch>[];
    }

    final matches = <_CoordinateMatch>[];
    final seen = <String>{};
    final regex = RegExp(
      r'(-?\d{1,2}\.\d{3,})\s*[,;/ ]\s*(-?\d{1,3}\.\d{3,})',
      multiLine: true,
    );

    for (final match in regex.allMatches(text)) {
      final lat = double.tryParse(match.group(1) ?? '');
      final lng = double.tryParse(match.group(2) ?? '');
      if (lat == null || lng == null) {
        continue;
      }
      if (lat.abs() > 90 || lng.abs() > 180) {
        continue;
      }

      final key = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
      if (!seen.add(key)) {
        continue;
      }

      matches.add(_CoordinateMatch(latitude: lat, longitude: lng));
    }

    return matches;
  }

  List<String> _extractPlaceQueries(String text) {
    final lines = _extractReadableLines(text);
    if (lines.isEmpty) {
      return const <String>[];
    }

    final candidates = <String>{};
    for (final line in lines) {
      if (_looksLikeLocationCandidate(line)) {
        candidates.add(line);
      }
    }

    for (var i = 0; i < lines.length - 1; i++) {
      final combined = '${lines[i]} ${lines[i + 1]}'.trim();
      if (combined.length <= 96 && _looksLikeLocationCandidate(combined)) {
        candidates.add(combined);
      }
    }

    final ordered = candidates.toList()
      ..sort((a, b) => _scorePlaceQuery(b).compareTo(_scorePlaceQuery(a)));
    return ordered;
  }

  List<String> _extractReadableLines(String text) {
    if (text.trim().isEmpty) {
      return const <String>[];
    }

    final lines = <String>{};
    for (final raw in text.split(RegExp(r'[\r\n]+'))) {
      final cleaned = raw
          .replaceAll(RegExp(r'[|•]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (cleaned.length < 3 || cleaned.length > 96) {
        continue;
      }

      if (!RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(cleaned)) {
        continue;
      }

      lines.add(cleaned);
    }

    return lines.toList();
  }

  bool _looksLikeLocationCandidate(String value) {
    if (value.length < 3 || value.length > 96) {
      return false;
    }
    if (RegExp(r'^[\d\W_]+$').hasMatch(value)) {
      return false;
    }

    final words = value.split(' ').where((part) => part.isNotEmpty).length;
    final hasDigits = RegExp(r'\d').hasMatch(value);
    return _containsLocationKeyword(value) || hasDigits || words >= 2;
  }

  bool _containsLocationKeyword(String value) {
    const keywords = <String>[
      'street',
      'st',
      'road',
      'rd',
      'avenue',
      'ave',
      'boulevard',
      'blvd',
      'hotel',
      'mall',
      'airport',
      'station',
      'cafe',
      'restaurant',
      'university',
      'hospital',
      'city',
      'district',
      'tower',
      'center',
      'centre',
      'plaza',
      'park',
      'beach',
      'museum',
      'mosque',
      'masjid',
      'شارع',
      'طريق',
      'حي',
      'مطار',
      'فندق',
      'جامعة',
      'مستشفى',
      'مسجد',
      'سوق',
      'مول',
      'مدينة',
      'محطة',
      'ميدان',
      'كورنيش',
      'برج',
      'سنتر',
      'بلازا',
    ];

    final lower = value.toLowerCase();
    return keywords.any(lower.contains);
  }

  double _scorePlaceQuery(String query) {
    var score = 0.0;
    if (_containsLocationKeyword(query)) {
      score += 0.35;
    }
    if (RegExp(r'\d').hasMatch(query)) {
      score += 0.15;
    }
    if (query.contains(',')) {
      score += 0.1;
    }

    final words = query.split(' ').where((part) => part.isNotEmpty).length;
    score += math.min(words, 6) * 0.05;
    if (query.length > 64) {
      score -= 0.08;
    }
    return score;
  }

  Future<_GeocodedCandidate?> _resolveBestQuery(List<String> queries) async {
    _GeocodedCandidate? best;
    for (final query in queries.take(6)) {
      try {
        final locations = await locationFromAddress(query);
        if (locations.isEmpty) {
          continue;
        }

        final first = locations.first;
        final resolvedAddress = await _reverseGeocode(
          first.latitude,
          first.longitude,
        );
        final candidate = _GeocodedCandidate(
          query: query,
          latitude: first.latitude,
          longitude: first.longitude,
          resolvedAddress: resolvedAddress,
          score: (_scorePlaceQuery(query) + 0.25).clamp(0.55, 0.82),
        );

        if (best == null || candidate.score > best.score) {
          best = candidate;
        }
      } catch (_) {
        // Keep trying other candidates.
      }
    }
    return best;
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return null;
      }

      final place = placemarks.first;
      return <String?>[
        place.country,
        place.administrativeArea,
        place.locality,
        place.subLocality,
        place.street,
      ]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join(' - ');
    } catch (_) {
      return null;
    }
  }

  Future<String?> _extractText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);
      final text = result.text.trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    } finally {
      await recognizer.close();
    }
  }

  Future<int> _detectFaces(String imagePath) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableContours: false,
        enableLandmarks: false,
      ),
    );

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await detector.processImage(inputImage);
      return faces.length;
    } catch (_) {
      return 0;
    } finally {
      await detector.close();
    }
  }

  _VisualStats _analyzePixels(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) {
      return const _VisualStats(
        averageColor: null,
        dominantColors: <Color>[],
        blurScore: null,
      );
    }

    final resized = img.copyResize(
      image,
      width: math.min(120, image.width),
    );

    var rTotal = 0;
    var gTotal = 0;
    var bTotal = 0;
    var count = 0;
    var edgeSum = 0.0;
    final buckets = <int, int>{};

    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        rTotal += r;
        gTotal += g;
        bTotal += b;
        count++;

        final bucketR = (r ~/ 32) * 32;
        final bucketG = (g ~/ 32) * 32;
        final bucketB = (b ~/ 32) * 32;
        final key = (bucketR << 16) | (bucketG << 8) | bucketB;
        buckets[key] = (buckets[key] ?? 0) + 1;

        if (x < resized.width - 1 && y < resized.height - 1) {
          final p2 = resized.getPixel(x + 1, y);
          final p3 = resized.getPixel(x, y + 1);

          final l1 = 0.299 * r + 0.587 * g + 0.114 * b;
          final l2 = 0.299 * p2.r + 0.587 * p2.g + 0.114 * p2.b;
          final l3 = 0.299 * p3.r + 0.587 * p3.g + 0.114 * p3.b;
          edgeSum += (l1 - l2).abs() + (l1 - l3).abs();
        }
      }
    }

    final averageColor = count == 0
        ? null
        : Color.fromARGB(
            255,
            (rTotal / count).round(),
            (gTotal / count).round(),
            (bTotal / count).round(),
          );

    final dominantEntries = buckets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final dominantColors = dominantEntries.take(5).map((entry) {
      final r = (entry.key >> 16) & 0xFF;
      final g = (entry.key >> 8) & 0xFF;
      final b = entry.key & 0xFF;
      return Color.fromARGB(255, r, g, b);
    }).toList();

    return _VisualStats(
      averageColor: averageColor,
      dominantColors: dominantColors,
      blurScore: count == 0 ? null : edgeSum / count,
    );
  }

  Future<void> _openExactMap(double lat, double lng) async {
    final l10n = AppL10n.of(context);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception(l10n.get('intel_map_open_failed'));
    }
  }

  Future<void> _openMapQuery(String query) async {
    final l10n = AppL10n.of(context);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception(l10n.get('intel_map_open_failed'));
    }
  }

  Future<void> _openWebSearch(String query) async {
    final l10n = AppL10n.of(context);
    final uri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent(query)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception(l10n.get('intel_search_open_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('intel_page_title')),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.get('intel_page_headline'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    l10n.get('intel_page_description'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    l10n.get('intel_limitations_note'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (!_isSupportedPlatform) ...<Widget>[
                    SizedBox(height: 12),
                    Text(
                      l10n.get('intel_mobile_only'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                _busy || !_isSupportedPlatform ? null : _analyzeExistingImage,
            icon: Icon(Icons.photo_library_outlined),
            label: Text(l10n.get('intel_analyze_existing')),
          ),
          SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _busy || !_isSupportedPlatform
                ? null
                : _captureNewImageWithGuaranteedGps,
            icon: Icon(Icons.add_a_photo_outlined),
            label: Text(l10n.get('intel_capture_with_gps')),
          ),
          SizedBox(height: 20),
          if (_busy) Center(child: CircularProgressIndicator()),
          if (_error != null) ...<Widget>[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
          ],
          if (result != null) ...<Widget>[
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(result.imagePath),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _statusChip(
                          l10n.intelLocationModeName(result.locationMode),
                          _modeColor(result.locationMode),
                        ),
                        _statusChip(
                          '${l10n.intelConfidenceName(result.confidenceScore)} ${(result.confidenceScore * 100).round()}%',
                          _confidenceColor(result.confidenceScore),
                        ),
                        _statusChip(
                          l10n.intelLocationSourceName(result.locationSource),
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      l10n.get('intel_location_report_title'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(result.locationSummary),
                    SizedBox(height: 12),
                    _infoLine(l10n.get('intel_mode_label'), l10n.intelModeName(result.mode == AnalyzeMode.existingImage)),
                    _infoLine(
                      l10n.get('intel_location_mode_label'),
                      l10n.intelLocationModeName(result.locationMode),
                    ),
                    _infoLine(
                      l10n.get('intel_source_label'),
                      l10n.intelLocationSourceName(result.locationSource),
                    ),
                    _infoLine(
                      l10n.get('intel_confidence_label'),
                      '${l10n.intelConfidenceName(result.confidenceScore)} ${(result.confidenceScore * 100).round()}%',
                    ),
                    _infoLine(
                      l10n.get('intel_latitude_label'),
                      result.latitude?.toStringAsFixed(6) ?? l10n.get('intel_not_available'),
                    ),
                    _infoLine(
                      l10n.get('intel_longitude_label'),
                      result.longitude?.toStringAsFixed(6) ?? l10n.get('intel_not_available'),
                    ),
                    _infoLine(
                      l10n.get('intel_address_label'),
                      result.address ?? l10n.get('intel_not_available'),
                    ),
                    _infoLine(
                      l10n.get('intel_best_query_label'),
                      result.mapQuery ?? l10n.get('intel_not_available'),
                    ),
                    _infoLine(l10n.get('intel_faces_label'), '${result.faceCount}'),
                    _infoLine(
                      l10n.get('intel_blur_score_label'),
                      result.blurScore?.toStringAsFixed(2) ?? l10n.get('intel_not_available'),
                    ),
                    if (result.warning != null) ...<Widget>[
                      SizedBox(height: 8),
                      Text(
                        result.warning!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        if (result.hasCoordinates)
                          FilledButton.icon(
                            onPressed: () => _openExactMap(
                              result.latitude!,
                              result.longitude!,
                            ),
                            icon: Icon(Icons.location_on_outlined),
                            label: Text(l10n.get('intel_open_exact_map')),
                          ),
                        if (result.hasMapQuery)
                          OutlinedButton.icon(
                            onPressed: () => _openMapQuery(result.mapQuery!),
                            icon: Icon(Icons.map_outlined),
                            label: Text(l10n.get('intel_search_on_maps')),
                          ),
                        if (result.hasSearchQuery)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _openWebSearch(result.searchQuery!),
                            icon: Icon(Icons.travel_explore_outlined),
                            label: Text(l10n.get('intel_search_web')),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.get('intel_ai_section_title'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(l10n.intelAiStatusLabel(result.aiInsight.status ?? '')),
                    if (result.aiInsight.success) ...<Widget>[
                      SizedBox(height: 8),
                      _infoLine(
                        l10n.get('intel_ai_confidence_label'),
                        result.aiInsight.confidenceScore == null
                            ? l10n.get('intel_not_available')
                            : '${l10n.intelConfidenceName(result.aiInsight.confidenceScore!)} ${(result.aiInsight.confidenceScore! * 100).round()}%',
                      ),
                      _infoLine(
                        l10n.get('intel_ai_scene_type_label'),
                        result.aiInsight.sceneType ?? l10n.get('intel_not_available'),
                      ),
                      _infoLine(
                        l10n.get('intel_ai_best_guess_label'),
                        result.aiInsight.bestLocationGuess ?? l10n.get('intel_not_available'),
                      ),
                      _infoLine(
                        l10n.get('intel_ai_best_query_label'),
                        result.aiInsight.bestLocationQuery ??
                            result.aiInsight.searchQuery ??
                            l10n.get('intel_not_available'),
                      ),
                      if ((result.aiInsight.summary ?? '').trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(result.aiInsight.summary!),
                        ),
                      if (result.aiInsight.visualClues.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: result.aiInsight.visualClues
                              .take(6)
                              .map(
                                (clue) => _statusChip(
                                  clue,
                                  Theme.of(context).colorScheme.secondary,
                                ),
                              )
                              .toList(),
                        ),
                      if ((result.aiInsight.caution ?? '').trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            result.aiInsight.caution!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                    if (!result.aiInsight.success &&
                        result.aiInsight.enabled &&
                        (result.aiInsight.error ?? '')
                            .trim()
                            .isNotEmpty) ...<Widget>[
                      SizedBox(height: 8),
                      Text(
                        result.aiInsight.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.get('intel_location_clues_title'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 8),
                    if (result.locationClues.isEmpty)
                      Text(l10n.get('intel_no_location_clues'))
                    else
                      ...result.locationClues.map(
                        (clue) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            clue.isStrong
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color: clue.isStrong
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          title: Text(clue.title),
                          subtitle: Text('${clue.value}\n${clue.detail}'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.get('intel_ocr_title'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(result.ocrText ?? l10n.get('intel_no_text_found')),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.get('intel_colors_title'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _colorTile(result.averageColor, l10n.get('intel_average_color_label')),
                        ...result.dominantColors.take(4).map(
                              (color) => _colorTile(color, l10n.get('intel_top_color_label')),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    l10n.get('intel_exif_title'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  children: result.exif.entries.map((entry) {
                    return ListTile(
                      dense: true,
                      title: Text(entry.key),
                      subtitle: Text('${entry.value}'),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _colorTile(Color? color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color ?? Colors.grey.shade400,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black12),
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }

  Color _modeColor(String mode) {
    final scheme = Theme.of(context).colorScheme;
    switch (mode) {
      case 'exact':
        return scheme.primary;
      case 'estimated':
        return scheme.tertiary;
      default:
        return scheme.outline;
    }
  }

  Color _confidenceColor(double score) {
    final scheme = Theme.of(context).colorScheme;
    if (score >= 0.9) {
      return scheme.primary;
    }
    if (score >= 0.7) {
      return scheme.secondary;
    }
    if (score >= 0.45) {
      return scheme.tertiary;
    }
    return scheme.outline;
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength - 1)}…';
  }
}

class _ResolvedLocation {
  final double? latitude;
  final double? longitude;
  final String locationMode;
  final String locationSource;
  final String? address;
  final String? mapQuery;
  final String? searchQuery;
  final String locationSummary;
  final double confidenceScore;
  final List<LocationClue> clues;
  final String? warning;

  const _ResolvedLocation({
    required this.latitude,
    required this.longitude,
    required this.locationMode,
    required this.locationSource,
    required this.address,
    required this.mapQuery,
    required this.searchQuery,
    required this.locationSummary,
    required this.confidenceScore,
    required this.clues,
    required this.warning,
  });
}

class _GeocodedCandidate {
  final String query;
  final double latitude;
  final double longitude;
  final String? resolvedAddress;
  final double score;

  const _GeocodedCandidate({
    required this.query,
    required this.latitude,
    required this.longitude,
    required this.resolvedAddress,
    required this.score,
  });
}

class _CoordinateMatch {
  final double latitude;
  final double longitude;

  const _CoordinateMatch({
    required this.latitude,
    required this.longitude,
  });
}

class _VisualStats {
  final Color? averageColor;
  final List<Color> dominantColors;
  final double? blurScore;

  const _VisualStats({
    required this.averageColor,
    required this.dominantColors,
    required this.blurScore,
  });
}
