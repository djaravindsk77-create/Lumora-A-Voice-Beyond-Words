import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/aac/aac_board_screen.dart';
import '../../features/aac/aac_categories_screen.dart';
import '../../features/aac/aac_favorites_screen.dart';
import '../../features/aac/aac_search_screen.dart';
import '../../features/calm_space/calm_space_screen.dart';
import '../../features/admin_dashboard/admin_dashboard_screen.dart';
import '../../features/caregiver_dashboard/caregiver_dashboard_screen.dart';
import '../../features/caregiver_dashboard/child_management_screen.dart';
import '../../features/caregiver_dashboard/content_management_screen.dart';
import '../../features/caregiver_dashboard/home_layout_screen.dart';
import '../../features/caregiver_dashboard/parent_dashboard_screen.dart';
import '../../features/therapist_dashboard/therapist_dashboard_screen.dart';
import '../../features/collaboration/collaboration_screen.dart';
import '../../features/confidence_tracker/confidence_tracker_screen.dart';
import '../../features/context_modes/context_modes_screen.dart';
import '../../features/creative/creative_hub_screen.dart';
import '../../features/emotions/emotion_history_screen.dart';
import '../../features/emotions/emotions_screen.dart';
import '../../features/learning/learn_play_screen.dart';
import '../../features/learning/learning_activity_screen.dart';
import '../../features/learning/learning_progress_screen.dart';
import '../../features/my_needs/my_needs_screen.dart';
import '../../features/child_home/child_home_screen.dart';
import '../../features/onboarding/accessibility_setup_screen.dart';
import '../../features/onboarding/language_selection_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/role_selection_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import 'route_hosts.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reminders/reminders_screen.dart';
import '../../features/routines/routine_planner_screen.dart';
import '../../features/routines/task_guidance_screen.dart';
import '../../features/routines/visual_timer_screen.dart';
import '../../features/safety/lost_child_mode_screen.dart';
import '../../features/safety/safety_screen.dart';
import '../../features/safety/trusted_contacts_screen.dart';
import '../../features/sentence_builder/sentence_builder_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/notifications_center_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/stories/stories_hub_screen.dart';
import '../../features/stories/story_reader_screen.dart';
import '../../features/voice_communication/voice_communication_screen.dart';

/// All Lumora routes. Child-mode and parent-mode destinations live side by
/// side; guards in the session layer decide what is reachable per role.
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    // ---- Onboarding & auth ----
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (BuildContext context, GoRouterState state) =>
          const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (BuildContext context, GoRouterState state) =>
          const WelcomeScreen(),
    ),
    GoRoute(
      path: '/welcome-back',
      name: 'welcomeBack',
      builder: (BuildContext context, GoRouterState state) =>
          const WelcomeScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (BuildContext context, GoRouterState state) =>
          const OnboardingScreen(),
    ),
    GoRoute(
      path: '/role-select',
      name: 'roleSelect',
      builder: (BuildContext context, GoRouterState state) =>
          const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/language',
      name: 'language',
      builder: (BuildContext context, GoRouterState state) =>
          LanguageSelectionScreen(
        role: state.uri.queryParameters['role'],
      ),
    ),
    GoRoute(
      path: '/accessibility',
      name: 'accessibilitySetup',
      builder: (BuildContext context, GoRouterState state) =>
          AccessibilitySetupScreen(
        role: state.uri.queryParameters['role'],
      ),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (BuildContext context, GoRouterState state) => LoginRouteHost(
        demo: state.uri.queryParameters['demo'] == '1',
        role: state.uri.queryParameters['role'],
      ),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (BuildContext context, GoRouterState state) =>
          const RegisterRouteHost(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgotPassword',
      builder: (BuildContext context, GoRouterState state) =>
          const ForgotPasswordRouteHost(),
    ),
    GoRoute(
      path: '/child-setup',
      name: 'childSetup',
      builder: (BuildContext context, GoRouterState state) =>
          const ChildProfileSetupRouteHost(),
    ),
    GoRoute(
      path: '/setup-complete',
      name: 'setupComplete',
      builder: (BuildContext context, GoRouterState state) =>
          const SetupCompleteRouteHost(),
    ),

    // ---- Child mode ----
    GoRoute(
      path: '/child-home',
      name: 'childHome',
      builder: (BuildContext context, GoRouterState state) =>
          const ChildHomeScreen(),
    ),
    GoRoute(
      path: '/voice',
      name: 'voice',
      builder: (BuildContext context, GoRouterState state) =>
          const VoiceCommunicationScreen(),
    ),
    GoRoute(
      path: '/aac',
      name: 'aac',
      builder: (BuildContext context, GoRouterState state) =>
          const AacCategoriesScreen(),
    ),
    GoRoute(
      path: '/aac/search',
      name: 'aacSearch',
      builder: (BuildContext context, GoRouterState state) =>
          const AacSearchScreen(),
    ),
    GoRoute(
      path: '/aac/favorites',
      name: 'aacFavorites',
      builder: (BuildContext context, GoRouterState state) =>
          const AacFavoritesScreen(),
    ),
    GoRoute(
      path: '/aac/board/:categoryId',
      name: 'aacBoard',
      builder: (BuildContext context, GoRouterState state) => AacBoardScreen(
        categoryId: state.pathParameters['categoryId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/sentence-builder',
      name: 'sentenceBuilder',
      builder: (BuildContext context, GoRouterState state) =>
          const SentenceBuilderScreen(),
    ),
    GoRoute(
      path: '/needs',
      name: 'needs',
      builder: (BuildContext context, GoRouterState state) =>
          const MyNeedsScreen(),
    ),
    GoRoute(
      path: '/emotions',
      name: 'emotions',
      builder: (BuildContext context, GoRouterState state) =>
          const EmotionsScreen(),
    ),
    GoRoute(
      path: '/emotions/history',
      name: 'emotionHistory',
      builder: (BuildContext context, GoRouterState state) =>
          const EmotionHistoryScreen(),
    ),
    GoRoute(
      path: '/tracker',
      name: 'tracker',
      builder: (BuildContext context, GoRouterState state) =>
          const ConfidenceTrackerScreen(),
    ),
    GoRoute(
      path: '/modes',
      name: 'contextModes',
      builder: (BuildContext context, GoRouterState state) =>
          const ContextModesScreen(),
    ),
    GoRoute(
      path: '/learn',
      name: 'learn',
      builder: (BuildContext context, GoRouterState state) =>
          const LearnPlayScreen(),
    ),
    GoRoute(
      path: '/learn/activity/:activityId',
      name: 'learnActivity',
      builder: (BuildContext context, GoRouterState state) =>
          LearningActivityScreen(
        activityId: state.pathParameters['activityId'] ?? '',
        mode: state.uri.queryParameters['mode'] ?? 'quiz',
      ),
    ),
    GoRoute(
      path: '/learn/progress',
      name: 'learnProgress',
      builder: (BuildContext context, GoRouterState state) =>
          const LearningProgressScreen(),
    ),
    GoRoute(
      path: '/stories',
      name: 'stories',
      builder: (BuildContext context, GoRouterState state) =>
          const StoriesHubScreen(),
    ),
    GoRoute(
      path: '/stories/:storyId',
      name: 'storyReader',
      builder: (BuildContext context, GoRouterState state) =>
          StoryReaderScreen(
        storyId: state.pathParameters['storyId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/creative',
      name: 'creative',
      builder: (BuildContext context, GoRouterState state) =>
          const CreativeHubScreen(),
    ),
    GoRoute(
      path: '/routines',
      name: 'routines',
      builder: (BuildContext context, GoRouterState state) =>
          const RoutinePlannerScreen(),
    ),
    GoRoute(
      path: '/routines/task/:taskId',
      name: 'taskGuidance',
      builder: (BuildContext context, GoRouterState state) =>
          TaskGuidanceScreen(
        taskId: state.pathParameters['taskId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/timer',
      name: 'timer',
      builder: (BuildContext context, GoRouterState state) =>
          const VisualTimerScreen(),
    ),
    GoRoute(
      path: '/reminders',
      name: 'reminders',
      builder: (BuildContext context, GoRouterState state) =>
          const RemindersScreen(),
    ),
    GoRoute(
      path: '/calm',
      name: 'calm',
      builder: (BuildContext context, GoRouterState state) =>
          const CalmSpaceScreen(),
    ),
    GoRoute(
      path: '/safety',
      name: 'safety',
      builder: (BuildContext context, GoRouterState state) =>
          const SafetyScreen(),
    ),
    GoRoute(
      path: '/trusted-contacts',
      name: 'trustedContacts',
      builder: (BuildContext context, GoRouterState state) =>
          const TrustedContactsScreen(),
    ),
    GoRoute(
      path: '/lost-mode',
      name: 'lostMode',
      builder: (BuildContext context, GoRouterState state) =>
          const LostChildModeScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (BuildContext context, GoRouterState state) =>
          const ProfileScreen(),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (BuildContext context, GoRouterState state) =>
          const NotificationCenterScreen(),
    ),

    // ---- Role-specific dashboards ----
    GoRoute(
      path: '/admin-dashboard',
      name: 'adminDashboard',
      builder: (BuildContext context, GoRouterState state) =>
          const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/therapist-dashboard',
      name: 'therapistDashboard',
      builder: (BuildContext context, GoRouterState state) =>
          const TherapistDashboardScreen(),
    ),
    GoRoute(
      path: '/caregiver-dashboard',
      name: 'caregiverDashboard',
      builder: (BuildContext context, GoRouterState state) =>
          const CaregiverDashboardScreen(),
    ),
    // ---- Parent mode ----
    GoRoute(
      path: '/parent-dashboard',
      name: 'parentDashboard',
      builder: (BuildContext context, GoRouterState state) =>
          const ParentDashboardScreen(),
    ),
    GoRoute(
      path: '/parent/child',
      name: 'childManagement',
      builder: (BuildContext context, GoRouterState state) =>
          const ChildManagementScreen(),
    ),
    GoRoute(
      path: '/parent/content',
      name: 'contentManagement',
      builder: (BuildContext context, GoRouterState state) =>
          const ContentManagementScreen(),
    ),
    GoRoute(
      path: '/parent/home-layout',
      name: 'homeLayout',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeLayoutScreen(),
    ),
    GoRoute(
      path: '/collaboration',
      name: 'collaboration',
      builder: (BuildContext context, GoRouterState state) =>
          const CollaborationScreen(),
    ),
    GoRoute(
      path: '/reports',
      name: 'reports',
      builder: (BuildContext context, GoRouterState state) =>
          const ReportsScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
  ],
);
