import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class AssistantService extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  AssistantService() {
    _messages.add(
      ChatMessage(
        text: 'مرحباً بك في معهد طريق المجد! كيف يمكنني مساعدتك اليوم؟',
        isUser: false,
      ),
    );
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(text: text, isUser: true));
    _isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _isTyping = false;
    _messages.add(
      ChatMessage(
        text:
            'هذا رد تجريبي من دليل المجد. يرجى ربط مفتاح Gemini API لتفعيل الذكاء الاصطناعي بالكامل.',
        isUser: false,
      ),
    );
    notifyListeners();
  }
}
