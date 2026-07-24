import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../../core/api_data_service.dart';

const String _assistantGreeting =
    'مرحباً بك في معهد طريق المجد! أنا دليل المجد، مساعدك الذكي. كيف يمكنني مساعدتك اليوم؟';

const int _maxHistoryTurns = 20;

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AssistantService extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _disposed = false;
  String? _pendingRetry;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get canRetry => _pendingRetry != null && !_isTyping;

  AssistantService() {
    _messages.add(ChatMessage(text: _assistantGreeting, isUser: false));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  List<Map<String, String>> _buildPriorTurns() {
    final history = <Map<String, String>>[];
    for (final message in _messages) {
      if (message.isError) continue;
      history.add({
        'role': message.isUser ? 'user' : 'model',
        'text': message.text,
      });
    }

    if (history.isNotEmpty && history.last['role'] == 'user') {
      history.removeLast();
    }
    while (history.isNotEmpty && history.first['role'] != 'user') {
      history.removeAt(0);
    }
    if (history.length > _maxHistoryTurns) {
      return history.sublist(history.length - _maxHistoryTurns);
    }
    return history;
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _messages.add(ChatMessage(text: trimmed, isUser: true));
    await _dispatch(trimmed);
  }

  Future<void> retryLast() async {
    final pending = _pendingRetry;
    if (pending == null || _isTyping) return;

    _messages.removeWhere((m) => m.isError);
    await _dispatch(pending);
  }

  Future<void> _dispatch(String message) async {
    _pendingRetry = null;
    _isTyping = true;
    _safeNotify();

    final history = _buildPriorTurns();

    try {
      final response = await ApiClient.dio.post(
        '/assistant/chat',
        data: {'message': message, 'history': history},
      );

      final data = response.data;
      final reply = data is Map<String, dynamic>
          ? (data['reply'] as String?)?.trim()
          : null;

      if (reply == null || reply.isEmpty) {
        _appendError('لم أتمكّن من صياغة إجابة، يرجى إعادة المحاولة', message);
      } else {
        _messages.add(ChatMessage(text: reply, isUser: false));
      }
    } on DioException catch (e) {
      _appendError(_assistantError(e), message);
    } catch (_) {
      _appendError('حدث خطأ غير متوقع، يرجى إعادة المحاولة', message);
    } finally {
      _isTyping = false;
      _safeNotify();
    }
  }

  void _appendError(String message, String retryPrompt) {
    _pendingRetry = retryPrompt;
    _messages.add(ChatMessage(text: message, isUser: false, isError: true));
  }

  String _assistantError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final serverMessage = (data['error'] as String?)?.trim();
      if (serverMessage != null && serverMessage.isNotEmpty) {
        return serverMessage;
      }
    }
    if (status == 503) {
      return 'خدمة المساعد الذكي غير مفعّلة حالياً، يرجى مراجعة إدارة المعهد';
    }
    return friendlyNetworkError(e);
  }
}
