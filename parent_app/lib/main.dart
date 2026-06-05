import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Snitch prototype screens
import 'screens/snitch/snitch_dashboard.dart';
import 'screens/snitch/snitch_assignments.dart';
import 'screens/snitch/snitch_marks.dart';
import 'screens/snitch/snitch_login.dart';
import 'screens/snitch/academic_parent_pages.dart';
import 'screens/snitch/snitch_preview.dart';
import 'services/snitch_api.dart';
import 'theme/snitch_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocalAlertService.initialize();
  runApp(const ParentApp());
}

class LocalAlertService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
  }

  static Future<void> showOverdueFeeAlert({
    required int notificationId,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'fee_alerts',
      'Fee Alerts',
      channelDescription: 'Overdue and due fee reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.show(
      notificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}

class ParentApp extends StatefulWidget {
  const ParentApp({super.key});

  @override
  State<ParentApp> createState() => _ParentAppState();
}

class _ParentAppState extends State<ParentApp> {
  Future<bool>? _hasToken;

  @override
  void initState() {
    super.initState();
    _hasToken = _checkToken();
  }

  Future<bool> _checkToken() async {
    final parentId = await SnitchApi.getParentId();
    return parentId != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SnitchTheme.light(),
      scrollBehavior: const NoStretchScrollBehavior(),
      routes: {
        '/snitch/preview': (ctx) => const SnitchPreview(),
        '/snitch/dashboard': (ctx) => const SnitchDashboard(),
        '/snitch/assignments': (ctx) => const SnitchAssignments(),
        '/snitch/marks': (ctx) => const SnitchMarks(),
        '/snitch/login': (ctx) => const SnitchLogin(),
        '/snitch/attendance': (ctx) => const AttendanceTrackingPage(),
        '/snitch/timetable': (ctx) => const StudentTimetablePage(),
        '/snitch/communication': (ctx) => const CommunicationCenterPage(),
        '/snitch/grades': (ctx) => const GradesPerformancePage(),
        '/snitch/calendar': (ctx) => const SchoolCalendarPage(),
        '/snitch/support': (ctx) => const SupportHelpPage(),
        '/snitch/settings': (ctx) => const SettingsPage(),
        '/snitch/student-info': (ctx) => const StudentInfoPage(),
      },
      home: FutureBuilder<bool>(
        future: _hasToken,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          final has = snap.data ?? false;
          return has ? const SnitchDashboard() : const SnitchLogin();
        },
      ),
    );
  }
}

class NoStretchScrollBehavior extends MaterialScrollBehavior {
  const NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
