import '../../models/barrel.dart';

/// Fictional demo data for Demo Mode.
///
/// Everything in this file is FICTIONAL sample content so the app is fully
/// usable immediately after installation, without any account or backend.
class DemoData {
  DemoData._();

  static const String childId = 'demo-child-1';
  static const String parentId = 'demo-user-parent';
  static const String teacherId = 'demo-user-teacher';
  static const String therapistId = 'demo-user-therapist';
  static const String caregiverId = 'demo-user-caregiver';

  static UserModel get parent => const UserModel(
        id: parentId,
        name: 'Meena (Demo Parent)',
        email: 'parent@demo.lumora',
        role: UserRole.parent,
        avatarKey: 'guardian',
        demo: true,
      );

  static UserModel get teacher => const UserModel(
        id: teacherId,
        name: 'Priya (Demo Teacher)',
        email: 'teacher@demo.lumora',
        role: UserRole.teacher,
        avatarKey: 'school',
        demo: true,
      );

  static UserModel get therapist => const UserModel(
        id: therapistId,
        name: 'Dr. Kumar (Demo Therapist)',
        email: 'therapist@demo.lumora',
        role: UserRole.therapist,
        avatarKey: 'healing',
        demo: true,
      );

  static UserModel get caregiver => const UserModel(
        id: caregiverId,
        name: 'Latha (Demo Caregiver)',
        email: 'caregiver@demo.lumora',
        role: UserRole.caregiver,
        avatarKey: 'volunteer_activism',
        demo: true,
      );

  static ChildProfile get child => const ChildProfile(
        id: childId,
        name: 'Arun',
        age: 7,
        avatarKey: 'sun',
        languageCode: 'en',
        communicationMethods: <String>['aac', 'voice', 'sentence'],
        favoriteActivityIds: <String>['colors-match', 'animals-quiz'],
        sensoryPreferences: <String>['quiet-sounds', 'soft-light'],
        comfortPreferences: <String>['hug', 'music'],
        learningLevel: 'beginner',
        trustedContactIds: <String>[
          'demo-contact-parent',
          'demo-contact-caregiver',
          'demo-contact-teacher',
        ],
        enabledModes: <String>[
          'home',
          'school',
          'hospital',
          'playground',
          'mealtime',
          'bedtime',
        ],
        notifiedEmotionIds: <String>['sad', 'scared', 'pain', 'sick'],
        notifiedNeedIds: <String>[
          'pain',
          'bathroom',
          'help',
          'uncomfortable',
        ],
        trackingEnabled: true,
      );

  static const List<PictureCategory> categories = <PictureCategory>[
    PictureCategory(
        id: 'cat-food',
        nameEn: 'Food',
        nameTa: 'உணவு',
        iconKey: 'restaurant',
        colorName: 'orange',
        orderIndex: 0),
    PictureCategory(
        id: 'cat-drinks',
        nameEn: 'Drinks',
        nameTa: 'பானங்கள்',
        iconKey: 'local_drink',
        colorName: 'teal',
        orderIndex: 1),
    PictureCategory(
        id: 'cat-people',
        nameEn: 'People',
        nameTa: 'நபர்கள்',
        iconKey: 'group',
        colorName: 'blue',
        orderIndex: 2),
    PictureCategory(
        id: 'cat-places',
        nameEn: 'Places',
        nameTa: 'இடங்கள்',
        iconKey: 'place',
        colorName: 'purple',
        orderIndex: 3),
    PictureCategory(
        id: 'cat-activities',
        nameEn: 'Activities',
        nameTa: 'செயல்பாடுகள்',
        iconKey: 'sports_esports',
        colorName: 'yellow',
        orderIndex: 4),
    PictureCategory(
        id: 'cat-toys',
        nameEn: 'Toys',
        nameTa: 'பொம்மைகள்',
        iconKey: 'toys',
        colorName: 'pink',
        orderIndex: 5),
    PictureCategory(
        id: 'cat-school',
        nameEn: 'School',
        nameTa: 'பள்ளி',
        iconKey: 'school',
        colorName: 'blue',
        orderIndex: 6),
    PictureCategory(
        id: 'cat-bathroom',
        nameEn: 'Bathroom',
        nameTa: 'கழிவறை',
        iconKey: 'wash',
        colorName: 'teal',
        orderIndex: 7),
    PictureCategory(
        id: 'cat-feelings',
        nameEn: 'Feelings',
        nameTa: 'உணர்வுகள்',
        iconKey: 'sentiment_satisfied',
        colorName: 'purple',
        orderIndex: 8),
    PictureCategory(
        id: 'cat-pain',
        nameEn: 'Pain',
        nameTa: 'வலி',
        iconKey: 'healing',
        colorName: 'red',
        orderIndex: 9),
    PictureCategory(
        id: 'cat-emergency',
        nameEn: 'Emergency',
        nameTa: 'அவசரம்',
        iconKey: 'emergency',
        colorName: 'red',
        orderIndex: 10),
    PictureCategory(
        id: 'cat-yesno',
        nameEn: 'Yes / No',
        nameTa: 'ஆம் / இல்லை',
        iconKey: 'rule',
        colorName: 'green',
        orderIndex: 11),
    PictureCategory(
        id: 'cat-greetings',
        nameEn: 'Greetings',
        nameTa: 'வணக்கம்',
        iconKey: 'waving_hand',
        colorName: 'yellow',
        orderIndex: 12),
    PictureCategory(
        id: 'cat-actions',
        nameEn: 'Actions',
        nameTa: 'செயல்கள்',
        iconKey: 'directions_run',
        colorName: 'green',
        orderIndex: 13),
    PictureCategory(
        id: 'cat-objects',
        nameEn: 'Objects',
        nameTa: 'பொருட்கள்',
        iconKey: 'category',
        colorName: 'gray',
        orderIndex: 14),
    PictureCategory(
        id: 'cat-requests',
        nameEn: 'Requests',
        nameTa: 'கோரிக்கைகள்',
        iconKey: 'front_hand',
        colorName: 'blue',
        orderIndex: 15),
  ];

  static PictureCard _c(
    String id,
    String categoryId,
    String labelEn,
    String labelTa,
    String iconKey,
    String colorName, {
    bool fav = false,
    int usage = 0,
    int order = 0,
  }) =>
      PictureCard(
        id: id,
        categoryId: categoryId,
        labelEn: labelEn,
        labelTa: labelTa,
        iconKey: iconKey,
        colorName: colorName,
        isFavorite: fav,
        usageCount: usage,
        orderIndex: order,
      );

  static List<PictureCard> get cards {
    final List<PictureCard> out = <PictureCard>[];
    int o = 0;
    // Food
    out.addAll(<PictureCard>[
      _c('card-rice', 'cat-food', 'Rice', 'சாதம்', 'rice_bowl', 'orange',
          fav: true, usage: 12, order: o++),
      _c('card-dosa', 'cat-food', 'Dosa', 'தோசை', 'bakery_dining', 'orange',
          usage: 5, order: o++),
      _c('card-idli', 'cat-food', 'Idli', 'இட்லி', 'bakery_dining', 'orange',
          usage: 4, order: o++),
      _c('card-fruit', 'cat-food', 'Fruit', 'பழம்', 'nutrition', 'green',
          usage: 7, order: o++),
      _c('card-banana', 'cat-food', 'Banana', 'வாழைப்பழம்', 'ecomode',
          'yellow', usage: 3, order: o++),
      _c('card-biscuit', 'cat-food', 'Biscuit', 'பிஸ்கட்', 'cookie',
          'brown', usage: 6, order: o++),
      _c('card-milk-food', 'cat-food', 'Milk', 'பால்', 'water_full', 'blue',
          usage: 2, order: o++),
      _c('card-egg', 'cat-food', 'Egg', 'முட்டை', 'egg', 'yellow',
          usage: 1, order: o++),
      _c('card-noodle', 'cat-food', 'Noodles', 'நூடுல்ஸ்', 'ramen_dining',
          'yellow', usage: 2, order: o++),
    ]);
    // Drinks
    out.addAll(<PictureCard>[
      _c('card-water', 'cat-drinks', 'Water', 'தண்ணீர்', 'water_drop',
          'teal', fav: true, usage: 15, order: o++),
      _c('card-juice', 'cat-drinks', 'Juice', 'ஜூஸ்', 'local_drink',
          'orange', usage: 4, order: o++),
      _c('card-milk', 'cat-drinks', 'Milk', 'பால்', 'local_cafe', 'blue',
          usage: 6, order: o++),
      _c('card-buttermilk', 'cat-drinks', 'Buttermilk', 'மோர்',
          'local_drink', 'teal', usage: 1, order: o++),
    ]);
    // People
    out.addAll(<PictureCard>[
      _c('card-mom', 'cat-people', 'Mom', 'அம்மா', 'face_3', 'pink',
          fav: true, usage: 9, order: o++),
      _c('card-dad', 'cat-people', 'Dad', 'அப்பா', 'face_6', 'blue',
          usage: 7, order: o++),
      _c('card-teacher', 'cat-people', 'Teacher', 'ஆசிரியர்', 'school',
          'purple', usage: 5, order: o++),
      _c('card-friend', 'cat-people', 'Friend', 'நண்பர்', 'group', 'green',
          usage: 3, order: o++),
      _c('card-grandma', 'cat-people', 'Grandma', 'பாட்டி', 'elderly',
          'purple', usage: 2, order: o++),
      _c('card-doctor', 'cat-people', 'Doctor', 'மருத்துவர்', 'medical_services',
          'red', usage: 1, order: o++),
    ]);
    // Places
    out.addAll(<PictureCard>[
      _c('card-home', 'cat-places', 'Home', 'வீடு', 'home', 'blue',
          fav: true, usage: 8, order: o++),
      _c('card-school-p', 'cat-places', 'School', 'பள்ளி', 'school',
          'purple', usage: 6, order: o++),
      _c('card-park', 'cat-places', 'Park', 'பூங்கா', 'park', 'green',
          usage: 4, order: o++),
      _c('card-shop', 'cat-places', 'Shop', 'கடை', 'storefront', 'orange',
          usage: 1, order: o++),
      _c('card-hospital-p', 'cat-places', 'Hospital', 'மருத்துவமனை',
          'local_hospital', 'red', usage: 1, order: o++),
    ]);
    // Activities
    out.addAll(<PictureCard>[
      _c('card-play', 'cat-activities', 'Play', 'விளையாடு', 'toys',
          'yellow', fav: true, usage: 10, order: o++),
      _c('card-draw', 'cat-activities', 'Draw', 'வரை', 'draw', 'purple',
          usage: 5, order: o++),
      _c('card-music', 'cat-activities', 'Music', 'இசை', 'music_note',
          'teal', usage: 6, order: o++),
      _c('card-swing', 'cat-activities', 'Swing', 'ஊஞ்சல்', 'attractions',
          'orange', usage: 2, order: o++),
      _c('card-story', 'cat-activities', 'Story', 'கதை', 'auto_stories',
          'blue', usage: 4, order: o++),
      _c('card-walk', 'cat-activities', 'Walk', 'நடந்து செல்',
          'directions_walk', 'green', usage: 3, order: o++),
    ]);
    // Toys
    out.addAll(<PictureCard>[
      _c('card-ball', 'cat-toys', 'Ball', 'பந்து', 'sports_soccer', 'orange',
          usage: 6, order: o++),
      _c('card-blocks', 'cat-toys', 'Blocks', 'கட்டைகள்', 'view_module',
          'blue', usage: 4, order: o++),
      _c('card-teddy', 'cat-toys', 'Teddy', 'நிக்கர் கரடி', 'pets', 'brown',
          fav: true, usage: 5, order: o++),
      _c('card-car', 'cat-toys', 'Car', 'கார்', 'directions_car', 'red',
          usage: 5, order: o++),
      _c('card-doll', 'cat-toys', 'Doll', 'பொம்மை', 'child_care', 'pink',
          usage: 2, order: o++),
    ]);
    // School
    out.addAll(<PictureCard>[
      _c('card-book', 'cat-school', 'Book', 'புத்தகம்', 'menu_book', 'purple',
          usage: 5, order: o++),
      _c('card-pencil', 'cat-school', 'Pencil', 'பென்சில்', 'edit', 'yellow',
          usage: 4, order: o++),
      _c('card-bag', 'cat-school', 'Bag', 'பை', 'backpack', 'blue',
          usage: 3, order: o++),
      _c('card-slate', 'cat-school', 'Board', 'பலகை', 'co_present', 'green',
          usage: 1, order: o++),
      _c('card-lunchbox', 'cat-school', 'Lunch box', 'உணவுப் பெட்டி',
          'lunch_dining', 'orange', usage: 2, order: o++),
    ]);
    // Bathroom
    out.addAll(<PictureCard>[
      _c('card-toilet', 'cat-bathroom', 'Toilet', 'கழிவறை', 'wc', 'teal',
          fav: true, usage: 9, order: o++),
      _c('card-brush', 'cat-bathroom', 'Brush', 'பல் துலக்கு', 'brush',
          'blue', usage: 5, order: o++),
      _c('card-bath', 'cat-bathroom', 'Bath', 'குளியல்', 'bathtub', 'teal',
          usage: 4, order: o++),
      _c('card-soap', 'cat-bathroom', 'Soap', 'சோப்பு', 'soap', 'purple',
          usage: 2, order: o++),
    ]);
    // Feelings
    out.addAll(<PictureCard>[
      _c('card-happy', 'cat-feelings', 'Happy', 'மகிழ்ச்சி',
          'sentiment_very_satisfied', 'yellow', usage: 8, order: o++),
      _c('card-sad', 'cat-feelings', 'Sad', 'சோகம்', 'sentiment_dissatisfied',
          'blue', usage: 4, order: o++),
      _c('card-angry', 'cat-feelings', 'Angry', 'கோபம்', 'mood_bad', 'red',
          usage: 2, order: o++),
      _c('card-tired', 'cat-feelings', 'Tired', 'சோர்வு', 'bedtime',
          'purple', usage: 3, order: o++),
    ]);
    // Pain
    out.addAll(<PictureCard>[
      _c('card-hurt', 'cat-pain', 'It hurts', 'வலிக்கிறது', 'healing',
          'red', usage: 3, order: o++),
      _c('card-tummy', 'cat-pain', 'Tummy pain', 'வயிற்று வலி', 'sick',
          'red', usage: 2, order: o++),
      _c('card-head', 'cat-pain', 'Head pain', 'தலைவலி', 'psychology',
          'orange', usage: 1, order: o++),
    ]);
    // Emergency
    out.addAll(<PictureCard>[
      _c('card-help-e', 'cat-emergency', 'Help!', 'உதவி!', 'emergency',
          'red', usage: 2, order: o++),
      _c('card-call-parent', 'cat-emergency', 'Call my parent', 'அம்மா '
          'அப்பாவை அழை', 'phone_in_talk', 'red', usage: 1, order: o++),
    ]);
    // Yes/No
    out.addAll(<PictureCard>[
      _c('card-yes', 'cat-yesno', 'Yes', 'ஆம்', 'check_circle', 'green',
          fav: true, usage: 11, order: o++),
      _c('card-no', 'cat-yesno', 'No', 'இல்லை', 'cancel', 'red',
          usage: 7, order: o++),
      _c('card-maybe', 'cat-yesno', 'Maybe', 'இருக்கலாம்', 'help', 'gray',
          usage: 1, order: o++),
    ]);
    // Greetings
    out.addAll(<PictureCard>[
      _c('card-hello', 'cat-greetings', 'Hello', 'வணக்கம்', 'waving_hand',
          'yellow', usage: 9, order: o++),
      _c('card-bye', 'cat-greetings', 'Bye', 'போய்வருகிறேன்', 'wave',
          'blue', usage: 6, order: o++),
      _c('card-thanks', 'cat-greetings', 'Thank you', 'நன்றி',
          'volunteer_activism', 'green', usage: 5, order: o++),
    ]);
    // Actions
    out.addAll(<PictureCard>[
      _c('card-eat', 'cat-actions', 'Eat', 'சாப்பிடு', 'restaurant', 'orange',
          usage: 7, order: o++),
      _c('card-drink-a', 'cat-actions', 'Drink', 'குடி', 'local_drink',
          'teal', usage: 5, order: o++),
      _c('card-sleep', 'cat-actions', 'Sleep', 'தூங்கு', 'bedtime', 'purple',
          usage: 6, order: o++),
      _c('card-run', 'cat-actions', 'Run', 'ஓடு', 'directions_run', 'green',
          usage: 2, order: o++),
      _c('card-sit', 'cat-actions', 'Sit', 'உட்கார்', 'chair', 'blue',
          usage: 3, order: o++),
    ]);
    // Objects
    out.addAll(<PictureCard>[
      _c('card-cup', 'cat-objects', 'Cup', 'கப்', 'local_cafe', 'blue',
          usage: 3, order: o++),
      _c('card-spoon', 'cat-objects', 'Spoon', 'ஸ்பூன்', 'restaurant_menu',
          'gray', usage: 2, order: o++),
      _c('card-fan', 'cat-objects', 'Fan', 'மின்விசிறி', 'air', 'teal',
          usage: 2, order: o++),
      _c('card-light', 'cat-objects', 'Light', 'விளக்கு', 'lightbulb',
          'yellow', usage: 1, order: o++),
    ]);
    // Requests
    out.addAll(<PictureCard>[
      _c('card-more', 'cat-requests', 'More', 'இன்னும்', 'add_circle',
          'green', usage: 8, order: o++),
      _c('card-please', 'cat-requests', 'Please', 'தயவுசெய்து',
          'front_hand', 'blue', usage: 4, order: o++),
      _c('card-break-r', 'cat-requests', 'I need a break', 'எனக்கு ஓய்வு '
          'வேண்டும்', 'self_improvement', 'purple', usage: 3, order: o++),
      _c('card-wait', 'cat-requests', 'Please wait', 'காத்திருக்கவும்',
          'hourglass_top', 'orange', usage: 2, order: o++),
    ]);
    return out;
  }

  static List<SavedPhrase> get phrases {
    final List<String> samples = <String>[
      'I want water',
      'I am hungry',
      'I need help',
      'I want to go home',
      'I feel uncomfortable',
      'Please wait',
      'Call my parent',
      'I need a break',
      'I do not understand',
    ];
    final List<SavedPhrase> out = <SavedPhrase>[];
    for (int i = 0; i < samples.length; i++) {
      out.add(SavedPhrase(
        id: 'demo-phrase-$i',
        childId: childId,
        text: samples[i],
        isFavorite: i < 3,
        usageCount: <int>[14, 9, 8, 6, 5, 4, 3, 2, 1][i],
        lastUsedAt: DateTime.now().subtract(Duration(hours: i + 1)),
        createdAt: DateTime.now().subtract(Duration(days: 10 - i)),
      ));
    }
    return out;
  }

  static List<TrustedContact> get contacts => <TrustedContact>[
        const TrustedContact(
          id: 'demo-contact-parent',
          childId: childId,
          name: 'Meena',
          relationship: 'parent',
          phone: '+91 90000 00001',
          email: 'parent@demo.lumora',
          permissionLevel: 'full',
          notificationPreference: 'all',
          isPrimary: true,
        ),
        const TrustedContact(
          id: 'demo-contact-caregiver',
          childId: childId,
          name: 'Latha',
          relationship: 'primaryCaregiver',
          phone: '+91 90000 00002',
          permissionLevel: 'editor',
          notificationPreference: 'alerts',
        ),
        const TrustedContact(
          id: 'demo-contact-teacher',
          childId: childId,
          name: 'Priya',
          relationship: 'teacher',
          phone: '+91 90000 00003',
          email: 'teacher@demo.lumora',
          permissionLevel: 'viewer',
          notificationPreference: 'alerts',
        ),
        const TrustedContact(
          id: 'demo-contact-emergency',
          childId: childId,
          name: 'Neighbour Uncle Ravi',
          relationship: 'emergency',
          phone: '+91 90000 00004',
          permissionLevel: 'viewer',
          notificationPreference: 'alerts',
        ),
      ];

  static List<Routine> get routines {
    final DateTime now = DateTime.now();
    return <Routine>[
      Routine(
        id: 'demo-routine-morning',
        childId: childId,
        name: 'Morning',
        kind: 'morning',
        repeat: 'daily',
        createdAt: now.subtract(const Duration(days: 20)),
        tasks: const <RoutineTask>[
          RoutineTask(
            id: 'demo-task-wake',
            title: 'Wake up',
            titleTa: 'எழுந்திரு',
            iconKey: 'wb_sunny',
            colorName: 'yellow',
            steps: <TaskStep>[
              TaskStep(
                  id: 's1',
                  text: 'Open your eyes',
                  textTa: 'கண்களைத் திற',
                  iconKey: 'visibility'),
              TaskStep(
                  id: 's2',
                  text: 'Sit up slowly',
                  textTa: 'மெதுவாக எழுந்திரு',
                  iconKey: 'airline_seat_flat'),
            ],
          ),
          RoutineTask(
            id: 'demo-task-brush',
            title: 'Brush teeth',
            titleTa: 'பல் துலக்கு',
            iconKey: 'brush',
            colorName: 'teal',
            steps: <TaskStep>[
              TaskStep(
                  id: 'b1',
                  text: 'Take the toothbrush',
                  textTa: 'பல் தூரிகையை எடு',
                  iconKey: 'brush'),
              TaskStep(
                  id: 'b2',
                  text: 'Apply toothpaste',
                  textTa: 'பாஸ்ட் போடு',
                  iconKey: 'water_drop'),
              TaskStep(
                  id: 'b3',
                  text: 'Brush your teeth',
                  textTa: 'பல் துலக்கு',
                  iconKey: 'sentiment_satisfied'),
              TaskStep(
                  id: 'b4',
                  text: 'Rinse your mouth',
                  textTa: 'வாயை கழுவு',
                  iconKey: 'wash'),
              TaskStep(
                  id: 'b5',
                  text: 'Put the brush away',
                  textTa: 'தூரிகையை வை',
                  iconKey: 'task_alt'),
            ],
          ),
          RoutineTask(
            id: 'demo-task-bath',
            title: 'Take a bath',
            titleTa: 'குளி',
            iconKey: 'bathtub',
            colorName: 'blue',
          ),
          RoutineTask(
            id: 'demo-task-dress',
            title: 'Get dressed',
            titleTa: 'உடை மாற்று',
            iconKey: 'checkroom',
            colorName: 'purple',
          ),
          RoutineTask(
            id: 'demo-task-breakfast',
            title: 'Eat breakfast',
            titleTa: 'காலை உணவு சாப்பிடு',
            iconKey: 'restaurant',
            colorName: 'orange',
          ),
          RoutineTask(
            id: 'demo-task-school',
            title: 'Go to school',
            titleTa: 'பள்ளிக்கு செல்',
            iconKey: 'school',
            colorName: 'blue',
          ),
        ],
      ),
      Routine(
        id: 'demo-routine-evening',
        childId: childId,
        name: 'Evening',
        kind: 'evening',
        repeat: 'daily',
        createdAt: now.subtract(const Duration(days: 20)),
        tasks: const <RoutineTask>[
          RoutineTask(
            id: 'demo-task-play',
            title: 'Play',
            titleTa: 'விளையாடு',
            iconKey: 'toys',
            colorName: 'yellow',
          ),
          RoutineTask(
            id: 'demo-task-study',
            title: 'Study',
            titleTa: 'படி',
            iconKey: 'menu_book',
            colorName: 'purple',
          ),
          RoutineTask(
            id: 'demo-task-dinner',
            title: 'Eat dinner',
            titleTa: 'இரவு உணவு சாப்பிடு',
            iconKey: 'dinner_dining',
            colorName: 'orange',
          ),
          RoutineTask(
            id: 'demo-task-sleep',
            title: 'Sleep',
            titleTa: 'தூங்கு',
            iconKey: 'bedtime',
            colorName: 'blue',
          ),
        ],
      ),
    ];
  }

  static List<Reminder> get reminders => <Reminder>[
        Reminder(
          id: 'demo-rem-school',
          childId: childId,
          title: 'School bus',
          category: 'school',
          time: DateTime(2024, 1, 1, 8, 0),
          repeat: 'weekdays',
          iconKey: 'directions_bus',
          colorName: 'blue',
        ),
        Reminder(
          id: 'demo-rem-therapy',
          childId: childId,
          title: 'Speech therapy',
          category: 'therapy',
          time: DateTime(2024, 1, 1, 17, 30),
          repeat: 'weekly',
          iconKey: 'record_voice_over',
          colorName: 'purple',
        ),
        Reminder(
          id: 'demo-rem-lunch',
          childId: childId,
          title: 'Lunch time',
          category: 'meals',
          time: DateTime(2024, 1, 1, 13, 0),
          repeat: 'daily',
          iconKey: 'lunch_dining',
          colorName: 'orange',
        ),
        Reminder(
          id: 'demo-rem-sleep',
          childId: childId,
          title: 'Bedtime',
          category: 'sleep',
          time: DateTime(2024, 1, 1, 21, 0),
          repeat: 'daily',
          iconKey: 'bedtime',
          colorName: 'purple',
        ),
      ];

  static List<Story> get stories {
    final DateTime now = DateTime.now();
    StoryPage p(String id, String text, String textTa, String icon,
            {String color = 'blue',
            List<StoryChoice> choices = const <StoryChoice>[]}) =>
        StoryPage(
          id: id,
          text: text,
          textTa: textTa,
          iconKey: icon,
          colorName: color,
          choices: choices,
        );

    return <Story>[
      Story(
        id: 'story-school',
        title: 'Going to school',
        titleTa: 'பள்ளிக்கு செல்லுதல்',
        createdAt: now.subtract(const Duration(days: 30)),
        iconKey: 'school',
        colorName: 'blue',
        pages: <StoryPage>[
          p('p1', 'I wake up and get ready.', 'நான் எழுந்து தயாராகிறேன்.',
              'wb_sunny', color: 'yellow'),
          p('p2', 'I ride the bus with my bag.',
              'நான் பையுடன் பஸ்ஸில் செல்கிறேன்.', 'directions_bus'),
          p('p3', 'I say hello to my teacher.',
              'நான் ஆசிரியரிடம் வணக்கம் சொல்கிறேன்.', 'waving_hand',
              color: 'green',
              choices: <StoryChoice>[
                const StoryChoice(
                    id: 'c1',
                    text: 'I feel happy',
                    nextPageId: 'p4'),
                const StoryChoice(
                    id: 'c2',
                    text: 'I feel shy',
                    nextPageId: 'p4'),
              ]),
          p('p4', 'I learn and play with my friends.',
              'நான் நண்பர்களுடன் கற்று விளையாடுகிறேன்.', 'groups'),
          p('p5', 'School is a safe place. Mom picks me up after school.',
              'பள்ளி பாதுகாப்பான இடம். பள்ளி முடிந்து அம்மா என்னை '
                  'அழைத்துச் செல்கிறார்.', 'favorite',
              color: 'pink'),
        ],
      ),
      Story(
        id: 'story-doctor',
        title: 'Visiting a doctor',
        titleTa: 'மருத்துவரை காணுதல்',
        createdAt: now.subtract(const Duration(days: 25)),
        iconKey: 'local_hospital',
        colorName: 'red',
        pages: <StoryPage>[
          p('p1', 'We go to the clinic.', 'நாம் மருத்துவமனைக்கு செல்கிறோம்.',
              'local_hospital'),
          p('p2', 'We wait for our turn. I can read a book.',
              'நாம் வரிசையில் காத்திருக்கிறோம். நான் புத்தகம் படிக்கலாம்.',
              'menu_book'),
          p('p3', 'The doctor checks me. It does not hurt.',
              'மருத்துவர் என்னை பரிசோதிக்கிறார். வலி இல்லை.',
              'medical_services'),
          p('p4', 'I can say or show: \u201cI am scared\u201d.',
              'நான் சொல்லலாம் அல்லது காட்டலாம்: \u201cஎனக்கு பயம்\u201d.',
              'sentiment_dissatisfied',
              choices: <StoryChoice>[
                const StoryChoice(id: 'c1', text: 'I am brave', nextPageId: 'p5'),
                const StoryChoice(
                    id: 'c2', text: 'I need my parent', nextPageId: 'p5'),
              ]),
          p('p5', 'Afterwards I get a sticker. Well done, me!',
              'பிறகு எனக்கு ஸ்டிக்கர் கிடைக்கும். நன்று, நான்!',
              'star', color: 'yellow'),
        ],
      ),
      Story(
        id: 'story-new-people',
        title: 'Meeting new people',
        titleTa: 'புதியவர்களை சந்தித்தல்',
        createdAt: now.subtract(const Duration(days: 22)),
        iconKey: 'group_add',
        colorName: 'purple',
        pages: <StoryPage>[
          p('p1', 'Sometimes I meet new people.',
              'சில நேரங்களில் நான் புதியவர்களை சந்திக்கிறேன்.', 'group_add'),
          p('p2', 'It is okay to feel shy.',
              'நாணம் கொள்வது சரிதான்.', 'sentiment_neutral'),
          p('p3', 'I can say hello when I am ready.',
              'நான் தயாரானதும் வணக்கம் சொல்லலாம்.', 'waving_hand',
              color: 'green'),
          p('p4', 'I can hold mom or dad\u2019s hand.',
              'நான் அம்மா அல்லது அப்பாவின் கையை பிடிக்கலாம்.',
              'front_hand', color: 'blue'),
        ],
      ),
      Story(
        id: 'story-queue',
        title: 'Waiting in a queue',
        titleTa: 'வரிசையில் காத்திருத்தல்',
        createdAt: now.subtract(const Duration(days: 18)),
        iconKey: 'hourglass_top',
        colorName: 'orange',
        pages: <StoryPage>[
          p('p1', 'Sometimes I must wait.', 'சில நேரம் காத்திருக்க வேண்டும்.',
              'hourglass_top'),
          p('p2', 'Waiting can feel long.',
              'காத்திருப்பு நீளமாக உணரலாம்.', 'schedule'),
          p('p3', 'I can count or breathe slowly.',
              'நான் எண்ணலாம் அல்லது மெதுவாக மூச்சு விடலாம்.',
              'self_improvement', color: 'teal'),
          p('p4', 'My turn comes, and I feel proud.',
              'என் முறை வரும்; நான் பெருமை அடைவேன்.', 'sentiment_very_satisfied',
              color: 'yellow'),
        ],
      ),
      Story(
        id: 'story-sharing',
        title: 'Sharing toys',
        titleTa: 'பொம்மைகளை பகிர்தல்',
        createdAt: now.subtract(const Duration(days: 15)),
        iconKey: 'toys',
        colorName: 'pink',
        pages: <StoryPage>[
          p('p1', 'My friend wants to play too.',
              'என் நண்பரும் விளையாட விரும்புகிறார்.', 'group'),
          p('p2', 'We can take turns.', 'நாம் மாறி மாறி விளையாடலாம்.',
              'swap_horiz', color: 'green'),
          p('p3', 'Sharing makes play more fun.',
              'பகிர்வு விளையாட்டை இனிமையாக்கும்.', 'sentiment_very_satisfied',
              color: 'yellow'),
        ],
      ),
      Story(
        id: 'story-classroom-rules',
        title: 'Classroom rules',
        titleTa: 'வகுப்பறை விதிகள்',
        createdAt: now.subtract(const Duration(days: 12)),
        iconKey: 'menu_book',
        colorName: 'blue',
        pages: <StoryPage>[
          p('p1', 'I sit at my desk.', 'நான் என் இருக்கையில் அமர்கிறேன்.',
              'chair'),
          p('p2', 'I listen when teacher talks.',
              'ஆசிரியர் பேசும்போது நான் கேட்கிறேன்.', 'hearing',
              color: 'teal'),
          p('p3', 'I raise my hand to answer.',
              'பதில் சொல்ல கையை உயர்த்துகிறேன்.', 'front_hand'),
          p('p4', 'If I do not understand, I can ask for help.',
              'புரியவில்லை என்றால் உதவி கேட்கலாம்.', 'help',
              color: 'purple'),
        ],
      ),
      Story(
        id: 'story-trip',
        title: 'Going on a trip',
        titleTa: 'பயணம் செல்லுதல்',
        createdAt: now.subtract(const Duration(days: 9)),
        iconKey: 'directions_car',
        colorName: 'teal',
        pages: <StoryPage>[
          p('p1', 'We pack our bag together.',
              'நாம் சேர்ந்து பை பொட்டலம் கட்டுகிறோம்.', 'backpack'),
          p('p2', 'The car ride may be long.',
              'கார் பயணம் நீளமாக இருக்கலாம்.', 'directions_car'),
          p('p3', 'I can listen to songs or rest.',
              'நான் பாடல்களை கேட்கலாம் அல்லது ஓய்வெடுக்கலாம்.',
              'music_note', color: 'purple'),
          p('p4', 'We arrive and explore together!',
              'நாம் சேர்ந்து வந்து ஆராய்கிறோம்!', 'explore',
              color: 'green'),
        ],
      ),
      Story(
        id: 'story-loud',
        title: 'Loud environments',
        titleTa: 'சத்தமான இடங்கள்',
        createdAt: now.subtract(const Duration(days: 6)),
        iconKey: 'volume_up',
        colorName: 'orange',
        pages: <StoryPage>[
          p('p1', 'Some places are loud.', 'சில இடங்கள் சத்தமாக இருக்கும்.',
              'volume_up'),
          p('p2', 'Loud sounds can bother me.',
              'சத்தம் எனக்கு கஷ்டமாக இருக்கலாம்.', 'hearing_disabled'),
          p('p3', 'I can cover my ears or wear headphones.',
              'நான் காதை பொத்தலாம் அல்லது ஹெட்ஃபோன் அணியலாம்.',
              'headphones', color: 'blue'),
          p('p4', 'I can tell a grown-up: \u201cI need a break\u201d.',
              'பெரியவரிடம் சொல்லலாம்: \u201cஎனக்கு ஓய்வு வேண்டும்\u201d.',
              'self_improvement', color: 'teal'),
        ],
      ),
      Story(
        id: 'story-ask-help',
        title: 'Asking for help',
        titleTa: 'உதவி கோருதல்',
        createdAt: now.subtract(const Duration(days: 3)),
        iconKey: 'help',
        colorName: 'green',
        pages: <StoryPage>[
          p('p1', 'Everyone needs help sometimes.',
              'எல்லோருக்கும் சில நேரம் உதவி தேவை.', 'volunteer_activism'),
          p('p2', 'I can say: \u201cI need help\u201d.',
              'நான் சொல்லலாம்: \u201cஎனக்கு உதவி வேண்டும்\u201d.',
              'front_hand'),
          p('p3', 'I can show my help card.',
              'நான் உதவி அட்டையை காட்டலாம்.', 'style', color: 'yellow'),
          p('p4', 'Grown-ups are happy to help me.',
              'பெரியவர்கள் எனக்கு உதவ மகிழ்ச்சி.', 'sentiment_very_satisfied',
              color: 'green'),
        ],
      ),
      Story(
        id: 'story-home-safe',
        title: 'Returning home safely',
        titleTa: 'பாதுகாப்பாக வீடு திரும்புதல்',
        createdAt: now.subtract(const Duration(days: 1)),
        iconKey: 'home',
        colorName: 'blue',
        pages: <StoryPage>[
          p('p1', 'After school I wait with my teacher.',
              'பள்ளி முடிந்து நான் ஆசிரியருடன் காத்திருக்கிறேன்.',
              'school'),
          p('p2', 'Mom or dad comes to pick me up.',
              'அம்மா அல்லது அப்பா என்னை அழைக்க வருகிறார்கள்.', 'family_restroom'),
          p('p3', 'I never go with someone I do not know.',
              'தெரியாதவருடன் நான் எங்கும் செல்ல மாட்டேன்.', 'do_not_touch',
              color: 'red'),
          p('p4', 'Home is warm and safe. I did it!',
              'வீடு அமைதியான பாதுகாப்பான இடம். நான் செய்தேன்!',
              'home', color: 'green'),
        ],
      ),
    ];
  }

  static List<CaregiverNote> get notes => <CaregiverNote>[
        CaregiverNote(
          id: 'demo-note-1',
          childId: childId,
          authorName: 'Priya (Demo Teacher)',
          authorRole: 'teacher',
          noteType: 'teacher',
          text: 'Arun used the picture board to ask for water during class. '
              'Wonderful independence!',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        CaregiverNote(
          id: 'demo-note-2',
          childId: childId,
          authorName: 'Dr. Kumar (Demo Therapist)',
          authorRole: 'therapist',
          noteType: 'therapist',
          text: 'Practiced the \u201cI need a break\u201d phrase three times. '
              'Clear progress this month.',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        CaregiverNote(
          id: 'demo-note-3',
          childId: childId,
          authorName: 'Meena (Demo Parent)',
          authorRole: 'parent',
          noteType: 'parent',
          text: 'Great week with the morning routine - two full completions!',
          createdAt: DateTime.now().subtract(const Duration(hours: 20)),
        ),
      ];

  /// Communication activities spread over the last 14 days so charts and
  /// the tracker look alive on first run.
  static List<CommunicationActivity> get commActivities {
    final List<CommunicationActivity> out = <CommunicationActivity>[];
    final List<String> contents = <String>[
      'I want water',
      'I am hungry',
      'I need help',
      'Happy',
      'I need a break',
      'Water',
      'More',
      'Toilet',
      'I want to play',
      'Please wait',
    ];
    final List<CommMethod> methods = <CommMethod>[
      CommMethod.aac,
      CommMethod.needs,
      CommMethod.voice,
      CommMethod.emotions,
      CommMethod.sentenceBuilder,
    ];
    int k = 0;
    for (int day = 0; day < 14; day++) {
      final int count = 3 + (day * 7 + 3) % 5; // 3..7 deterministic
      for (int i = 0; i < count; i++) {
        final int m = (k + i) % methods.length;
        out.add(CommunicationActivity(
          id: 'demo-act-$k',
          childId: childId,
          method: methods[m],
          content: contents[k % contents.length],
          assisted: (k + i) % 4 == 0,
          createdAt: DateTime.now().subtract(
            Duration(days: day, hours: (i * 3) % 12),
          ),
        ));
        k++;
      }
    }
    return out;
  }

  static List<EmotionEntry> get emotionEntries {
    final List<EmotionEntry> out = <EmotionEntry>[];
    final List<String> emos = <String>[
      'happy',
      'calm',
      'sad',
      'excited',
      'tired',
      'angry',
      'happy',
      'scared',
      'happy',
      'calm',
      'happy',
      'worried',
    ];
    for (int i = 0; i < emos.length; i++) {
      out.add(EmotionEntry(
        id: 'demo-emo-$i',
        childId: childId,
        emotionId: emos[i],
        comfortChoiceId:
            i % 3 == 0 ? null : EmotionCatalog.comfortChoiceIds[i % 5],
        notifiedCaregiver: i == 2 || i == 7,
        createdAt: DateTime.now().subtract(Duration(days: i * 1, hours: 3)),
      ));
    }
    return out;
  }

  /// Learning progress spread over the last 10 days so the parent dashboard
  /// and reports show meaningful data on first run.
  static List<LearningProgress> get learningProgress {
    final List<({String id, int total, int correct})> plays = <(
        {String id, int total, int correct})>[
      (id: 'colors-match', total: 5, correct: 4),
      (id: 'animals-quiz', total: 5, correct: 5),
      (id: 'numbers-count', total: 5, correct: 3),
      (id: 'shapes-quiz', total: 5, correct: 4),
      (id: 'colors-match', total: 5, correct: 5),
      (id: 'animals-quiz', total: 5, correct: 4),
      (id: 'memory-cards', total: 6, correct: 6),
      (id: 'fruits-quiz', total: 4, correct: 3),
      (id: 'colors-match', total: 5, correct: 3),
      (id: 'numbers-count', total: 5, correct: 4),
      (id: 'animals-quiz', total: 5, correct: 3),
      (id: 'shapes-quiz', total: 5, correct: 5),
    ];
    final List<LearningProgress> out = <LearningProgress>[];
    for (int i = 0; i < plays.length; i++) {
      final int total = plays[i].total;
      final int correct = plays[i].correct;
      out.add(LearningProgress(
        id: 'demo-lp-$i',
        childId: childId,
        activityId: plays[i].id,
        level: 'beginner',
        completedAt: DateTime.now().subtract(Duration(days: i ~/ 2, hours: i)),
        correctCount: correct,
        totalCount: total,
        durationSeconds: 60 + (i * 17) % 120,
        starsEarned: total == 0 ? 0 : ((correct / total) * 3).round(),
      ));
    }
    return out;
  }

  static List<SentenceHistory> get sentences => <SentenceHistory>[
        SentenceHistory(
          id: 'demo-sent-1',
          childId: childId,
          words: const <String>['I', 'want', 'water'],
          spokenText: 'I want water',
          usageCount: 6,
          isFavorite: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        SentenceHistory(
          id: 'demo-sent-2',
          childId: childId,
          words: const <String>['I', 'am', 'hungry'],
          spokenText: 'I am hungry',
          usageCount: 4,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        SentenceHistory(
          id: 'demo-sent-3',
          childId: childId,
          words: const <String>['I', 'need', 'help'],
          spokenText: 'I need help',
          usageCount: 3,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];

  static List<SafetyAlert> get alerts => <SafetyAlert>[
        SafetyAlert(
          id: 'demo-alert-1',
          childId: childId,
          messageKey: 'safety.needHelp',
          status: 'acknowledged',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          notifiedContactIds: const <String>['demo-contact-parent'],
          demo: true,
        ),
        SafetyAlert(
          id: 'demo-alert-2',
          childId: childId,
          messageKey: 'safety.lost',
          status: 'sent',
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
          notifiedContactIds: const <String>[
            'demo-contact-parent',
            'demo-contact-caregiver',
          ],
          demo: true,
        ),
      ];

  static List<NotificationItem> get notifications => <NotificationItem>[
        NotificationItem(
          id: 'demo-notif-1',
          titleKey: 'Routine completed',
          bodyKey: 'Morning routine finished - great job!',
          type: 'routine',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          rawTitle: 'Routine completed',
          rawBody: 'Morning routine finished - great job!',
        ),
        NotificationItem(
          id: 'demo-notif-2',
          titleKey: 'Note from teacher',
          bodyKey: 'Priya added a progress note.',
          type: 'note',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          rawTitle: 'Note from teacher',
          rawBody: 'Priya added a progress note.',
        ),
        NotificationItem(
          id: 'demo-notif-3',
          titleKey: 'Feeling shared',
          bodyKey: 'Arun shared feeling: sad. A comfort option was offered.',
          type: 'alert',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          rawTitle: 'Feeling shared',
          rawBody: 'Arun shared feeling: sad. A comfort option was offered.',
        ),
      ];

  static List<CaregiverPermission> get permissions => <CaregiverPermission>[
        CaregiverPermission(
          id: 'demo-perm-teacher',
          childId: childId,
          invitedUserId: teacherId,
          invitedUserName: 'Priya (Demo Teacher)',
          role: UserRole.teacher,
          canViewReports: true,
          canViewEmotions: false,
          canViewRoutines: true,
          canAssignActivities: true,
          canWriteNotes: true,
          canReceiveAlerts: false,
          status: 'active',
          inviteCode: 'LUMORA-TEACHER',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        CaregiverPermission(
          id: 'demo-perm-therapist',
          childId: childId,
          invitedUserId: therapistId,
          invitedUserName: 'Dr. Kumar (Demo Therapist)',
          role: UserRole.therapist,
          canViewReports: true,
          canViewEmotions: true,
          canViewRoutines: false,
          canAssignActivities: true,
          canWriteNotes: true,
          canReceiveAlerts: false,
          status: 'active',
          inviteCode: 'LUMORA-THERAPY',
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
        ),
      ];

  /// Seeds the local data source with demo content if it is empty.
  static Future<void> seedIfNeeded() async {
    // Implemented in DemoDataSource to keep this file data-only.
  }
}
