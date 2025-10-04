// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentResponse _$AgentResponseFromJson(Map<String, dynamic> json) =>
    AgentResponse(
      message: json['message'] as String,
      action: json['action'] == null
          ? null
          : ActionIntent.fromJson(json['action'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AgentResponseToJson(AgentResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'action': instance.action,
      'metadata': instance.metadata,
    };

ActionIntent _$ActionIntentFromJson(Map<String, dynamic> json) => ActionIntent(
  type: $enumDecode(_$ActionTypeEnumMap, json['type']),
  parameters: json['parameters'] as Map<String, dynamic>,
  requiresConfirmation: json['requiresConfirmation'] as bool? ?? true,
  confirmationPrompt: json['confirmationPrompt'] as String?,
);

Map<String, dynamic> _$ActionIntentToJson(ActionIntent instance) =>
    <String, dynamic>{
      'type': _$ActionTypeEnumMap[instance.type]!,
      'parameters': instance.parameters,
      'requiresConfirmation': instance.requiresConfirmation,
      'confirmationPrompt': instance.confirmationPrompt,
    };

const _$ActionTypeEnumMap = {
  ActionType.setAlarm: 'set_alarm',
  ActionType.setEvent: 'set_event',
  ActionType.sendSms: 'send_sms',
  ActionType.makeCall: 'make_call',
  ActionType.search: 'search',
  ActionType.unknown: 'unknown',
};

UserConfirmation _$UserConfirmationFromJson(Map<String, dynamic> json) =>
    UserConfirmation(
      actionId: json['actionId'] as String,
      approved: json['approved'] as bool,
      modifiedParameters: json['modifiedParameters'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UserConfirmationToJson(UserConfirmation instance) =>
    <String, dynamic>{
      'actionId': instance.actionId,
      'approved': instance.approved,
      'modifiedParameters': instance.modifiedParameters,
    };

EventParameters _$EventParametersFromJson(Map<String, dynamic> json) =>
    EventParameters(
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      location: json['location'] as String?,
      attendees: (json['attendees'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$EventParametersToJson(EventParameters instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'location': instance.location,
      'attendees': instance.attendees,
    };

AlarmParameters _$AlarmParametersFromJson(Map<String, dynamic> json) =>
    AlarmParameters(
      label: json['label'] as String,
      time: DateTime.parse(json['time'] as String),
      repeatDays: (json['repeatDays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      vibrate: json['vibrate'] as bool? ?? true,
    );

Map<String, dynamic> _$AlarmParametersToJson(AlarmParameters instance) =>
    <String, dynamic>{
      'label': instance.label,
      'time': instance.time.toIso8601String(),
      'repeatDays': instance.repeatDays,
      'vibrate': instance.vibrate,
    };
