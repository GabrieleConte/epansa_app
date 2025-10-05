import 'package:json_annotation/json_annotation.dart';

part 'agent_response.g.dart';

/// Response from the AI agent server
@JsonSerializable()
class AgentResponse {
  /// Human-readable message from the agent
  final String message;

  /// Action intent that needs to be executed
  final ActionIntent? action;

  /// Metadata about the response
  final Map<String, dynamic>? metadata;

  AgentResponse({
    required this.message,
    this.action,
    this.metadata,
  });

  factory AgentResponse.fromJson(Map<String, dynamic> json) =>
      _$AgentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AgentResponseToJson(this);
}

/// Action intent from the agent - tells the app what to do
@JsonSerializable()
class ActionIntent {
  /// Type of action to perform
  final ActionType type;

  /// Parameters specific to this action
  final Map<String, dynamic> parameters;

  /// Whether user confirmation is required before execution
  final bool requiresConfirmation;

  /// Confirmation prompt to show the user
  final String? confirmationPrompt;

  ActionIntent({
    required this.type,
    required this.parameters,
    this.requiresConfirmation = true,
    this.confirmationPrompt,
  });

  factory ActionIntent.fromJson(Map<String, dynamic> json) =>
      _$ActionIntentFromJson(json);

  Map<String, dynamic> toJson() => _$ActionIntentToJson(this);
}

/// Types of actions the app can perform
enum ActionType {
  @JsonValue('set_alarm')
  setAlarm,

  @JsonValue('set_event')
  setEvent,

  @JsonValue('send_sms')
  sendSms,

  @JsonValue('make_call')
  makeCall,

  @JsonValue('search')
  search,

  @JsonValue('unknown')
  unknown,
}

/// User's response to a confirmation request
@JsonSerializable()
class UserConfirmation {
  /// ID of the action being confirmed
  final String actionId;

  /// Whether the user approved the action
  final bool approved;

  /// Optional user modifications to parameters
  final Map<String, dynamic>? modifiedParameters;

  UserConfirmation({
    required this.actionId,
    required this.approved,
    this.modifiedParameters,
  });

  factory UserConfirmation.fromJson(Map<String, dynamic> json) =>
      _$UserConfirmationFromJson(json);

  Map<String, dynamic> toJson() => _$UserConfirmationToJson(this);
}

/// Event parameters for calendar actions
@JsonSerializable()
class EventParameters {
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final List<String>? attendees;

  EventParameters({
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.attendees,
  });

  factory EventParameters.fromJson(Map<String, dynamic> json) =>
      _$EventParametersFromJson(json);

  Map<String, dynamic> toJson() => _$EventParametersToJson(this);
}

/// Alarm parameters for alarm actions
@JsonSerializable()
class AlarmParameters {
  final String label;
  final DateTime time;
  final List<int>? repeatDays;
  final bool vibrate;

  AlarmParameters({
    required this.label,
    required this.time,
    this.repeatDays,
    this.vibrate = true,
  });

  factory AlarmParameters.fromJson(Map<String, dynamic> json) =>
      _$AlarmParametersFromJson(json);

  Map<String, dynamic> toJson() => _$AlarmParametersToJson(this);
}

/// SMS parameters for SMS actions
@JsonSerializable()
class SmsParameters {
  final String phoneNumber;
  final String message;
  final String? contactName;

  SmsParameters({
    required this.phoneNumber,
    required this.message,
    this.contactName,
  });

  factory SmsParameters.fromJson(Map<String, dynamic> json) =>
      _$SmsParametersFromJson(json);

  Map<String, dynamic> toJson() => _$SmsParametersToJson(this);
}

/// Call parameters for phone call actions
@JsonSerializable()
class CallParameters {
  final String phoneNumber;
  final String? contactName;

  CallParameters({
    required this.phoneNumber,
    this.contactName,
  });

  factory CallParameters.fromJson(Map<String, dynamic> json) =>
      _$CallParametersFromJson(json);

  Map<String, dynamic> toJson() => _$CallParametersToJson(this);
}
