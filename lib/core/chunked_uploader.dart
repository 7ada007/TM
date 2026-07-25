import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

abstract final class ChunkedUploader {
  static const int chunkSize = 4 * 1024 * 1024;
  static const int _maxAttemptsPerChunk = 4;
  static const String _manifestPrefix = 'chunked_upload::';

  static const int _concurrentChunks = 3;

  static Future<String> upload(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final fileSize = await file.length();

    if (fileSize <= chunkSize) {
      return ApiClient.uploadFile(file, onProgress: onProgress);
    }

    final fileName = file.path.split(Platform.pathSeparator).last;
    final totalChunks = (fileSize / chunkSize).ceil();
    final prefs = await SharedPreferences.getInstance();
    final manifestKey = await _manifestKeyFor(file, fileSize);

    final session = await _resumeOrStartSession(
      prefs: prefs,
      manifestKey: manifestKey,
      fileName: fileName,
      fileSize: fileSize,
      totalChunks: totalChunks,
    );

    var uploadedBytes = session.received.fold<int>(
      0,
      (sum, idx) => sum + _chunkLength(idx, fileSize),
    );
    onProgress?.call(fileSize == 0 ? 1.0 : uploadedBytes / fileSize);

    final missing = [
      for (var i = 0; i < totalChunks; i++)
        if (!session.received.contains(i)) i,
    ];

    for (var start = 0; start < missing.length; start += _concurrentChunks) {
      final batch = missing.skip(start).take(_concurrentChunks);
      await Future.wait(
        batch.map((index) async {
          final length = _chunkLength(index, fileSize);
          final bytes = await _readChunk(file, index * chunkSize, length);
          await _withRetry(() => _uploadChunk(session.uploadId, index, bytes));
          uploadedBytes += length;
          onProgress?.call(uploadedBytes / fileSize);
        }),
      );
    }

    final url = await _withRetry(() => _completeSession(session.uploadId));
    await prefs.remove(manifestKey);
    return url;
  }

  static int _chunkLength(int index, int fileSize) {
    final offset = index * chunkSize;
    return math.min(chunkSize, fileSize - offset);
  }

  static Future<Uint8List> _readChunk(File file, int offset, int length) async {
    final builder = BytesBuilder(copy: false);
    await for (final part in file.openRead(offset, offset + length)) {
      builder.add(part);
    }
    return builder.takeBytes();
  }

  static Future<_UploadSession> _resumeOrStartSession({
    required SharedPreferences prefs,
    required String manifestKey,
    required String fileName,
    required int fileSize,
    required int totalChunks,
  }) async {
    final existing = prefs.getString(manifestKey);
    if (existing != null) {
      try {
        final decoded = jsonDecode(existing) as Map<String, dynamic>;
        final uploadId = decoded['uploadId'] as String;
        final response = await ApiClient.dio.get(
          '/uploads/chunked/$uploadId/status',
        );
        final receivedList = (response.data['receivedChunks'] as List?) ?? [];
        return _UploadSession(
          uploadId: uploadId,
          received: receivedList.map((e) => e as int).toSet(),
        );
      } catch (_) {
        await prefs.remove(manifestKey);
      }
    }

    final uploadId = await _withRetry(
      () => _initSession(fileName, fileSize, totalChunks),
    );
    await prefs.setString(manifestKey, jsonEncode({'uploadId': uploadId}));
    return _UploadSession(uploadId: uploadId, received: <int>{});
  }

  static Future<String> _initSession(
    String fileName,
    int fileSize,
    int totalChunks,
  ) async {
    final response = await ApiClient.dio.post(
      '/uploads/chunked/init',
      data: {
        'fileName': fileName,
        'fileSize': fileSize,
        'totalChunks': totalChunks,
      },
    );
    final uploadId = response.data['uploadId'] as String?;
    if (uploadId == null || uploadId.isEmpty) {
      throw Exception('تعذّر بدء جلسة الرفع');
    }
    return uploadId;
  }

  static Future<void> _uploadChunk(
    String uploadId,
    int index,
    Uint8List bytes,
  ) async {
    final formData = FormData.fromMap({
      'chunk': MultipartFile.fromBytes(bytes, filename: '$index.part'),
    });
    await ApiClient.dio.post(
      '/uploads/chunked/$uploadId/chunk/$index',
      data: formData,
    );
  }

  static Future<String> _completeSession(String uploadId) async {
    final response = await ApiClient.dio.post(
      '/uploads/chunked/$uploadId/complete',
    );
    final url = response.data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('استجابة رفع غير صالحة من الخادم');
    }
    return url;
  }

  static Future<T> _withRetry<T>(Future<T> Function() action) async {
    for (var attempt = 0; attempt < _maxAttemptsPerChunk; attempt++) {
      try {
        return await action();
      } catch (_) {
        if (attempt == _maxAttemptsPerChunk - 1) rethrow;
        final delayMs = math.min(400 * (1 << attempt), 4000);
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    throw StateError('unreachable');
  }

  static Future<String> _manifestKeyFor(File file, int fileSize) async {
    final stat = await file.stat();
    return '$_manifestPrefix${file.path}::$fileSize::'
        '${stat.modified.millisecondsSinceEpoch}';
  }
}

class _UploadSession {
  final String uploadId;
  final Set<int> received;

  const _UploadSession({required this.uploadId, required this.received});
}
