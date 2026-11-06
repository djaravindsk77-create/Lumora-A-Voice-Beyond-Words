#!/usr/bin/perl
# Cross-reference checker: flags capitalized identifiers that are neither
# defined in the project nor in the allow-list of SDK/third-party symbols.
use strict;
use warnings;
use File::Find;

my @files;
find(sub { push @files, $File::Find::name if /\.dart$/ && $File::Find::name !~ m{\btool\b} }, 'lib', 'test');

my %defines;
for my $f (@files) {
    open my $fh, '<', $f or next;
    local $/;
    my $src = <$fh>;
    close $fh;
    while ($src =~ /\b(?:class|enum|mixin|extension)\s+([A-Z]\w+)/g) {
        $defines{$1} = $f;
    }
}

# Allow-list: Flutter SDK, third-party packages, Dart core, test framework.
my $allow = <<'EOF';
Widget BuildContext StatelessWidget StatefulWidget State Color Colors IconData Icon Text
EdgeInsets EdgeInsetsSymmetric EdgeInsetsOnly EdgeInsetsAll EdgeInsetsFromLTRB SizedBox Column
Row Center Container Padding Align Stack Positioned Expanded Flexible ListView GridView
GridViewCount GridViewExtent Card ListTile CircleAvatar Chip InputChip ChoiceChip FilterChip
ActionChip Switch SwitchListTile CheckboxListTile Checkbox Radio RadioListTile Slider TextField
TextFormField TextEditingController InputDecoration OutlineInputBorder InputBorder
UnderlineInputBorder BorderSide RoundedRectangleBorder BorderRadius Radius Circular BoxBorder
Border BorderAll BoxShadow BoxDecoration ShapeDecoration Gradient LinearGradient
SweepGradient RadialGradient GlobalKey FormState GlobalKeyState Navigator PageRouteBuilder
PageRoute ScrollController AnimationController TweenAnimationBuilder AnimatedBuilder AnimatedContainer
AnimatedOpacity AnimatedSwitcher FadeTransition SlideTransition ScaleTransition Tween Curves
Duration Curve TextStyle FontWeight TextAlign MainAxisSize CrossAxisAlignment mainAxisAlignment
OverflowBox ClipRRect ClipOval ClipPath Material InkWell GestureDetector Ink Wrap Spacer
ConstrainedBox Constraints BoxConstraints FractionallySizedBox AspectRatio Placeholder Divider
LinearProgressIndicator CircularProgressIndicator RefreshIndicator DropdownButtonFormField
DropdownButton DropdownMenuItem PopupMenuButton PopupMenuItem PopupMenuDivider SegmentedButton
ButtonSegment Semantics Tooltip DefaultTabController TabBar TabBarView Tab TabController
ReorderableListView ReorderableDragStartNotifier Dismissible NotificationListener
CustomPaint CustomPainter Canvas Paint Offset Rect Size PaintingStyle StrokeCap TextPainter
TextDirection ValueDirection ExpansionTile ExpansionPanelList FlowTableTable RowColumn
MultiProvider ChangeNotifierProvider ProxyProvider ConsumerProvider ListenableProvider
Provider Consumer ConsumerState ChangeNotifier SingleChildWidget MultiWidgetProvider
MaterialApp WidgetsApp CupertinoApp TitleAction AppBar AppBarTheme BottomNavigationBar
NavigationBar NavigationRail Drawer DrawerHeader EndDrawer FloatingActionButton
Scaffold ScaffoldMessenger SnackBar SnackBarBehavior BottomSheet showBottomSheet
showDialog showGeneralDialog showTimePicker showDatePicker showSearch FutureBuilder
StreamBuilder Builder LayoutBuilder OrientationBuilder AspectRatioWidget Theme ThemeData
ThemeMode Brightness TextTheme ColorScheme ColorSchemeLight ColorSchemeDark MaterialState
WidgetState WidgetStateProperty VisualDensity FontFeature Locale Localex Directionality
LocalizationsDelegate Localizations WidgetsLocalizations Delegate SupportedLocales
SemanticsService SystemSound SystemChrome SystemNavigator HapticFeedback DeviceOrientation
SystemUiOverlayStyle SystemUiOverlay Exception FormatException ArgumentError StateError
WidgetsBinding WidgetsFlutterBinding TestWidgetsFlutterBinding TestDefaultBinaryMessenger
Key ValueKey KeyInt KeyString UniqueKey GlobalObjectKey Object String int double bool num
dynamic void var final const late required this super null true false override
SharedPreferences SharedPreferencesAsync SharedPreferencesWithCache PackageInfo Uuid
Http http Response Request FlutterTts SpeechToText SpeechListenOptions ListenOptions
AudioPlayer PlayerState DeviceFileSource UrlSource AssetSource ReleaseMode
FlutterLocalNotificationsPlugin AndroidInitializationSettings DarwinInitializationSettings
InitializationSettings AndroidNotificationDetails AndroidScheduleMode NotificationDetails
DarwinNotificationDetails Importance Priority Permission NotificationAppLaunchDetails
tz tzdata TZDateTime Location TimeOfDay DateTime DateFormat NumberFormat
ImagePicker ImageSource XFile File FileImage MemoryImage NetworkImage Image ImageWidget
FirebaseApp FirebaseOptions DefaultFirebaseOptions FirebaseAuth FirebaseAuthException
FirebaseAuthUserCollisionException User UserCredential UserMetadata FirebaseFirestore
CollectionReference DocumentReference QuerySnapshot QueryDocumentSnapshot DocumentSnapshot
WriteBatch Transaction FieldValue Timestamp GeoPoint SetOptions Source SnapshotOptions
GoRouter GoRouterState GoRoute ShellRoute StatefulShellRoute RouteBase RouterConfig
NavigatorObserver CustomTransitionPage NoTransitionPage RedirectLogic
FlTitlesData AxisTitles SideTitles BarChart BarChartData BarChartGroupData BarChartRodData
FlGridData FlLine FlBorderData FlDotData PieChart PieChartData PieChartSectionData
TitleMeta LineChart LineChartData LineChartBarData FlSpot Interval BetweenBarsData
SemanticsFlag SemanticsProperties MergeSemantics ExcludeSemantics
TestGesture WidgetTester Finder CommonFinders FindsOneWidget FindsNothing FindsWidgets
AssetImage ExactAssetImage SVGPicture LottieComposition
EOF
my %allowed = map { $_ => 1 } split /\s+/, $allow;

my %missing;
for my $f (@files) {
    open my $fh, '<', $f or next;
    local $/;
    my $src = <$fh>;
    close $fh;
    # Strip comments and string literals.
    $src =~ s{/\*.*?\*/}{}gs;
    $src =~ s{//[^\n]*}{}g;
    $src =~ s{r?'(?:[^'\\]|\\.)*'}{''}gs;
    $src =~ s{r?"(?:[^"\\]|\\.)*"}{""}gs;
    while ($src =~ /\b([A-Z][A-Za-z0-9_]{2,})\b/g) {
        my $id = $1;
        next if $allowed{$id} || $defines{$id};
        $missing{"$id"}{$f} = 1;
    }
}

my $total = scalar keys %missing;
print "$total unresolved identifier(s)\n";
for my $id (sort keys %missing) {
    my @fs = sort keys %{ $missing{$id} };
    my $n = scalar @fs;
    print " - $id ($n file(s)): $fs[0]\n";
}
