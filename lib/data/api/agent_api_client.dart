import 'package:dio/dio.dart';
import 'package:epansa_app/core/config/app_config.dart';
import 'package:epansa_app/data/models/api/alarm_api_models.dart';
import 'package:epansa_app/data/models/api/contact_api_models.dart';
import 'package:epansa_app/data/models/api/phone_call_api_models.dart';
import 'package:epansa_app/data/repositories/alarm_repository.dart';
import 'package:epansa_app/data/repositories/contact_repository.dart';
import 'package:epansa_app/data/repositories/phone_call_repository.dart';
import 'package:epansa_app/services/auth_service.dart';

/// Agent API Client
/// Handles communication with the EPANSA backend
class AgentApiClient {
  final String baseUrl;
  final AuthService authService;
  final AlarmRepository alarmRepository;
  final ContactRepository contactRepository;
  final PhoneCallRepository phoneCallRepository;
  final Dio _dio;
  final bool useMockData;

  AgentApiClient({
    String? baseUrl,
    required this.authService,
    required this.alarmRepository,
    required this.contactRepository,
    required this.phoneCallRepository,
    this.useMockData = true,
  })  : baseUrl = baseUrl ?? AppConfig.agentApiBaseUrl,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? AppConfig.agentApiBaseUrl,
          connectTimeout: const Duration(seconds: 10000),
          receiveTimeout: const Duration(seconds: 10000),
        ));

  /// Send a message to the agent and get a response
  Future<String> sendMessage(String message) async {
    if (useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      return _getMockResponse(message);
    }

    try {
      final headers = await authService.getAuthHeaders();
      
      final response = await _dio.post(
        '/chat',
        data: {
          'text': message, // Backend expects 'text' field based on ChatPayload schema
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['response'] ?? 'No response received';
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error communicating with agent: $e');
    }
  }

  /// Get mock response based on message content
  String _getMockResponse(String message) {
    final lowerMessage = message.toLowerCase();

    // Check for greetings
    if (lowerMessage.contains('hello') || 
        lowerMessage.contains('hi') || 
        lowerMessage.contains('hey')) {
      return "Hello! I'm EPANSA, your AI assistant. How can I help you today?";
    }

    // Check for help requests
    if (lowerMessage.contains('help') || lowerMessage.contains('what can you do')) {
      return "I can help you with:\n"
          "• Managing your calendar and events\n"
          "• Sending messages and making calls\n"
          "• Setting alarms and reminders\n"
          "• Searching the web\n"
          "• And much more! Just ask me anything.";
    }

    // Check for action requests that need confirmation
    if (lowerMessage.contains('send') && lowerMessage.contains('sms')) {
      return "ACTION_REQUEST:SEND_SMS:Would you like me to send an SMS? Please confirm.";
    }

    if (lowerMessage.contains('call')) {
      return "ACTION_REQUEST:MAKE_CALL:Would you like me to make a call? Please confirm.";
    }

    // Check for alarm actions
    if (lowerMessage.contains('set alarm') || lowerMessage.contains('set an alarm') || 
        (lowerMessage.contains('alarm') && (lowerMessage.contains('set') || lowerMessage.contains('create')))) {
      return "ACTION_REQUEST:SET_ALARM:Would you like me to set an alarm? Please confirm.";
    }

    // Check for alarm queries
    if (lowerMessage.contains('alarm') || lowerMessage.contains('my alarms') || lowerMessage.contains('show alarm')) {
      return "Here are your current alarms:\n"
          "⏰ 7:00 AM - Wake up (Mon-Fri)\n"
          "⏰ 8:30 AM - Gym reminder (Mon, Wed, Fri)\n"
          "⏰ 10:00 PM - Bedtime reminder (Daily)\n\n"
          "Would you like me to add, remove, or modify any alarms?";
    }

    // Check for call history queries
    if (lowerMessage.contains('call') && (lowerMessage.contains('history') || lowerMessage.contains('log') || 
        lowerMessage.contains('recent') || lowerMessage.contains('last'))) {
      return "Here are your recent calls:\n"
          "📞 Mom - Outgoing, 5 min ago (3:24 duration)\n"
          "📞 John Smith - Incoming, 2 hours ago (10:15 duration)\n"
          "📞 Unknown Number - Missed, Yesterday at 4:32 PM\n"
          "📞 Office - Outgoing, Yesterday at 2:10 PM (45:20 duration)\n\n"
          "I've synced your complete call history with the server.";
    }

    if (lowerMessage.contains('event') || lowerMessage.contains('meeting')) {
      return "ACTION_REQUEST:CREATE_EVENT:Would you like me to create a calendar event? Please confirm.";
    }

    // Check for calendar queries
    if (lowerMessage.contains('calendar') || lowerMessage.contains('schedule')) {
      return "Let me check your calendar... You have 2 events today:\n"
          "📅 10:00 AM - Team meeting\n"
          "📅 1:00 PM - Lunch with Sarah";
    }

    // Check for weather
    if (lowerMessage.contains('weather')) {
      return "The weather today is sunny with a high of 72°F (22°C). Perfect day to go outside! ☀️";
    }

    // Check for time
    if (lowerMessage.contains('time') || lowerMessage.contains('what time')) {
      final now = DateTime.now();
      return "The current time is ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
    }

    // Check for thanks
    if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      return "You're welcome! Let me know if you need anything else. 😊";
    }

    // Default response
    return "I understand you said: \"$message\"\n\n"
        "I'm currently in demo mode with mock responses. In the full version, "
        "I'll be able to help you with a wide range of tasks using AI!";
  }

  /// Check agent health
  Future<bool> checkHealth() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }

    try {
      final response = await _dio.get('/healthz');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // Alarm API Methods
  // ========================================

  /// Add a new alarm to the backend
  Future<void> addAlarm(AlarmPayload alarmPayload) async {
    try {
      final headers = await authService.getAuthHeaders();
      print('🔍 Adding alarm with headers: ${headers.keys}');
      print('🔍 Authorization header present: ${headers.containsKey("Authorization")}');
      
      final response = await _dio.post(
        '/add_alarm',
        data: alarmPayload.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add alarm: ${response.statusCode}');
      }

      print('✅ Alarm added to backend: ${alarmPayload.alarm}');
    } catch (e) {
      print('❌ Error adding alarm to backend: $e');
      rethrow;
    }
  }

  /// Update an existing alarm on the backend
  Future<void> updateAlarm(AlarmPayload alarmPayload) async {
    try {
      final headers = await authService.getAuthHeaders();
      
      final response = await _dio.post(
        '/update_alarm',
        data: alarmPayload.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update alarm: ${response.statusCode}');
      }

      print('✅ Alarm updated on backend: ${alarmPayload.alarm}');
    } catch (e) {
      print('❌ Error updating alarm on backend: $e');
      rethrow;
    }
  }

  /// Delete an alarm from the backend
  Future<void> deleteAlarm(String alarmId) async {
    try {
      final headers = await authService.getAuthHeaders();
      
      // Fetch the alarm from repository to determine if it's recurrent
      final alarm = await alarmRepository.getAlarm(alarmId);
      final isRecurrent = alarm?.repeatFrequency != null && 
                          alarm!.repeatFrequency != 'once' && 
                          alarm.repeatFrequency!.isNotEmpty;
      final recurrenceType = isRecurrent ? 'recurrent' : 'single-occurrence';
      
      final deletePayload = DeletePayload(
        id: alarmId,
        sourceApp: 'epansa_app',
        metadata: {
          'kind': 'alarm',
          'recurrence_type': recurrenceType,
        },
      );

      final response = await _dio.post(
        '/delete_alarm',
        data: deletePayload.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to delete alarm: ${response.statusCode}');
      }

      print('✅ Alarm deleted from backend: $alarmId (type: $recurrenceType)');
    } catch (e) {
      print('❌ Error deleting alarm from backend: $e');
      rethrow;
    }
  }

  // ========================================
  // Contact API Methods
  // ========================================

  /// Add a new contact to the backend
  Future<void> addContact(ContactPayload contactPayload) async {
    try {
      final headers = await authService.getAuthHeaders();
      print('🔍 Adding contact with headers: ${headers.keys}');
      
      final response = await _dio.post(
        '/add_contact',
        data: contactPayload.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add contact: ${response.statusCode}');
      }

      print('✅ Contact added to backend: ${contactPayload.contact} (${contactPayload.metadata.name})');
    } catch (e) {
      print('❌ Error adding contact to backend: $e');
      rethrow;
    }
  }

  /// Update an existing contact on the backend
  Future<void> updateContact(ContactPayload contactPayload) async {
    try {
      final headers = await authService.getAuthHeaders();
      
      final response = await _dio.post(
        '/update_contact',
        data: contactPayload.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update contact: ${response.statusCode}');
      }

      print('✅ Contact updated on backend: ${contactPayload.contact} (${contactPayload.metadata.name})');
    } catch (e) {
      print('❌ Error updating contact on backend: $e');
      rethrow;
    }
  }

  /// Delete a contact from the backend
  Future<void> deleteContact(String contactId) async {
    try {
      final headers = await authService.getAuthHeaders();
      
      final deletePayload = DeletePayload(
        id: contactId,
        sourceApp: 'epansa_app',
        metadata: {
          'kind': 'contact',
        },
      );

      final response = await _dio.post(
        '/delete_contact',
        data: deletePayload.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to delete contact: ${response.statusCode}');
      }

      print('✅ Contact deleted from backend: $contactId');
    } catch (e) {
      print('❌ Error deleting contact from backend: $e');
      rethrow;
    }
  }

  /// Sync all contacts to backend (bulk operation)
  /// This is used for initial sync and periodic background sync
  Future<void> syncContactsToBackend(List<ContactPayload> contacts) async {
    if (contacts.isEmpty) {
      print('ℹ️ No contacts to sync');
      return;
    }

    print('🔄 Syncing ${contacts.length} contacts to backend...');
    int successCount = 0;
    int errorCount = 0;

    for (var contact in contacts) {
      try {
        await addContact(contact);
        successCount++;
      } catch (e) {
        errorCount++;
        print('⚠️ Failed to sync contact ${contact.metadata.name}: $e');
        // Continue with next contact instead of stopping entire sync
      }
    }

    print('✅ Contact sync completed: $successCount succeeded, $errorCount failed');
  }

  // ========================================
  // Phone Call API Methods
  // ========================================

  /// Add a new phone call to the backend
  Future<void> addPhoneCall(PhoneCallPayload phoneCallPayload) async {
    try {
      final headers = await authService.getAuthHeaders();
      print('🔍 Adding phone call with headers: ${headers.keys}');
      
      final response = await _dio.post(
        '/add_telephone',
        data: phoneCallPayload.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add phone call: ${response.statusCode}');
      }

      print('✅ Phone call added to backend: ${phoneCallPayload.call} (${phoneCallPayload.metadata.callDirection})');
    } catch (e) {
      print('❌ Error adding phone call to backend: $e');
      rethrow;
    }
  }

  /// Delete a phone call from the backend
  Future<void> deletePhoneCall(String callId) async {
    try {
      final headers = await authService.getAuthHeaders();
      
      final deletePayload = DeletePayload(
        id: callId,
        sourceApp: 'epansa_app',
        metadata: {
          'kind': 'call',
        },
      );

      final response = await _dio.post(
        '/delete_telephone',
        data: deletePayload.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to delete phone call: ${response.statusCode}');
      }

      print('✅ Phone call deleted from backend: $callId');
    } catch (e) {
      print('❌ Error deleting phone call from backend: $e');
      rethrow;
    }
  }

  /// Sync all phone calls to backend (bulk operation)
  /// This is used for initial sync and periodic background sync
  Future<void> syncPhoneCallsToBackend(List<PhoneCallPayload> calls) async {
    if (calls.isEmpty) {
      print('ℹ️ No phone calls to sync');
      return;
    }

    print('🔄 Syncing ${calls.length} phone calls to backend...');
    int successCount = 0;
    int errorCount = 0;

    for (var call in calls) {
      try {
        await addPhoneCall(call);
        successCount++;
      } catch (e) {
        errorCount++;
        print('⚠️ Failed to sync phone call ${call.call}: $e');
        // Continue with next call instead of stopping entire sync
      }
    }

    print('✅ Phone call sync completed: $successCount succeeded, $errorCount failed');
  }
}
