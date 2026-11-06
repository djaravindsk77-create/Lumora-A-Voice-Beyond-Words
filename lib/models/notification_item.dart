import 'package:flutter/foundation.dart';

/// An in-app notification shown in the notification center.
@immutable
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
    required this.type,
    required this.createdAt,
    this.titleParams = const <String, String>{},
    this.bodyParams = const <String, String>{},
    this.read = false,
    this.rawTitle,
    this.rawBody,
  });

  final String id;

  /// Localization keys; rawTitle/rawBody used for dynamic content.
  final String titleKey;
  final String bodyKey;
  final Map<String, String> titleParams;
  final Map<String, String> bodyParams;

  /// routine | activity | alert | note | event | system
  final String type;
  final DateTime createdAt;
  final bool read;
  final String? rawTitle;
  final String? rawBody;

  NotificationItem copyWith({bool? read}) => NotificationItem(
        id: id,
        titleKey: titleKey,
        bodyKey: bodyKey,
        titleParams: titleParams,
        bodyParams: bodyParams,
        type: type,
        createdAt: createdAt,
        read: read ?? this.read,
        rawTitle: rawTitle,
        rawBody: rawBody,
      );

  String title(String languageCode) => rawTitle ?? titleKey;
  String body(String languageCode) => rawBody ?? bodyKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'titleKey': titleKey,
        'bodyKey': bodyKey,
        'titleParams': titleParams,
        'bodyParams': bodyParams,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'rawTitle': rawTitle,
        'rawBody': rawBody,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] as String,
        titleKey: json['titleKey'] as String? ?? 'notif.title',
        bodyKey: json['bodyKey'] as String? ?? '',
        titleParams:
            (json['titleParams'] as Map<String, dynamic>? ?? const {})
                .cast<String, String>(),
        bodyParams:
            (json['bodyParams'] as Map<String, dynamic>? ?? const {})
                .cast<String, String>(),
        type: json['type'] as String? ?? 'system',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        read: json['read'] as bool? ?? false,
        rawTitle: json['rawTitle'] as String?,
        rawBody: json['rawBody'] as String?,
      );
}
