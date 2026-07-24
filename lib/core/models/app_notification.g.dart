// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppNotificationImpl _$$AppNotificationImplFromJson(
        Map<String, dynamic> json) =>
    _$AppNotificationImpl(
      id: json['id'] as String,
      subject: json['subject'] as String,
      content: json['email_content'] as String?,
      type: json['type'] as String,
      read: json['read'] as bool? ?? false,
      creation: DateTime.parse(json['creation'] as String),
      documentType: json['document_type'] as String?,
      documentName: json['document_name'] as String?,
    );

Map<String, dynamic> _$$AppNotificationImplToJson(
        _$AppNotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subject': instance.subject,
      'email_content': instance.content,
      'type': instance.type,
      'read': instance.read,
      'creation': instance.creation.toIso8601String(),
      'document_type': instance.documentType,
      'document_name': instance.documentName,
    };
