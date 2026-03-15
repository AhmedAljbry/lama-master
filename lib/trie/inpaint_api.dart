import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart';

class SubmitJobResponse {
  final String jobId;
  SubmitJobResponse({required this.jobId});

  factory SubmitJobResponse.fromJson(Map<String, dynamic> j) {
    final id = (j['job_id'] ?? j['jobId'] ?? j['id'] ?? j['task_id'] ?? j['taskId'])?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('submit-job response missing job_id/jobId/id/task_id');
    }
    return SubmitJobResponse(jobId: id);
  }
}

class JobStatusResponse {
  final String status; // queued|running|done|failed
  final double? progress; // 0..1 optional
  final String? message;

  JobStatusResponse({required this.status, this.progress, this.message});

  factory JobStatusResponse.fromJson(Map<String, dynamic> j) {
    final p = j['progress'];
    return JobStatusResponse(
      status: (j['status'] ?? '').toString(),
      progress: p == null ? null : (p as num).toDouble(),
      message: j['message']?.toString(),
    );
  }

  bool get isDone => status.toLowerCase() == 'done';
  bool get isFailed => status.toLowerCase() == 'failed';
}

class InpaintApi {
  final Dio dio;

  InpaintApi({required String baseUrl})
      : dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 120),
    // helpful defaults
    headers: {'Accept': '*/*'},
    followRedirects: true,
    validateStatus: (code) => code != null && code >= 200 && code < 400,
  )) {
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: false, // multipart كبير، لا تسجله
      responseBody: false,
      responseHeader: false,
    ));
  }

  Future<SubmitJobResponse> submitJob({
    required File image,
    required File maskPng,
  }) async {
    final form = FormData.fromMap({
      // ✅ عدّل الأسماء لو /docs مختلفة
      'image': await MultipartFile.fromFile(image.path, filename: 'image.jpg'),
      'mask': await MultipartFile.fromFile(maskPng.path, filename: 'mask.png'),
    });

    final res = await dio.post('/submit-job', data: form);

    if (res.data is! Map) {
      throw Exception('Unexpected submit-job response type: ${res.data.runtimeType}\nBody: ${res.data}');
    }
    return SubmitJobResponse.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<JobStatusResponse> getStatus(String jobId) async {
    final res = await dio.get('/status/$jobId');
    if (res.data is! Map) {
      throw Exception('Unexpected status response type: ${res.data.runtimeType}\nBody: ${res.data}');
    }
    return JobStatusResponse.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<Uint8List> getResultBytes(String jobId) async {
    final res = await dio.get(
      '/result/$jobId',
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = _asBytes(res.data);

    // هل هو JSON؟
    final text = _tryUtf8(bytes);
    if (text != null && text.trimLeft().startsWith('{')) {
      final decoded = _tryJson(text);
      if (decoded is Map) {
        final rawUrl = (decoded['result_url'] ?? decoded['url'])?.toString();
        if (rawUrl == null || rawUrl.isEmpty) {
          throw Exception('result json missing result_url/url\nBody: $decoded');
        }

        final url = _makeAbsoluteIfNeeded(rawUrl);

        final fileRes = await dio.get(
          url,
          options: Options(responseType: ResponseType.bytes),
        );

        return _asBytes(fileRes.data);
      }
    }

    return bytes; // صورة مباشرة
  }

  Uint8List _asBytes(dynamic data) {
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    throw Exception('Unexpected bytes type: ${data.runtimeType}');
  }

  String _makeAbsoluteIfNeeded(String url) {
    // إذا رجع "/result-file/xxx.png" نخليه absolute باستخدام baseUrl
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (!url.startsWith('/')) return '${dio.options.baseUrl}/$url';
    return '${dio.options.baseUrl}$url';
  }

  String? _tryUtf8(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }

  dynamic _tryJson(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }
}