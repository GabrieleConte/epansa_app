/// Chat API models matching backend Pydantic schemas
/// These models are used for communication with the EPANSA backend chat endpoint

/// Chat payload matching backend ChatPayload
class ChatPayload {
  final String text;

  ChatPayload({
    required this.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }

  factory ChatPayload.fromJson(Map<String, dynamic> json) {
    return ChatPayload(
      text: json['text'] as String,
    );
  }
}

/// Chat response from backend
/// The backend's process_user_command returns a dictionary with the response
class ChatResponse {
  final String? response;
  final String? action;
  final Map<String, dynamic>? actionData;
  final String? error;

  ChatResponse({
    this.response,
    this.action,
    this.actionData,
    this.error,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'] as String?,
      action: json['action'] as String?,
      actionData: json['action_data'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'response': response,
      'action': action,
      'action_data': actionData,
      'error': error,
    };
  }

  /// Check if the response contains an action request
  bool get hasAction => action != null && action!.isNotEmpty;

  /// Check if the response has an error
  bool get hasError => error != null && error!.isNotEmpty;

  /// Get the response text (either response or error)
  String get text => response ?? error ?? 'No response received';
}
