import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

String get apiBaseUrl {
  if (kIsWeb) {
    return "http://127.0.0.1:8000";
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return "http://10.0.2.2:8000";
  }

  return "http://127.0.0.1:8000";
}

class AppColors {
  static const primary = Color(0xFF1E3A8A);
  static const gradientEnd = Color(0xFF2563EB);
  static const card = Colors.white;
  static const badge = Color(0xFFF59E0B);
  static const success = Color(0xFF16A34A);
}

void main() {
  runApp(const ParentApp());
}

class ParentApp extends StatelessWidget {
  const ParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: NoStretchScrollBehavior(),
      home: SplashScreen(),
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

class AppSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool showBack;

  const AppSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 28, bottom: 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.gradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          if (showBack)
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
              ],
            ),
          Icon(icon, color: Colors.white, size: 44),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class PoweredByQuadeltFooter extends StatelessWidget {
  const PoweredByQuadeltFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8, bottom: 16),
      child: Center(
        child: Text(
          "Powered by Quadelt",
          style: TextStyle(
            fontSize: 11,
            color: Colors.black38,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.gradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, color: Colors.white, size: 64),
                  SizedBox(height: 16),
                  Text(
                    "School Platform",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Parent App",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 22),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (isLoading) {
      return;
    }

    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter username and password")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/api/login/"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parentId = data["parent_id"];

        if (!mounted) {
          return;
        }

        if (parentId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Parent profile not found")),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentListScreen(
              parentId: parentId,
            ),
          ),
        );
      } else {
        String message = "Login failed";
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData["non_field_errors"] is List) {
            final errors = errorData["non_field_errors"] as List;
            if (errors.isNotEmpty) {
              message = errors.first.toString();
            }
          }
        } catch (_) {}

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot connect to server")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            const AppSectionHeader(
              icon: Icons.school,
              title: "Parent Login",
              subtitle: "Sign in to view your child dashboard",
              showBack: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Card(
                      color: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: usernameController,
                              enabled: !isLoading,
                              decoration: const InputDecoration(
                                labelText: "Username",
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: passwordController,
                              enabled: !isLoading,
                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            isPasswordVisible =
                                                !isPasswordVisible;
                                          });
                                        },
                                  icon: Icon(
                                    isPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              obscureText: !isPasswordVisible,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        "Login",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const PoweredByQuadeltFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentListScreen extends StatefulWidget {
  final int parentId;

  const StudentListScreen({super.key, required this.parentId});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class DashboardScreen extends StatelessWidget {
  final int studentId;
  final int parentId;
  final int classId;
  final String studentName;

  const DashboardScreen({
    super.key,
    required this.studentId,
    required this.parentId,
    required this.classId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildHeader(context),
              const SizedBox(height: 20),
              buildStatsRow(),
              const SizedBox(height: 20),
              buildMainCards(context),
              const SizedBox(height: 16),
              const PoweredByQuadeltFooter(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNav(context),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.gradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessagesScreen(
                          parentId: parentId,
                          studentName: studentName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Icon(Icons.person, size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: 15),
          Text(
            studentName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildMiniCard("Attendance", "76%", AppColors.success),
          buildMiniCard("Marks Avg", "82%", AppColors.primary),
        ],
      ),
    );
  }

  Widget buildMiniCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget buildMainCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          buildCard(
            context,
            Icons.assignment,
            "Assignments",
            const AssignmentsScreen(),
          ),
          buildCard(
            context,
            Icons.description,
            "Report Card",
            ReportCardScreen(studentId: studentId, studentName: studentName),
          ),
          buildCard(
            context,
            Icons.calendar_today,
            "Timetable",
            TimetableScreen(classId: classId, studentName: studentName),
          ),
          buildCard(
            context,
            Icons.check_circle,
            "Attendance",
            AttendanceScreen(studentId: studentId, studentName: studentName),
          ),
          buildCard(
            context,
            Icons.book,
            "Materials",
            MaterialsScreen(studentName: studentName),
          ),
          buildCard(
            context,
            Icons.bar_chart,
            "Marks",
            MarksScreen(studentId: studentId, studentName: studentName),
          ),
        ],
      ),
    );
  }

  Widget buildCard(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HappeningsScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: "Dashboard",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: "Happenings",
        ),
      ],
    );
  }
}

class ReportCardScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const ReportCardScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends State<ReportCardScreen> {
  List reportCards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReportCards();
  }

  Future<void> fetchReportCards() async {
    try {
      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/student/${widget.studentId}/reportcards/"),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        setState(() {
          reportCards = json.decode(response.body);
          isLoading = false;
        });
        return;
      }

      setState(() {
        reportCards = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to load report cards")),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        reportCards = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot connect to server")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              icon: Icons.description,
              title: "Report Card",
              subtitle: widget.studentName,
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : reportCards.isEmpty
                      ? const Center(
                          child: Text(
                            "No report cards available",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: reportCards.length + 1,
                          itemBuilder: (context, index) {
                            if (index == reportCards.length) {
                              return const PoweredByQuadeltFooter();
                            }
                            final report = reportCards[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              color: AppColors.card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(26),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.picture_as_pdf,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  report['exam'] ?? 'Report Card',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  report['generated_on']
                                          ?.toString()
                                          .split('T')
                                          .first ??
                                      '',
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.black45,
                                ),
                                onTap: () async {
                                  final filePath = report['pdf_file'];
                                  if (filePath == null ||
                                      filePath.toString().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("PDF not available"),
                                      ),
                                    );
                                    return;
                                  }

                                  final url = "$apiBaseUrl$filePath";
                                  final uri = Uri.parse(url);

                                  final launched = await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );

                                  if (!launched && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Could not open PDF"),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            const AppSectionHeader(
              icon: Icons.assignment,
              title: "Assignments",
            ),
            const Expanded(
              child: Center(
                child: Text(
                  "Coming soon",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HappeningsScreen extends StatelessWidget {
  const HappeningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Happenings")),
      body: const Center(
        child: Text("Coming soon"),
      ),
    );
  }
}

class TimetableScreen extends StatefulWidget {
  final int classId;
  final String studentName;

  const TimetableScreen({
    super.key,
    required this.classId,
    required this.studentName,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List timetable = [];

  @override
  void initState() {
    super.initState();
    fetchTimetable();
  }

  Future<void> fetchTimetable() async {
    final response = await http.get(
      Uri.parse("$apiBaseUrl/api/timetable/${widget.classId}/"),
    );

    if (response.statusCode == 200) {
      setState(() {
        timetable = json.decode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              icon: Icons.calendar_today,
              title: "Timetable",
              subtitle: widget.studentName,
            ),
            Expanded(
              child: timetable.isEmpty
                  ? const Center(
                      child: Text(
                        "No timetable available",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: timetable.length + 1,
                      itemBuilder: (context, index) {
                        if (index == timetable.length) {
                          return const PoweredByQuadeltFooter();
                        }
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          color: AppColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.schedule,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              "${timetable[index]['day_of_week']} - Period ${timetable[index]['period_number']}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              "${timetable[index]['subject']} (${timetable[index]['teacher']})",
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const AttendanceScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List attendance = [];

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    final response = await http.get(
      Uri.parse(
        "$apiBaseUrl/api/student/${widget.studentId}/attendance/",
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        attendance = json.decode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              icon: Icons.check_circle,
              title: "Attendance",
              subtitle: widget.studentName,
            ),
            Expanded(
              child: attendance.isEmpty
                  ? const Center(
                      child: Text(
                        "No attendance records",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: attendance.length + 1,
                      itemBuilder: (context, index) {
                        if (index == attendance.length) {
                          return const PoweredByQuadeltFooter();
                        }
                        final isPresent = attendance[index]['status'] ==
                            "PRESENT";
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          color: AppColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            title: Text(
                              attendance[index]['date'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(attendance[index]['status']),
                            trailing: Icon(
                              isPresent ? Icons.check_circle : Icons.cancel,
                              color: isPresent ? AppColors.success : Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarksScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const MarksScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  List marks = [];

  @override
  void initState() {
    super.initState();
    fetchMarks();
  }

  Future<void> fetchMarks() async {
    final response = await http.get(
      Uri.parse(
        "$apiBaseUrl/api/student/${widget.studentId}/marks/",
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        marks = json.decode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              icon: Icons.bar_chart,
              title: "Marks",
              subtitle: widget.studentName,
            ),
            Expanded(
              child: marks.isEmpty
                  ? const Center(
                      child: Text(
                        "No marks available",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: marks.length + 1,
                      itemBuilder: (context, index) {
                        if (index == marks.length) {
                          return const PoweredByQuadeltFooter();
                        }
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          color: AppColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.assessment,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              marks[index]['subject'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(marks[index]['exam']),
                            trailing: Text(
                              marks[index]['score'].toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final response = await http.get(
      Uri.parse("$apiBaseUrl/api/announcements/"),
    );

    if (response.statusCode == 200) {
      setState(() {
        notifications = json.decode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            const AppSectionHeader(
              icon: Icons.notifications,
              title: "Notifications",
            ),
            Expanded(
              child: notifications.isEmpty
                  ? const Center(
                      child: Text(
                        "No notifications available",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: notifications.length + 1,
                      itemBuilder: (context, index) {
                        if (index == notifications.length) {
                          return const PoweredByQuadeltFooter();
                        }
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          color: AppColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.campaign,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              notifications[index]['title'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(notifications[index]['body']),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class MaterialsScreen extends StatefulWidget {
  final String studentName;

  const MaterialsScreen({super.key, required this.studentName});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  List materials = [];

  @override
  void initState() {
    super.initState();
    fetchMaterials();
  }

  Future<void> fetchMaterials() async {
    final response = await http.get(
      Uri.parse("$apiBaseUrl/api/materials/"),
    );

    if (response.statusCode == 200) {
      setState(() {
        materials = json.decode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              icon: Icons.book,
              title: "Materials",
              subtitle: widget.studentName,
            ),
            Expanded(
              child: materials.isEmpty
                  ? const Center(
                      child: Text(
                        "No materials available",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: materials.length + 1,
                      itemBuilder: (context, index) {
                        if (index == materials.length) {
                          return const PoweredByQuadeltFooter();
                        }
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          color: AppColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              materials[index]['title'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(materials[index]['subject']),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.black45,
                            ),
                            onTap: () async {
                              final url = "$apiBaseUrl${materials[index]['file']}";
                              final uri = Uri.parse(url);

                              final launched = await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );

                              if (!launched) {
                                debugPrint("Could not launch $url");
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesScreen extends StatefulWidget {
  final int parentId;
  final String studentName;

  const MessagesScreen({
    super.key,
    required this.parentId,
    required this.studentName,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List chats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    try {
      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/chats/${widget.parentId}/"),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        setState(() {
          chats = json.decode(response.body);
          isLoading = false;
        });
        return;
      }

      setState(() {
        chats = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to load chats")),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        chats = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot connect to server")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              icon: Icons.message,
              title: "Messages",
              subtitle: widget.studentName,
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : chats.isEmpty
                  ? const Center(
                      child: Text(
                        "No conversations available",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: chats.length + 1,
                      itemBuilder: (context, index) {
                        if (index == chats.length) {
                          return const PoweredByQuadeltFooter();
                        }
                        final chat = chats[index];
                        final studentName = chat['student_name'] ?? '';
                        final teacherName = chat['teacher_name'] ?? '';
                        final lastMessage = chat['last_message'] ?? '';
                        final threadId = chat['thread_id'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          color: AppColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.support_agent,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              teacherName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              lastMessage.isEmpty
                                  ? "Tap to start conversation"
                                  : "$studentName • $lastMessage",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.black45,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                    threadId: threadId,
                                    parentId: widget.parentId,
                                    studentName: studentName,
                                    teacherName: teacherName,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final int threadId;
  final int parentId;
  final String studentName;
  final String teacherName;

  const ChatDetailScreen({
    super.key,
    required this.threadId,
    required this.parentId,
    required this.studentName,
    required this.teacherName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController messageController = TextEditingController();
  List messages = [];
  bool isLoading = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/chats/thread/${widget.threadId}/messages/"),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        setState(() {
          messages = json.decode(response.body);
          isLoading = false;
        });
        return;
      }

      setState(() {
        messages = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to load messages")),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        messages = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot connect to server")),
      );
    }
  }

  Future<void> sendMessage() async {
    if (isSending) {
      return;
    }

    final content = messageController.text.trim();
    if (content.isEmpty) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/api/chats/thread/${widget.threadId}/send/"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "parent_id": widget.parentId,
          "content": content,
        }),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        setState(() {
          messages = [...messages, data];
        });
        messageController.clear();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to send message")),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot connect to server")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              icon: Icons.chat,
              title: widget.teacherName,
              subtitle: widget.studentName,
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? const Center(
                          child: Text(
                            "No messages yet",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isParent = message['sender_role'] == 'PARENT';
                            return Align(
                              alignment: isParent
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                constraints: const BoxConstraints(maxWidth: 280),
                                decoration: BoxDecoration(
                                  color: isParent
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['sender_name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isParent
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message['content'] ?? '',
                                      style: TextStyle(
                                        color: isParent
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: const Color(0xFFF3F4F6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      enabled: !isSending,
                      decoration: InputDecoration(
                        hintText: "Type a message",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: isSending ? null : sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _StudentListScreenState extends State<StudentListScreen> {
  List students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/parent/${widget.parentId}/students/"),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          if (decoded.length == 1) {
            final student = decoded.first;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardScreen(
                  studentId: student['id'],
                  parentId: widget.parentId,
                  classId: student['class_id'],
                  studentName: student['name'],
                ),
              ),
            );
            return;
          }

          setState(() {
            students = decoded;
            isLoading = false;
          });
          return;
        }
      }

      setState(() {
        students = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to fetch children right now")),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        students = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot connect to server")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            const AppSectionHeader(
              icon: Icons.family_restroom,
              title: "Choose Child",
              subtitle: "Select a child to open dashboard",
              showBack: false,
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : students.isEmpty
                      ? const Center(
                          child: Text(
                            "No children found",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: students.length + 1,
                          itemBuilder: (context, index) {
                            if (index == students.length) {
                              return const PoweredByQuadeltFooter();
                            }
                            final student = students[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              color: AppColors.card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(26),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  student['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.black45,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DashboardScreen(
                                        studentId: student['id'],
                                        parentId: widget.parentId,
                                        classId: student['class_id'],
                                        studentName: student['name'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
