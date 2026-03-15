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
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  _ImageIntelCopy get _copy {
    final locale = Localizations.localeOf(context);
    return _ImageIntelCopy(locale.languageCode.toLowerCase().startsWith('ar'));
  }

  Future<void> _analyzeExistingImage() async {
    final copy = _copy;
    if (!_isSupportedPlatform) {
      setState(() => _error = copy.mobileOnlyMessage);
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
    final copy = _copy;
    if (!_isSupportedPlatform) {
      setState(() => _error = copy.mobileOnlyMessage);
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
    final copy = _copy;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(copy.locationServiceOff);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(copy.locationPermissionDenied);
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(copy.locationPermissionDeniedForever);
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
    final copy = _copy;
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

      final localLocation = await _resolveLocation(
        copy: copy,
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
        latitude: localLocation.latitude,
        longitude: localLocation.longitude,
        localLocationSummary: localLocation.locationSummary,
      );

      final resolvedLocation = await _mergeAiLocation(
        copy: copy,
        base: localLocation,
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
      throw Exception('${copy.analysisFailedPrefix}$error');
    } finally {
      await exifReader.close();
    }
  }

  Future<_ResolvedLocation> _resolveLocation({
    required _ImageIntelCopy copy,
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
          title: copy.exifGpsClueTitle,
          value:
              '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
          detail: copy.exifGpsClueDetail,
          isStrong: true,
        ),
      );
    } else if (forcedLatitude != null && forcedLongitude != null) {
      latitude = forcedLatitude;
      longitude = forcedLongitude;
      locationMode = 'exact';
      locationSource = 'live_gps';
      confidenceScore = 0.96;
      warning = copy.liveGpsWarning;
      clues.add(
        LocationClue(
          title: copy.liveGpsClueTitle,
          value:
              '${forcedLatitude.toStringAsFixed(6)}, ${forcedLongitude.toStringAsFixed(6)}',
          detail: copy.liveGpsClueDetail,
          isStrong: true,
        ),
      );
    }

    final exifTextClues = _extractExifTextClues(exif);
    if (exifTextClues.isNotEmpty) {
      clues.add(
        LocationClue(
          title: copy.exifTextClueTitle,
          value: _truncate(exifTextClues.first, 96),
          detail: copy.exifTextClueDetail,
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
          title: copy.detectedTextClueTitle,
          value: _truncate(readableLines.take(2).join(' | '), 96),
          detail: copy.detectedTextClueDetail,
          isStrong: false,
        ),
      );
    }

    final coordinateMatches = _extractCoordinatesFromText(combinedText);
    if (coordinateMatches.isNotEmpty) {
      final coordinate = coordinateMatches.first;
      clues.add(
        LocationClue(
          title: copy.textCoordinatesClueTitle,
          value:
              '${coordinate.latitude.toStringAsFixed(6)}, ${coordinate.longitude.toStringAsFixed(6)}',
          detail: copy.textCoordinatesClueDetail,
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
          title: copy.searchQueryClueTitle,
          value: placeQueries.first,
          detail: copy.searchQueryClueDetail,
          isStrong: _containsLocationKeyword(placeQueries.first),
        ),
      );
    }

    final geocoded = await _resolveBestQuery(placeQueries);
    if (geocoded != null) {
      clues.add(
        LocationClue(
          title: copy.geocodedPlaceClueTitle,
          value: geocoded.resolvedAddress ?? geocoded.query,
          detail: copy.geocodedPlaceClueDetail(geocoded.query),
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
      copy: copy,
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
    required _ImageIntelCopy copy,
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
          title: copy.aiSceneSummaryClueTitle,
          value: _truncate(aiInsight.summary!, 110),
          detail: copy.aiSceneSummaryClueDetail,
          isStrong: false,
        ),
      );
    }

    for (final visualClue in aiInsight.visualClues.take(4)) {
      clues.add(
        LocationClue(
          title: copy.aiVisualClueTitle,
          value: _truncate(visualClue, 96),
          detail: copy.aiVisualClueDetail,
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
          title: copy.aiLocationGuessClueTitle,
          value: _truncate(aiInsight.bestLocationGuess ?? aiQuery, 96),
          detail: copy.aiLocationGuessClueDetail,
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
          locationSummary = copy.aiSceneSummary(address ?? aiQuery);
        }
      } catch (_) {
        if (base.locationMode == 'unknown') {
          locationMode = 'estimated';
          locationSource = 'ai_scene_query';
          confidenceScore = math.max(
            confidenceScore,
            (aiInsight.confidenceScore ?? 0.44).clamp(0.35, 0.72),
          );
          locationSummary = copy.aiSceneQuerySummary(aiQuery);
        }
      }
    } else if (base.locationMode == 'exact' && aiQuery != null) {
      locationSummary = copy.aiSupportsExactSummary(base.locationSummary);
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
    required _ImageIntelCopy copy,
    required String locationMode,
    required String locationSource,
    required String? address,
    required String? mapQuery,
    required int clueCount,
  }) {
    switch (locationSource) {
      case 'exif_gps':
        return copy.exactGpsSummary(address);
      case 'live_gps':
        return copy.liveGpsSummary(address);
      case 'text_coordinates':
        return copy.textCoordinatesSummary(address ?? mapQuery);
      case 'text_geocode':
        return copy.textGeocodeSummary(address ?? mapQuery);
      case 'text_query':
        return copy.textQuerySummary(mapQuery);
      default:
        if (locationMode == 'estimated' && mapQuery != null) {
          return copy.textQuerySummary(mapQuery);
        }
        if (clueCount > 0) {
          return copy.weakCluesSummary;
        }
        return copy.noLocationSummary;
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
    final copy = _copy;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception(copy.mapOpenFailed);
    }
  }

  Future<void> _openMapQuery(String query) async {
    final copy = _copy;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception(copy.mapOpenFailed);
    }
  }

  Future<void> _openWebSearch(String query) async {
    final copy = _copy;
    final uri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent(query)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception(copy.searchOpenFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copy;
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: Text(copy.pageTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    copy.pageHeadline,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.pageDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.limitationsNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (!_isSupportedPlatform) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      copy.mobileOnlyMessage,
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
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                _busy || !_isSupportedPlatform ? null : _analyzeExistingImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(copy.analyzeExistingButton),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _busy || !_isSupportedPlatform
                ? null
                : _captureNewImageWithGuaranteedGps,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(copy.captureWithGpsButton),
          ),
          const SizedBox(height: 20),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_error != null) ...<Widget>[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (result != null) ...<Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _statusChip(
                          copy.locationModeName(result.locationMode),
                          _modeColor(result.locationMode),
                        ),
                        _statusChip(
                          '${copy.confidenceName(result.confidenceScore)} ${copy.confidencePercent(result.confidenceScore)}',
                          _confidenceColor(result.confidenceScore),
                        ),
                        _statusChip(
                          copy.locationSourceName(result.locationSource),
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      copy.locationReportTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(result.locationSummary),
                    const SizedBox(height: 12),
                    _infoLine(copy.modeLabel, copy.modeName(result.mode)),
                    _infoLine(
                      copy.locationModeLabel,
                      copy.locationModeName(result.locationMode),
                    ),
                    _infoLine(
                      copy.sourceLabel,
                      copy.locationSourceName(result.locationSource),
                    ),
                    _infoLine(
                      copy.confidenceLabel,
                      '${copy.confidenceName(result.confidenceScore)} ${copy.confidencePercent(result.confidenceScore)}',
                    ),
                    _infoLine(
                      copy.latitudeLabel,
                      result.latitude?.toStringAsFixed(6) ?? copy.notAvailable,
                    ),
                    _infoLine(
                      copy.longitudeLabel,
                      result.longitude?.toStringAsFixed(6) ?? copy.notAvailable,
                    ),
                    _infoLine(
                      copy.addressLabel,
                      result.address ?? copy.notAvailable,
                    ),
                    _infoLine(
                      copy.bestQueryLabel,
                      result.mapQuery ?? copy.notAvailable,
                    ),
                    _infoLine(copy.facesLabel, '${result.faceCount}'),
                    _infoLine(
                      copy.blurScoreLabel,
                      result.blurScore?.toStringAsFixed(2) ?? copy.notAvailable,
                    ),
                    if (result.warning != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        result.warning!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
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
                            icon: const Icon(Icons.location_on_outlined),
                            label: Text(copy.openExactMapButton),
                          ),
                        if (result.hasMapQuery)
                          OutlinedButton.icon(
                            onPressed: () => _openMapQuery(result.mapQuery!),
                            icon: const Icon(Icons.map_outlined),
                            label: Text(copy.searchOnMapsButton),
                          ),
                        if (result.hasSearchQuery)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _openWebSearch(result.searchQuery!),
                            icon: const Icon(Icons.travel_explore_outlined),
                            label: Text(copy.searchWebButton),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      copy.aiSectionTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(copy.aiStatusLabel(result.aiInsight)),
                    if (result.aiInsight.success) ...<Widget>[
                      const SizedBox(height: 8),
                      _infoLine(
                        copy.aiConfidenceLabel,
                        result.aiInsight.confidenceScore == null
                            ? copy.notAvailable
                            : '${copy.confidenceName(result.aiInsight.confidenceScore!)} ${copy.confidencePercent(result.aiInsight.confidenceScore!)}',
                      ),
                      _infoLine(
                        copy.aiSceneTypeLabel,
                        result.aiInsight.sceneType ?? copy.notAvailable,
                      ),
                      _infoLine(
                        copy.aiBestGuessLabel,
                        result.aiInsight.bestLocationGuess ?? copy.notAvailable,
                      ),
                      _infoLine(
                        copy.aiBestQueryLabel,
                        result.aiInsight.bestLocationQuery ??
                            result.aiInsight.searchQuery ??
                            copy.notAvailable,
                      ),
                      if ((result.aiInsight.summary ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
                          padding: const EdgeInsets.only(top: 8),
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
                      const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      copy.locationCluesTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (result.locationClues.isEmpty)
                      Text(copy.noLocationClues)
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
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      copy.ocrTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(result.ocrText ?? copy.noTextFound),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      copy.colorsTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _colorTile(result.averageColor, copy.averageColorLabel),
                        ...result.dominantColors.take(4).map(
                              (color) => _colorTile(color, copy.topColorLabel),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    copy.exifTitle,
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
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
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
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _ImageIntelCopy {
  final bool isArabic;

  const _ImageIntelCopy(this.isArabic);

  String get pageTitle =>
      isArabic ? 'تحليل موقع الصورة' : 'Image Location Intel';
  String get pageHeadline => isArabic
      ? 'استخرج GPS إن وجد، ثم حلل النص والقرائن داخل الصورة لتقدير مكانها.'
      : 'Extract GPS when available, then analyze text and clues inside the image to estimate where it was taken.';
  String get pageDescription => isArabic
      ? 'هذه الصفحة تبحث أولًا عن إحداثيات EXIF، ثم تحاول استنتاج الموقع من النصوص والعناوين والمعالم الظاهرة، وتبني مستوى ثقة وأفضل نتيجة قابلة للفتح في Google Maps.'
      : 'This page checks EXIF coordinates first, then tries to infer location from visible text, address fragments, and scene clues, producing a confidence score and the best Google Maps target.';
  String get limitationsNote => isArabic
      ? 'مهم: بدون GPS أو نص واضح أو معلم معروف، النتيجة ستكون تقديرية فقط وليست دليلا قطعيا.'
      : 'Important: without GPS, clear text, or a known landmark, the result remains an estimate rather than proof.';
  String get mobileOnlyMessage => isArabic
      ? 'هذه الميزة تعمل حاليًا على Android و iPhone فقط.'
      : 'This feature currently works on Android and iPhone only.';
  String get analyzeExistingButton =>
      isArabic ? 'تحليل صورة موجودة' : 'Analyze Existing Image';
  String get captureWithGpsButton =>
      isArabic ? 'التقاط صورة جديدة مع GPS' : 'Capture New Image With GPS';
  String get locationServiceOff =>
      isArabic ? 'خدمة الموقع مغلقة.' : 'Location service is turned off.';
  String get locationPermissionDenied =>
      isArabic ? 'تم رفض صلاحية الموقع.' : 'Location permission was denied.';
  String get locationPermissionDeniedForever => isArabic
      ? 'صلاحية الموقع مرفوضة نهائيًا من إعدادات الجهاز.'
      : 'Location permission was permanently denied in device settings.';
  String get liveGpsWarning => isArabic
      ? 'تم استخدام GPS المباشر من الجهاز وقت الالتقاط، لكنه ليس مثبتًا داخل EXIF للصورة نفسها.'
      : 'Live GPS from the device was used at capture time, but it is not confirmed inside the image EXIF itself.';
  String get analysisFailedPrefix =>
      isArabic ? 'فشل تحليل الصورة: ' : 'Image analysis failed: ';
  String get mapOpenFailed =>
      isArabic ? 'تعذر فتح الخريطة.' : 'Could not open the map.';
  String get searchOpenFailed =>
      isArabic ? 'تعذر فتح البحث.' : 'Could not open the search page.';
  String get modeLabel => isArabic ? 'الوضع' : 'Mode';
  String get locationModeLabel => isArabic ? 'نوع التحديد' : 'Location mode';
  String get sourceLabel => isArabic ? 'مصدر الموقع' : 'Location source';
  String get confidenceLabel => isArabic ? 'مستوى الثقة' : 'Confidence';
  String get latitudeLabel => isArabic ? 'خط العرض' : 'Latitude';
  String get longitudeLabel => isArabic ? 'خط الطول' : 'Longitude';
  String get addressLabel => isArabic ? 'العنوان' : 'Address';
  String get bestQueryLabel =>
      isArabic ? 'أفضل استعلام للموقع' : 'Best location query';
  String get facesLabel => isArabic ? 'الوجوه' : 'Faces';
  String get blurScoreLabel => isArabic ? 'مؤشر الحدة' : 'Blur score';
  String get locationReportTitle =>
      isArabic ? 'تقرير تحديد الموقع' : 'Location Report';
  String get aiSectionTitle =>
      isArabic ? 'تحليل الذكاء الاصطناعي للمشهد' : 'AI Scene Analysis';
  String get aiConfidenceLabel =>
      isArabic ? 'ثقة الذكاء الاصطناعي' : 'AI confidence';
  String get aiSceneTypeLabel => isArabic ? 'نوع المشهد' : 'Scene type';
  String get aiBestGuessLabel => isArabic ? 'أفضل تخمين' : 'Best guess';
  String get aiBestQueryLabel => isArabic ? 'أفضل استعلام AI' : 'Best AI query';
  String get openExactMapButton =>
      isArabic ? 'فتح الموقع على الخريطة' : 'Open Exact Map';
  String get searchOnMapsButton =>
      isArabic ? 'بحث في Google Maps' : 'Search on Google Maps';
  String get searchWebButton => isArabic ? 'بحث على الويب' : 'Search the Web';
  String get locationCluesTitle => isArabic ? 'قرائن المكان' : 'Location Clues';
  String get noLocationClues => isArabic
      ? 'لم يتم العثور على قرائن مكانية كافية داخل الصورة.'
      : 'No strong location clues were found inside the image.';
  String get ocrTitle => isArabic ? 'النص المستخرج' : 'OCR Text';
  String get noTextFound =>
      isArabic ? 'لا يوجد نص واضح.' : 'No clear text found.';
  String get colorsTitle => isArabic ? 'الألوان' : 'Colors';
  String get averageColorLabel => isArabic ? 'متوسط' : 'Average';
  String get topColorLabel => isArabic ? 'بارز' : 'Top';
  String get exifTitle => 'EXIF';
  String get notAvailable => isArabic ? 'غير متاح' : 'N/A';
  String get exifGpsClueTitle => isArabic ? 'GPS داخل EXIF' : 'GPS in EXIF';
  String get exifGpsClueDetail => isArabic
      ? 'الصورة نفسها تحتوي على إحداثيات محفوظة داخل بياناتها.'
      : 'The image itself contains coordinates stored in its metadata.';
  String get liveGpsClueTitle =>
      isArabic ? 'GPS مباشر وقت الالتقاط' : 'Live GPS at capture';
  String get liveGpsClueDetail => isArabic
      ? 'استخدم التطبيق موقع الجهاز لحظة التقاط الصورة الجديدة.'
      : 'The app used the device location at the moment of taking the new image.';
  String get exifTextClueTitle =>
      isArabic ? 'نصوص داخل EXIF' : 'Text inside EXIF';
  String get exifTextClueDetail => isArabic
      ? 'بعض الصور تحمل وصفًا أو تعليقًا قد يساعد في الاستدلال على المكان.'
      : 'Some images include descriptions or comments that may help infer location.';
  String get detectedTextClueTitle =>
      isArabic ? 'نص ظاهر في الصورة' : 'Visible text in image';
  String get detectedTextClueDetail => isArabic
      ? 'النص المستخرج قد يحتوي على عنوان أو اسم مكان أو لافتة.'
      : 'Extracted text may include an address, place name, or sign.';
  String get textCoordinatesClueTitle =>
      isArabic ? 'إحداثيات مكتوبة داخل الصورة' : 'Coordinates written in image';
  String get textCoordinatesClueDetail => isArabic
      ? 'تم العثور على أرقام تبدو كإحداثيات داخل النص الظاهر على الصورة.'
      : 'The visible text contains numbers that look like latitude and longitude coordinates.';
  String get searchQueryClueTitle =>
      isArabic ? 'أفضل عبارة بحث مكانية' : 'Best location search phrase';
  String get searchQueryClueDetail => isArabic
      ? 'هذه أقوى عبارة يمكن إرسالها إلى Maps أو البحث العام.'
      : 'This is the strongest phrase that can be sent to Maps or web search.';
  String get geocodedPlaceClueTitle =>
      isArabic ? 'مكان مطابق من النص' : 'Place matched from text';
  String get aiSceneSummaryClueTitle =>
      isArabic ? 'ملخص AI للمشهد' : 'AI scene summary';
  String get aiSceneSummaryClueDetail => isArabic
      ? 'الذكاء الاصطناعي حاول قراءة المشهد نفسه من مبانٍ وطبيعة ومعالم.'
      : 'The AI tried to read the scene itself from buildings, nature, and landmarks.';
  String get aiVisualClueTitle =>
      isArabic ? 'قرينة بصرية من AI' : 'AI visual clue';
  String get aiVisualClueDetail => isArabic
      ? 'هذه إشارة بصرية استنتجها النموذج من الصورة.'
      : 'This is a visual clue inferred by the model from the image.';
  String get aiLocationGuessClueTitle =>
      isArabic ? 'تخمين AI للمكان' : 'AI location guess';
  String get aiLocationGuessClueDetail => isArabic
      ? 'أفضل مكان أو عبارة خرج بها النموذج من تحليل المشهد.'
      : 'The best place or query produced by the model from scene analysis.';
  String geocodedPlaceClueDetail(String query) => isArabic
      ? 'تم تحويل النص "$query" إلى مكان فعلي قابل للعرض على الخريطة.'
      : 'The text "$query" was converted into a real place that can be shown on the map.';
  String exactGpsSummary(String? address) => isArabic
      ? 'تم العثور على موقع دقيق من GPS داخل بيانات الصورة.${address != null ? ' العنوان التقريبي: $address.' : ''}'
      : 'An exact location was found from GPS metadata inside the image.${address != null ? ' Approximate address: $address.' : ''}';
  String liveGpsSummary(String? address) => isArabic
      ? 'تم تحديد الموقع بدقة من GPS الجهاز وقت الالتقاط.${address != null ? ' العنوان التقريبي: $address.' : ''}'
      : 'The location was determined accurately from the device GPS at capture time.${address != null ? ' Approximate address: $address.' : ''}';
  String textCoordinatesSummary(String? locationLabel) => isArabic
      ? 'لا يوجد GPS مؤكد، لكن تم العثور على إحداثيات مكتوبة داخل الصورة${locationLabel != null ? ' وتشير غالبًا إلى: $locationLabel.' : '.'}'
      : 'No confirmed GPS was found, but the image contains written coordinates${locationLabel != null ? ' that likely point to: $locationLabel.' : '.'}';
  String textGeocodeSummary(String? locationLabel) => isArabic
      ? 'لا يوجد GPS مباشر، لكن النص الظاهر أعطى مكانًا محتملًا${locationLabel != null ? ': $locationLabel.' : '.'}'
      : 'There is no direct GPS, but the visible text produced a likely place${locationLabel != null ? ': $locationLabel.' : '.'}';
  String textQuerySummary(String? query) => isArabic
      ? 'تعذر تثبيت الموقع بدقة، لكن التطبيق استخرج عبارة بحث مكانية مفيدة${query != null ? ': $query.' : '.'}'
      : 'An exact place could not be confirmed, but the app extracted a useful location query${query != null ? ': $query.' : '.'}';
  String aiSceneSummary(String? label) => isArabic
      ? 'الذكاء الاصطناعي قرأ المشهد البصري ورجّح موقعًا محتملًا${label != null ? ': $label.' : '.'}'
      : 'The AI read the visual scene and suggested a likely place${label != null ? ': $label.' : '.'}';
  String aiSceneQuerySummary(String? query) => isArabic
      ? 'الذكاء الاصطناعي لم يثبت إحداثيات دقيقة، لكنه قدّم عبارة مكانية قوية${query != null ? ': $query.' : '.'}'
      : 'The AI could not confirm exact coordinates, but it produced a strong location query${query != null ? ': $query.' : '.'}';
  String aiSupportsExactSummary(String baseSummary) => isArabic
      ? '$baseSummary كما أن تحليل AI للمباني والطبيعة يدعم هذه النتيجة.'
      : '$baseSummary The AI reading of buildings and natural cues also supports this result.';
  String get weakCluesSummary => isArabic
      ? 'تم العثور على بعض القرائن، لكنها ليست كافية لتحديد المكان بثقة عالية.'
      : 'Some clues were found, but they are not enough to identify the place with high confidence.';
  String get noLocationSummary => isArabic
      ? 'لم يتم العثور على GPS أو نص أو قرائن مكانية كافية لتحديد مكان الصورة.'
      : 'No GPS, text, or strong spatial clues were found to identify where the image was taken.';

  String modeName(AnalyzeMode mode) {
    if (isArabic) {
      return mode == AnalyzeMode.existingImage
          ? 'صورة موجودة'
          : 'التقاط جديد مع GPS';
    }
    return mode == AnalyzeMode.existingImage
        ? 'Existing image'
        : 'New capture with GPS';
  }

  String locationModeName(String mode) {
    switch (mode) {
      case 'exact':
        return isArabic ? 'دقيق' : 'Exact';
      case 'estimated':
        return isArabic ? 'تقديري' : 'Estimated';
      default:
        return isArabic ? 'غير معروف' : 'Unknown';
    }
  }

  String locationSourceName(String source) {
    switch (source) {
      case 'exif_gps':
        return isArabic ? 'GPS داخل الصورة' : 'Image EXIF GPS';
      case 'live_gps':
        return isArabic ? 'GPS الجهاز' : 'Device GPS';
      case 'text_coordinates':
        return isArabic ? 'إحداثيات من النص' : 'Coordinates from text';
      case 'text_geocode':
        return isArabic ? 'عنوان من النص' : 'Address from text';
      case 'text_query':
        return isArabic ? 'استعلام من النص' : 'Query from text';
      case 'ai_scene':
        return isArabic ? 'تحليل AI للمشهد' : 'AI scene analysis';
      case 'ai_scene_query':
        return isArabic ? 'استعلام AI' : 'AI scene query';
      default:
        return isArabic ? 'غير معروف' : 'Unknown';
    }
  }

  String confidenceName(double score) {
    if (score >= 0.9) {
      return isArabic ? 'عالية جدًا' : 'Very high';
    }
    if (score >= 0.7) {
      return isArabic ? 'عالية' : 'High';
    }
    if (score >= 0.45) {
      return isArabic ? 'متوسطة' : 'Medium';
    }
    return isArabic ? 'ضعيفة' : 'Low';
  }

  String confidencePercent(double score) => '${(score * 100).round()}%';

  String aiStatusLabel(AiSceneLocationInsight insight) {
    switch (insight.status) {
      case 'ready':
        return isArabic
            ? 'AI مفعّل وتم تحليل المشهد بصريًا.'
            : 'AI is enabled and the scene was analyzed visually.';
      case 'failed':
        return isArabic
            ? 'تمت محاولة تحليل AI لكن الطلب فشل.'
            : 'AI analysis was attempted but the request failed.';
      default:
        return isArabic
            ? 'تحليل AI غير مفعّل. أضف OPENAI_API_KEY لتفعيل التعرف على المباني والطبيعة والمعالم.'
            : 'AI analysis is not enabled. Add OPENAI_API_KEY to enable building, nature, and landmark reasoning.';
    }
  }
}
