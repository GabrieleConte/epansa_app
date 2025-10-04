import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:epansa_app/data/models/chat_message.dart';
import 'package:epansa_app/data/api/agent_api_client.dart';
import 'package:epansa_app/services/alarm_service.dart';
import 'package:epansa_app/services/calendar_event_service.dart';

/// Chat provider managing conversation state
class ChatProvider extends ChangeNotifier {
  final AgentApiClient _apiClient;
  final AlarmService? _alarmService;
  final CalendarEventService? _calendarEventService;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  PendingAction? _pendingAction;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  PendingAction? get pendingAction => _pendingAction;

  ChatProvider({
    AgentApiClient? apiClient,
    AlarmService? alarmService,
    CalendarEventService? calendarEventService,
  })  : _apiClient = apiClient ?? AgentApiClient(useMockData: true),
        _alarmService = alarmService,
        _calendarEventService = calendarEventService;

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
      // Check for prototype commands
      if (text.toLowerCase().trim() == 'set_event') {
        _isLoading = false;
        _handleSetEventCommand();
        return;
      }

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

  /// Handle set_event prototype command
  void _handleSetEventCommand() {
    // Mock agent response for calendar event creation
    final agentMessage = ChatMessage.assistant(
      'I can help you create a calendar event! 📅\n\n'
      'I\'d like to schedule:\n'
      '• Event: EPANSA Meeting\n'
      '• Date: Today\n'
      '• Time: 2:00 PM - 3:00 PM\n'
      '• Location: Office\n\n'
      'Would you like me to create this event?',
      type: MessageType.actionRequest,
      actionId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _messages.add(agentMessage);

    // Create pending action for calendar event
    _pendingAction = PendingAction(
      id: agentMessage.actionId!,
      description: 'Create calendar event: EPANSA Meeting',
      type: ActionType.createEvent,
      parameters: {
        'title': 'EPANSA Meeting',
        'description': 'Meeting created by EPANSA assistant',
        'duration': 60, // minutes
        'location': 'Office',
      },
    );

    _isLoading = false;
    notifyListeners();
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
      case 'SET_EVENT':
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
    notifyListeners();

    // Execute the action
    bool success = false;
    String resultMessage = '';

    try {
      if (action.type == ActionType.setAlarm && _alarmService != null) {
        // Check notification permissions first
        final hasPermission = await _alarmService.hasNotificationPermission();
        
        if (!hasPermission) {
          // Permissions not granted - inform user
          resultMessage = '⚠️ Notification Permission Required\n\n'
              'To set alarms, please enable notifications:\n\n'
              '1. Go to iPhone Settings\n'
              '2. Find "Epansa App"\n'
              '3. Tap "Notifications"\n'
              '4. Enable "Allow Notifications"\n\n'
              '💡 Then try setting the alarm again!';
          success = false;
        } else {
          // Create alarm at 7:01 AM (test mode: fires in 10 seconds)
          final alarmTime = const TimeOfDay(hour: 7, minute: 1);
          success = await _alarmService.createAlarm(
            label: 'EPANSA Alarm',
            time: alarmTime,
            repeatDays: [], // One-time alarm
            testMode: true, // Test mode: alarm fires in 10 seconds
          );
          
          if (success) {
            final alarmCount = _alarmService.alarms.length;
            resultMessage = '✅ Alarm set successfully! 🔔\n\n'
                '⏰ TEST MODE: Will ring in 10 SECONDS\n\n'
                'You now have $alarmCount alarm(s) scheduled.\n\n'
                '📱 How to stop the alarm:\n'
                '• On iOS: Tap the notification to open the stop screen\n'
                '• On Android: Use the "Stop" button in the notification\n'
                '• Or: Open the app when it rings\n\n'
                '⚠️ Works even when app is closed!';
          } else {
            resultMessage = '❌ Failed to set alarm. Please check notification permissions in Settings.';
          }
        }
      } else if (action.type == ActionType.createEvent && _calendarEventService != null) {
        debugPrint('🔵 ChatProvider: Creating calendar event...');
        
        // Create calendar event for today
        // The createEvent method will handle permission requests internally
        final now = DateTime.now();
        final startTime = DateTime(now.year, now.month, now.day, 14, 0); // 2 PM today
        final endTime = startTime.add(const Duration(hours: 1)); // 1 hour duration
        
        debugPrint('🔵 ChatProvider: Calling createEvent...');
        final eventId = await _calendarEventService.createEvent(
          title: 'EPANSA Meeting',
          description: 'Meeting created by EPANSA assistant',
          startTime: startTime,
          endTime: endTime,
          location: 'Office',
        );
        debugPrint('🔵 ChatProvider: createEvent returned: $eventId');
        
        success = eventId != null;
        
        if (success) {
          resultMessage = '✅ Calendar event created successfully! 📅\n\n'
              'Event: EPANSA Meeting\n'
              'Date: Today\n'
              'Time: 2:00 PM - 3:00 PM\n'
              'Location: Office\n\n'
              '💡 Check your calendar app to see the event!';
        } else {
          // Check if permission was denied
          final hasPermission = await _calendarEventService.hasCalendarPermission();
          if (!hasPermission) {
            resultMessage = '⚠️ Calendar Permission Required\n\n'
                'To create calendar events, please enable calendar access:\n\n'
                '1. Go to iPhone Settings\n'
                '2. Find "Epansa App"\n'
                '3. Tap "Calendars"\n'
                '4. Enable calendar access\n\n'
                '💡 Then try creating the event again!';
          } else {
            resultMessage = '❌ Failed to create calendar event. Please try again.';
          }
        }
      } else {
        // Other action types - simulate execution
        await Future.delayed(const Duration(seconds: 1));
        success = true;
        resultMessage = 'Successfully completed the ${_getActionName(action.type)}!';
      }
    } catch (e) {
      debugPrint('❌ Error executing action: $e');
      success = false;
      resultMessage = 'Failed to execute action: $e';
    }

    // Note: Calendar events are now handled server-side via Google Calendar API

    // Add result message
    final resultMsg = ChatMessage.assistant(resultMessage);
    _messages.add(resultMsg);

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
