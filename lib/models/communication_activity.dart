import 'package:flutter/foundation.dart';

/// Methods of communication tracked by the confidence tracker.
enum CommMethod { aac, voice, sentenceBuilder, needs, emotions, safety }

extension CommMethodX on CommMethod {
  String get id {
    switch (this) {
      case CommMethod.aac:
        return 'aac';
      case CommMethod.voice:
        return 'voice';
      case CommMethod.sentenceBuilder:
        return 'sentence';
      case CommMethod.needs:
        return 'needs';
      case CommMethod.emotions:
        return 'emotions';
      case CommMethod.safety:
        return 'safety';
    }
  }

  String get l10nKey {
    switch (this) {
      case CommMethod.aac:
        return 'track.aacUsage';
      case CommMethod.voice:
        return 'track.voiceUsage';
      case CommMethod.sentenceBuilder:
        return 'track.sentenceUsage';
      case CommMethod.needs:
        return 'needs.title';
      case CommMethod.emotions:
        return 'feel.title';
      case CommMethod.safety:
        return 'safety.title';
    }
  }

  static CommMethod fromId(String id) {
    for (final CommMethod m in CommMethod.values) {
      if (m.id == id) return m;
    }
    return CommMethod.aac;
  }
}

/// A single communication attempt, logged for the confidence tracker and
/// reports. Never scored or compared across children.
@immutable
class CommunicationActivity {
  const CommunicationActivity({
    required this.id,
    required this.childId,
    required this.method,
    required this.content,
    this.assisted = false,
    this.contextMode,
    this.createdAt,
  });

  final String id;
  final String childId;
  final CommMethod method;

  /// The phrase/word/label that was communicated.
  final String content;

  /// True when a caregiver prompted/assisted (vs independent use).
  final bool assisted;

  /// Context mode id when applicable (school, hospital, ...).
  final String? contextMode;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'childId': childId,
        'method': method.id,
        'content': content,
        'assisted': assisted,
        'contextMode': contextMode,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory CommunicationActivity.fromJson(Map<String, dynamic> json) =>
      CommunicationActivity(
        id: json['id'] as String,
        childId: json['childId'] as String,
        method: CommMethodX.fromId(json['method'] as String? ?? 'aac'),
        content: json['content'] as String? ?? '',
        assisted: json['assisted'] as bool? ?? false,
        contextMode: json['contextMode'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

/// A caregiver note attached to progress (supportive observations only).
@immutable
class CaregiverNote {
  const CaregiverNote({
    required this.id,
    required this.childId,
    required this.authorName,
    required this.authorRole,
    required this.noteType,
    required this.text,
    required this.createdAt,
    this.isPrivate = false,
  });

  final String id;
  final String childId;

  /// Display name of the parent/teacher/therapist who wrote it.
  final String authorName;
  final String authorRole;

  /// teacher | therapist | parent | system
  final String noteType;
  final String text;
  final DateTime createdAt;

  /// Private notes are visible only to their author in demo mode.
  final bool isPrivate;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'childId': childId,
        'authorName': authorName,
        'authorRole': authorRole,
        'noteType': noteType,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'isPrivate': isPrivate,
      };

  factory CaregiverNote.fromJson(Map<String, dynamic> json) => CaregiverNote(
        id: json['id'] as String,
        childId: json['childId'] as String,
        authorName: json['authorName'] as String? ?? '',
        authorRole: json['authorRole'] as String? ?? 'parent',
        noteType: json['noteType'] as String? ?? json['authorRole'] as String? ?? 'parent',
        text: json['text'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        isPrivate: json['isPrivate'] as bool? ?? false,
      );
}
