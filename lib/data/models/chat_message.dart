/// Message model for chat
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final String? actionId; // For messages requiring confirmation

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.actionId,
  });

  factory ChatMessage.user(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(String text, {MessageType? type, String? actionId}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      type: type ?? MessageType.text,
      actionId: actionId,
    );
  }
}

enum MessageType {
  text,
  actionRequest, // Requires user confirmation
  actionConfirmed,
  actionDenied,
  error,
}

/// Pending action model for user confirmation
class PendingAction {
  final String id;
  final String description;
  final ActionType type;
  final Map<String, dynamic> parameters;

  PendingAction({
    required this.id,
    required this.description,
    required this.type,
    required this.parameters,
  });
}

enum ActionType {
  sendSms,
  makeCall,
  setAlarm,
  createEvent,
  sendEmail,
  other,
}
