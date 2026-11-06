import 'package:flutter/foundation.dart';

/// A context-aware communication mode (Home, School, Hospital...).
@immutable
class CommunicationMode {
  const CommunicationMode({
    required this.id,
    required this.nameKey,
    required this.iconKey,
    required this.colorName,
    required this.phrases,
    this.isCustom = false,
    this.enabled = true,
    this.orderIndex = 0,
  });

  final String id;

  /// Localization key for built-in modes (e.g. 'mode.school').
  final String nameKey;

  final String iconKey;
  final String colorName;

  /// Phrase keys or raw strings offered in this mode.
  final List<String> phrases;

  /// True for parent-created modes.
  final bool isCustom;
  final bool enabled;
  final int orderIndex;

  CommunicationMode copyWith({
    String? iconKey,
    String? colorName,
    List<String>? phrases,
    bool? enabled,
    int? orderIndex,
  }) =>
      CommunicationMode(
        id: id,
        nameKey: nameKey,
        iconKey: iconKey ?? this.iconKey,
        colorName: colorName ?? this.colorName,
        phrases: phrases ?? this.phrases,
        isCustom: isCustom,
        enabled: enabled ?? this.enabled,
        orderIndex: orderIndex ?? this.orderIndex,
      );
}

/// Built-in modes with curated phrases (English text; Tamil fallback is the
/// same text unless a Tamil translation exists in the phrase bank).
class ModeCatalog {
  ModeCatalog._();

  static const List<CommunicationMode> builtIn = <CommunicationMode>[
    CommunicationMode(
      id: 'home',
      nameKey: 'mode.home',
      iconKey: 'home',
      colorName: 'blue',
      phrases: <String>[
        'I want water',
        'I am hungry',
        'I need help',
        'I want to play',
        'I want my parent',
      ],
    ),
    CommunicationMode(
      id: 'school',
      nameKey: 'mode.school',
      iconKey: 'school',
      colorName: 'purple',
      phrases: <String>[
        'I need help',
        'I want to answer',
        'I do not understand',
        'I need a break',
        'I want to use the bathroom',
      ],
    ),
    CommunicationMode(
      id: 'hospital',
      nameKey: 'mode.hospital',
      iconKey: 'local_hospital',
      colorName: 'red',
      phrases: <String>[
        'I am in pain',
        'I feel scared',
        'Where is my parent?',
        'Please stop',
        'I need water',
      ],
    ),
    CommunicationMode(
      id: 'travel',
      nameKey: 'mode.travel',
      iconKey: 'directions_car',
      colorName: 'teal',
      phrases: <String>[
        'I need a break',
        'I feel uncomfortable',
        'I want water',
        'When will we arrive?',
      ],
    ),
    CommunicationMode(
      id: 'public',
      nameKey: 'mode.public',
      iconKey: 'storefront',
      colorName: 'orange',
      phrases: <String>[
        'I am lost',
        'Please call my parent',
        'I need help',
        'I do not know this person',
        'I want to go home',
      ],
    ),
    CommunicationMode(
      id: 'playground',
      nameKey: 'mode.playground',
      iconKey: 'toys',
      colorName: 'yellow',
      phrases: <String>[
        'I want to play',
        'I need a break',
        'Watch me!',
        'I feel scared of the swing',
      ],
    ),
    CommunicationMode(
      id: 'mealtime',
      nameKey: 'mode.mealtime',
      iconKey: 'restaurant',
      colorName: 'green',
      phrases: <String>[
        'I am hungry',
        'I am thirsty',
        'I am finished',
        'I do not like this',
        'More please',
      ],
    ),
    CommunicationMode(
      id: 'classroom',
      nameKey: 'mode.classroom',
      iconKey: 'menu_book',
      colorName: 'blue',
      phrases: <String>[
        'I do not understand',
        'I want to answer',
        'I need a break',
        'Can you repeat that?',
      ],
    ),
    CommunicationMode(
      id: 'therapy',
      nameKey: 'mode.therapy',
      iconKey: 'medication',
      colorName: 'purple',
      phrases: <String>[
        'I need a break',
        'That is too hard',
        'I did it!',
        'I need my parent',
      ],
    ),
    CommunicationMode(
      id: 'bedtime',
      nameKey: 'mode.bedtime',
      iconKey: 'bedtime',
      colorName: 'purple',
      phrases: <String>[
        'I want to sleep',
        'I need water',
        'Read me a story',
        'I feel scared of the dark',
      ],
    ),
  ];

  static CommunicationMode? byId(String id) {
    for (final CommunicationMode m in builtIn) {
      if (m.id == id) return m;
    }
    return null;
  }
}
