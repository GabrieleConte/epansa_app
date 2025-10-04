import 'package:flutter/foundation.dart';
import 'package:epansa_app/data/models/chat_message.dart';
import 'package:epansa_app/data/api/agent_api_client.dart';

/// Chat provider managing conversation state
class ChatProvider extends ChangeNotifier {
  final AgentApiClient _apiClient;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  PendingAction? _pendingAction;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  PendingAction? get pendingAction => _pendingAction;

  ChatProvider({AgentApiClient? apiClient})
      : _apiClient = apiClient ?? AgentApiClient(useMockData: true);

  /// Send a message and get response
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage.user(text);
    _messages.add(userMessage);
    notifyListeners();

    // Show loading
    _isLoading = true;
    notifyListeners();

    try {
      // Get response from agent
      final response = await _apiClient.sendMessage(text);

      // Check if response contains an action request
      if (response.startsWith('ACTION_REQUEST:')) {
        _handleActionRequest(response);
      } else {
        // Add assistant message
        final assistantMessage = ChatMessage.assistant(response);
        _messages.add(assistantMessage);
      }
    } catch (e) {
      // Add error message
      final errorMessage = ChatMessage.assistant(
        'Sorry, I encountered an error: ${e.toString()}',
        type: MessageType.error,
      );
      _messages.add(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle action request from agent
  void _handleActionRequest(String response) {
    final parts = response.split(':');
    if (parts.length < 3) return;

    final actionTypeStr = parts[1];
    final description = parts.sublist(2).join(':');

    ActionType actionType;
    switch (actionTypeStr) {
      case 'SEND_SMS':
        actionType = ActionType.sendSms;
        break;
      case 'MAKE_CALL':
        actionType = ActionType.makeCall;
        break;
      case 'SET_ALARM':
        actionType = ActionType.setAlarm;
        break;
      case 'CREATE_EVENT':
        actionType = ActionType.createEvent;
        break;
      default:
        actionType = ActionType.other;
    }

    // Create pending action
    _pendingAction = PendingAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      type: actionType,
      parameters: {},
    );

    // Add action request message
    final actionMessage = ChatMessage.assistant(
      description,
      type: MessageType.actionRequest,
      actionId: _pendingAction!.id,
    );
    _messages.add(actionMessage);
    notifyListeners();
  }

  /// Confirm pending action
  Future<void> confirmAction() async {
    if (_pendingAction == null) return;

    final action = _pendingAction!;
    _pendingAction = null;

    // Add confirmation message
    final confirmMessage = ChatMessage.assistant(
      'Action confirmed! Executing ${_getActionName(action.type)}...',
      type: MessageType.actionConfirmed,
    );
    _messages.add(confirmMessage);

    // Simulate action execution
    await Future.delayed(const Duration(seconds: 1));

    // Add success message
    final successMessage = ChatMessage.assistant(
      'Successfully completed the ${_getActionName(action.type)}!',
    );
    _messages.add(successMessage);

    notifyListeners();
  }

  /// Deny pending action
  void denyAction() {
    if (_pendingAction == null) return;

    final action = _pendingAction!;
    _pendingAction = null;

    // Add denial message
    final denyMessage = ChatMessage.assistant(
      'Action cancelled. I won\'t ${_getActionName(action.type)}.',
      type: MessageType.actionDenied,
    );
    _messages.add(denyMessage);

    notifyListeners();
  }

  String _getActionName(ActionType type) {
    switch (type) {
      case ActionType.sendSms:
        return 'send SMS';
      case ActionType.makeCall:
        return 'make call';
      case ActionType.setAlarm:
        return 'set alarm';
      case ActionType.createEvent:
        return 'create event';
      case ActionType.sendEmail:
        return 'send email';
      default:
        return 'perform action';
    }
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    _pendingAction = null;
    notifyListeners();
  }

  /// Add welcome message
  void addWelcomeMessage() {
    if (_messages.isEmpty) {
      final welcomeMessage = ChatMessage.assistant(
        "Hello! I'm EPANSA, your AI-powered assistant. "
        "I can help you with tasks, answer questions, and much more. "
        "How can I assist you today?",
      );
      _messages.add(welcomeMessage);
      notifyListeners();
    }
  }
}
