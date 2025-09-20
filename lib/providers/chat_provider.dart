import 'package:flutter/foundation.dart';

class ChatProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _messages = [];

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);

  void addMessage(Map<String, dynamic> message) {
    _messages.add(message);
    notifyListeners();
  }
}
