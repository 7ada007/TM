import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'monitoring_models.dart';

enum RealtimeStatus { disconnected, connecting, connected }

class RealtimeService extends ChangeNotifier {
  static const Duration _baseBackoff = Duration(seconds: 2);
  static const Duration _maxBackoff = Duration(seconds: 30);
  static const Duration _handshakeTimeout = Duration(seconds: 12);
  static const Duration _coalesceWindow = Duration(milliseconds: 120);
  static const Duration _heartbeatInterval = Duration(seconds: 10);

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _attempt = 0;
  bool _enabled = false;
  bool _connecting = false;

  RealtimeStatus _status = RealtimeStatus.disconnected;
  DateTime? _lastEventAt;
  final Map<String, ViewerState> _viewers = {};
  Timer? _coalesceTimer;
  List<ViewerState>? _sortedCache;
  int _revision = 0;

  RealtimeStatus get status => _status;
  bool get isConnected => _status == RealtimeStatus.connected;
  DateTime? get lastEventAt => _lastEventAt;
  int get revision => _revision;

  List<ViewerState> get viewers {
    final cached = _sortedCache;
    if (cached != null) return cached;
    final list = _viewers.values.toList()
      ..sort((a, b) {
        if (a.isWatching != b.isWatching) return a.isWatching ? -1 : 1;
        if (a.online != b.online) return a.online ? -1 : 1;
        return a.userName.compareTo(b.userName);
      });
    final result = List<ViewerState>.unmodifiable(list);
    _sortedCache = result;
    return result;
  }

  ViewerState? viewerFor(String userId) => _viewers[userId];

  int get onlineCount => _viewers.values.where((v) => v.online).length;
  int get watchingCount => _viewers.values.where((v) => v.isWatching).length;

  void _markDirty() {
    _sortedCache = null;
    _revision++;
  }

  void _scheduleNotify() {
    if (_coalesceTimer != null) return;
    _coalesceTimer = Timer(_coalesceWindow, () {
      _coalesceTimer = null;
      notifyListeners();
    });
  }

  static Uri _endpoint() {
    final base = Uri.parse(ApiClient.baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return base.replace(scheme: scheme, path: '${base.path}/realtime');
  }

  Future<void> start() async {
    if (_enabled) return;
    _enabled = true;
    await _connect();
  }

  Future<void> stop() async {
    _enabled = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _attempt = 0;
    await _teardown();
    _viewers.clear();
    _markDirty();
    _setStatus(RealtimeStatus.disconnected);
  }

  Future<void> _teardown() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        await socket.close(WebSocketStatus.normalClosure);
      } catch (_) {}
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _send(const {'type': 'heartbeat'});
    });
  }

  void _setStatus(RealtimeStatus value) {
    if (_status == value) return;
    _status = value;
    _markDirty();
    notifyListeners();
  }

  Future<void> _connect() async {
    if (!_enabled || _connecting || _socket != null) return;
    _connecting = true;
    _setStatus(RealtimeStatus.connecting);

    try {
      final token = await ApiClient.getToken();
      if (token == null || token.isEmpty) {
        _connecting = false;
        _setStatus(RealtimeStatus.disconnected);
        return;
      }

      final socket = await WebSocket.connect(
        _endpoint().toString(),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(_handshakeTimeout);

      if (!_enabled) {
        await socket.close(WebSocketStatus.normalClosure);
        _connecting = false;
        return;
      }

      socket.pingInterval = const Duration(seconds: 15);
      _socket = socket;
      _attempt = 0;
      _connecting = false;
      _setStatus(RealtimeStatus.connected);
      _startHeartbeat();

      _subscription = socket.listen(
        _onData,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _connecting = false;
      _socket = null;
      _setStatus(RealtimeStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _handleDisconnect() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _socket = null;
    _subscription = null;
    for (final entry in _viewers.entries.toList()) {
      _viewers[entry.key] = _offline(entry.value);
    }
    _markDirty();
    _setStatus(RealtimeStatus.disconnected);
    notifyListeners();
    _scheduleReconnect();
  }

  ViewerState _offline(ViewerState v) {
    return ViewerState(
      userId: v.userId,
      userName: v.userName,
      section: v.section,
      online: false,
      lectureId: v.lectureId,
      lectureTitle: v.lectureTitle,
      lectureSubject: v.lectureSubject,
      playing: false,
      positionSeconds: v.positionSeconds,
      durationSeconds: v.durationSeconds,
      watchedSeconds: v.watchedSeconds,
      percent: v.percent,
      completed: v.completed,
      startedAt: v.startedAt,
      lastSeenAt: v.lastSeenAt,
    );
  }

  void _scheduleReconnect() {
    if (!_enabled || _reconnectTimer != null) return;
    final millis = (_baseBackoff.inMilliseconds * (1 << _attempt)).clamp(
      _baseBackoff.inMilliseconds,
      _maxBackoff.inMilliseconds,
    );
    if (_attempt < 6) _attempt++;
    _reconnectTimer = Timer(Duration(milliseconds: millis), () {
      _reconnectTimer = null;
      _connect();
    });
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    Map<String, dynamic> decoded;
    try {
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic>) return;
      decoded = value;
    } catch (_) {
      return;
    }

    switch (decoded['type']) {
      case 'snapshot':
        final list = decoded['viewers'];
        _viewers.clear();
        if (list is List) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final viewer = ViewerState.fromJson(item);
              if (viewer.userId.isNotEmpty) _viewers[viewer.userId] = viewer;
            }
          }
        }
        _lastEventAt = DateTime.now();
        _markDirty();
        _scheduleNotify();

      case 'presence':
      case 'activity':
        final item = decoded['viewer'];
        if (item is Map<String, dynamic>) {
          final viewer = ViewerState.fromJson(item);
          if (viewer.userId.isNotEmpty) {
            _viewers[viewer.userId] = viewer;
            _lastEventAt = DateTime.now();
            _markDirty();
            _scheduleNotify();
          }
        }
    }
  }

  bool _send(Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) return false;
    try {
      socket.add(jsonEncode(payload));
      return true;
    } catch (_) {
      return false;
    }
  }

  bool reportProgress({
    required String lectureId,
    required String lectureTitle,
    required String lectureSubject,
    required double positionSeconds,
    required double durationSeconds,
    required double watchedDeltaSeconds,
    required bool playing,
    required bool completed,
  }) {
    return _send({
      'type': 'progress',
      'lectureId': lectureId,
      'lectureTitle': lectureTitle,
      'lectureSubject': lectureSubject,
      'positionSeconds': positionSeconds,
      'durationSeconds': durationSeconds,
      'watchedDeltaSeconds': watchedDeltaSeconds,
      'playing': playing,
      'completed': completed,
    });
  }

  bool reportStopped(String lectureId) {
    return _send({'type': 'stopped', 'lectureId': lectureId});
  }

  Future<void> flushProgress({
    required String lectureId,
    required double positionSeconds,
    required double durationSeconds,
    required double watchedDeltaSeconds,
    required bool completed,
  }) async {
    try {
      await ApiClient.dio.post(
        '/progress',
        data: {
          'lectureId': lectureId,
          'positionSeconds': positionSeconds,
          'durationSeconds': durationSeconds,
          'watchedDeltaSeconds': watchedDeltaSeconds,
          'completed': completed,
        },
      );
    } catch (_) {}
  }

  Future<List<LectureProgressRecord>> fetchProgress({
    String? lectureId,
    String? userId,
  }) async {
    final response = await ApiClient.dio.get(
      '/monitoring/progress',
      queryParameters: {'lectureId': ?lectureId, 'userId': ?userId},
    );
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(LectureProgressRecord.fromJson)
        .toList();
  }

  @override
  void dispose() {
    _enabled = false;
    _reconnectTimer?.cancel();
    _coalesceTimer?.cancel();
    _heartbeatTimer?.cancel();
    unawaited(_teardown());
    super.dispose();
  }
}
