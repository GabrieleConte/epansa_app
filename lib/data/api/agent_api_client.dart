import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:epansa_app/core/config/app_config.dart';

/// Mock Agent API Client
/// This provides mock responses for testing without a real backend
class AgentApiClient {
  final String baseUrl;
  final String apiKey;
  final bool useMockData;

  AgentApiClient({
    String? baseUrl,
    String? apiKey,
    this.useMockData = true,
  })  : baseUrl = baseUrl ?? AppConfig.agentApiBaseUrl,
        apiKey = apiKey ?? AppConfig.agentApiKey;

  /// Send a message to the agent and get a response
  Future<String> sendMessage(String message) async {
    if (useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      return _getMockResponse(message);
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No response received';
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
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
