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
  final String? imageUrl;
  final bool showBack;

  const AppSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10, bottom: 14),
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
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
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
          (imageUrl != null && imageUrl!.isNotEmpty)
              ? ClipOval(
                  child: Image.network(
                    "$apiBaseUrl$imageUrl",
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) {
                      return Icon(icon, color: Colors.white, size: 30);
                    },
                  ),
                )
              : Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
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
        final userId = data["user_id"];

        if (!mounted) {
          return;
        }

        if (parentId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Parent profile not found")),
          );
          return;
        }

        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User profile not found")),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentListScreen(
              parentId: parentId,
              userId: userId,
            ),
          ),
        );
      } else {
        String message = "Login failed";
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map) {
            if (errorData["non_field_errors"] is List) {
              final errors = errorData["non_field_errors"] as List;
              if (errors.isNotEmpty) {
                message = errors.first.toString();
              }
            } else if (errorData["detail"] != null) {
              message = errorData["detail"].toString();
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
  final int userId;

  const StudentListScreen({
    super.key,
    required this.parentId,
    required this.userId,
  });

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class DashboardScreen extends StatefulWidget {
  final int userId;
  final int studentId;
  final int parentId;
  final int classId;
  final String studentName;
  final String? studentImage;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.studentId,
    required this.parentId,
    required this.classId,
    required this.studentName,
    this.studentImage,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool hasMultipleChildren = false;
  String attendancePercent = "-";
  String marksAverage = "-";

  @override
  void initState() {
    super.initState();
    checkMultipleChildren();
    fetchDashboardStats();
  }

  Future<void> checkMultipleChildren() async {
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
          setState(() {
            hasMultipleChildren = decoded.length > 1;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> fetchDashboardStats() async {
    try {
      final attendanceResponse = await http.get(
        Uri.parse("$apiBaseUrl/api/student/${widget.studentId}/attendance/"),
      );

      final marksResponse = await http.get(
        Uri.parse("$apiBaseUrl/api/student/${widget.studentId}/marks/"),
      );

      if (!mounted) {
        return;
      }

      double? computedAttendance;
      double? computedMarksAvg;

      if (attendanceResponse.statusCode == 200) {
        final attendanceData = json.decode(attendanceResponse.body);
        if (attendanceData is List && attendanceData.isNotEmpty) {
          final presentCount = attendanceData.where((entry) {
            final status = entry is Map ? entry['status']?.toString() : null;
            return status == 'PRESENT';
          }).length;
          computedAttendance = (presentCount / attendanceData.length) * 100;
        }
      }

      if (marksResponse.statusCode == 200) {
        final marksData = json.decode(marksResponse.body);
        if (marksData is List && marksData.isNotEmpty) {
          double totalScore = 0;
          int count = 0;
          for (final entry in marksData) {
            if (entry is Map) {
              final parsed = double.tryParse(entry['score'].toString());
              if (parsed != null) {
                totalScore += parsed;
                count += 1;
              }
            }
          }
          if (count > 0) {
            computedMarksAvg = totalScore / count;
          }
        }
      }

      setState(() {
        attendancePercent = computedAttendance == null
            ? "-"
            : "${computedAttendance.toStringAsFixed(0)}%";
        marksAverage = computedMarksAvg == null
            ? "-"
          : computedMarksAvg.toStringAsFixed(1);
      });
    } catch (_) {}
  }

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
      padding: const EdgeInsets.only(top: 8, bottom: 16),
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
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
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
                          userId: widget.userId,
                          parentId: widget.parentId,
                          studentId: widget.studentId,
                          studentName: widget.studentName,
                          studentImage: widget.studentImage,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message, color: Colors.white),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasMultipleChildren)
                      IconButton(
                        tooltip: "Switch Child",
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentListScreen(
                                parentId: widget.parentId,
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.switch_account, color: Colors.white),
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
                    IconButton(
                      tooltip: "Logout",
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: const Text("Logout"),
                              content: const Text(
                                "Are you sure you want to logout?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext, false);
                                  },
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext, true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("Logout"),
                                ),
                              ],
                            );
                          },
                        );

                        if (shouldLogout == true && context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: widget.studentImage != null &&
                    widget.studentImage!.toString().isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      "$apiBaseUrl${widget.studentImage}",
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 38,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  )
                : const Icon(Icons.person, size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            widget.studentName,
            style: const TextStyle(
              fontSize: 17,
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
          buildMiniCard(
            "Attendance",
            attendancePercent,
            AppColors.success,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceScreen(
                    studentId: widget.studentId,
                    studentName: widget.studentName,
                  ),
                ),
              );
            },
          ),
          buildMiniCard(
            "Marks Avg",
            marksAverage,
            AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MarksScreen(
                    studentId: widget.studentId,
                    studentName: widget.studentName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildMiniCard(
    String title,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
            ReportCardScreen(
              studentId: widget.studentId,
              studentName: widget.studentName,
              studentImage: widget.studentImage,
            ),
          ),
          buildCard(
            context,
            Icons.calendar_today,
            "Timetable",
            TimetableScreen(classId: widget.classId, studentName: widget.studentName),
          ),
          buildCard(
            context,
            Icons.check_circle,
            "Attendance",
            AttendanceScreen(
              studentId: widget.studentId,
              studentName: widget.studentName,
            ),
          ),
          buildCard(
            context,
            Icons.book,
            "Materials",
            MaterialsScreen(studentName: widget.studentName),
          ),
          buildCard(
            context,
            Icons.bar_chart,
            "Marks",
            MarksScreen(studentId: widget.studentId, studentName: widget.studentName),
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
  final String? studentImage;

  const ReportCardScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    this.studentImage,
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
              imageUrl: widget.studentImage,
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
                          itemCount: reportCards.length,
                          itemBuilder: (context, index) {
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
                                  width: 52,
                                  height: 52,
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
                                  final reportId = report['id'];
                                  final hasStoredPdf = filePath != null &&
                                      filePath.toString().isNotEmpty;

                                  // Fall back to generated PDF endpoint when no file is stored.
                                  final url = hasStoredPdf
                                      ? "$apiBaseUrl$filePath"
                                      : "$apiBaseUrl/api/reportcards/$reportId/pdf/";
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
  bool isLoading = true;
  bool isUsingSampleData = false;
  late String selectedDay;

  final List<String> weekDays = const [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];

  final List<Map<String, String>> periods = const [
    {"number": "1", "time": "08:30-09:15"},
    {"number": "2", "time": "09:15-10:00"},
    {"number": "3", "time": "10:15-11:00"},
    {"number": "4", "time": "11:00-11:45"},
    {"number": "5", "time": "12:15-01:00"},
    {"number": "6", "time": "01:00-01:45"},
  ];

  @override
  void initState() {
    super.initState();
    // Start with Monday or today's day if it's a weekday
    DateTime now = DateTime.now();
    if (now.weekday >= 1 && now.weekday <= 6) {
      // Monday=1 to Saturday=6
      selectedDay = weekDays[now.weekday - 1];
    } else {
      // If Sunday, default to Monday
      selectedDay = "Monday";
    }
    fetchTimetable();
  }

  Future<void> fetchTimetable() async {
    try {
      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/timetable/${widget.classId}/"),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          setState(() {
            timetable = decoded;
            isLoading = false;
            isUsingSampleData = false;
          });
          return;
        }
      }

      setState(() {
        timetable = sampleTimetable();
        isLoading = false;
        isUsingSampleData = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        timetable = sampleTimetable();
        isLoading = false;
        isUsingSampleData = true;
      });
    }
  }

  List<Map<String, dynamic>> sampleTimetable() {
    return [
      {
        "day_of_week": "Monday",
        "period_number": 1,
        "subject": "English",
        "teacher": "Ms. Priya",
      },
      {
        "day_of_week": "Monday",
        "period_number": 2,
        "subject": "Mathematics",
        "teacher": "Mr. Arjun",
      },
      {
        "day_of_week": "Monday",
        "period_number": 3,
        "subject": "Science",
        "teacher": "Ms. Kavya",
      },
      {
        "day_of_week": "Monday",
        "period_number": 4,
        "subject": "Social",
        "teacher": "Mr. Suresh",
      },
      {
        "day_of_week": "Monday",
        "period_number": 5,
        "subject": "Hindi",
        "teacher": "Ms. Meera",
      },
      {
        "day_of_week": "Monday",
        "period_number": 6,
        "subject": "Computer",
        "teacher": "Mr. Kiran",
      },
      {
        "day_of_week": "Tuesday",
        "period_number": 1,
        "subject": "Mathematics",
        "teacher": "Mr. Arjun",
      },
      {
        "day_of_week": "Tuesday",
        "period_number": 2,
        "subject": "English",
        "teacher": "Ms. Priya",
      },
      {
        "day_of_week": "Tuesday",
        "period_number": 3,
        "subject": "Computer",
        "teacher": "Mr. Kiran",
      },
      {
        "day_of_week": "Tuesday",
        "period_number": 4,
        "subject": "Science",
        "teacher": "Ms. Kavya",
      },
      {
        "day_of_week": "Tuesday",
        "period_number": 5,
        "subject": "Art",
        "teacher": "Ms. Ritu",
      },
      {
        "day_of_week": "Tuesday",
        "period_number": 6,
        "subject": "Sports",
        "teacher": "Coach Aman",
      },
      {
        "day_of_week": "Wednesday",
        "period_number": 1,
        "subject": "Science",
        "teacher": "Ms. Kavya",
      },
      {
        "day_of_week": "Wednesday",
        "period_number": 2,
        "subject": "Mathematics",
        "teacher": "Mr. Arjun",
      },
      {
        "day_of_week": "Wednesday",
        "period_number": 3,
        "subject": "English",
        "teacher": "Ms. Priya",
      },
      {
        "day_of_week": "Wednesday",
        "period_number": 4,
        "subject": "Social",
        "teacher": "Mr. Suresh",
      },
      {
        "day_of_week": "Wednesday",
        "period_number": 5,
        "subject": "Hindi",
        "teacher": "Ms. Meera",
      },
      {
        "day_of_week": "Wednesday",
        "period_number": 6,
        "subject": "Library",
        "teacher": "Ms. Pooja",
      },
      {
        "day_of_week": "Thursday",
        "period_number": 1,
        "subject": "English",
        "teacher": "Ms. Priya",
      },
      {
        "day_of_week": "Thursday",
        "period_number": 2,
        "subject": "Science",
        "teacher": "Ms. Kavya",
      },
      {
        "day_of_week": "Thursday",
        "period_number": 3,
        "subject": "Mathematics",
        "teacher": "Mr. Arjun",
      },
      {
        "day_of_week": "Thursday",
        "period_number": 4,
        "subject": "Computer",
        "teacher": "Mr. Kiran",
      },
      {
        "day_of_week": "Thursday",
        "period_number": 5,
        "subject": "Social",
        "teacher": "Mr. Suresh",
      },
      {
        "day_of_week": "Thursday",
        "period_number": 6,
        "subject": "GK",
        "teacher": "Ms. Nisha",
      },
      {
        "day_of_week": "Friday",
        "period_number": 1,
        "subject": "Mathematics",
        "teacher": "Mr. Arjun",
      },
      {
        "day_of_week": "Friday",
        "period_number": 2,
        "subject": "English",
        "teacher": "Ms. Priya",
      },
      {
        "day_of_week": "Friday",
        "period_number": 3,
        "subject": "Science",
        "teacher": "Ms. Kavya",
      },
      {
        "day_of_week": "Friday",
        "period_number": 4,
        "subject": "Hindi",
        "teacher": "Ms. Meera",
      },
      {
        "day_of_week": "Friday",
        "period_number": 5,
        "subject": "Sports",
        "teacher": "Coach Aman",
      },
      {
        "day_of_week": "Friday",
        "period_number": 6,
        "subject": "Art",
        "teacher": "Ms. Ritu",
      },
      {
        "day_of_week": "Saturday",
        "period_number": 1,
        "subject": "English",
        "teacher": "Ms. Priya",
      },
      {
        "day_of_week": "Saturday",
        "period_number": 2,
        "subject": "Mathematics",
        "teacher": "Mr. Arjun",
      },
      {
        "day_of_week": "Saturday",
        "period_number": 3,
        "subject": "Science",
        "teacher": "Ms. Kavya",
      },
      {
        "day_of_week": "Saturday",
        "period_number": 4,
        "subject": "Club Activity",
        "teacher": "Class Teacher",
      },
    ];
  }

  List<Map<String, dynamic>> getTimetableForDay(String day) {
    return timetable
        .cast<Map<String, dynamic>>()
        .where((entry) => entry['day_of_week']?.toString().toLowerCase() == day.toLowerCase())
        .toList()
        ..sort((a, b) => int.parse(a['period_number'].toString())
            .compareTo(int.parse(b['period_number'].toString())));
  }

  String getDayShorthand(String day) {
    return day.substring(0, 3).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dayTimetable = getTimetableForDay(selectedDay);

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
            // Day Selector Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: weekDays.map((day) {
                    final isSelected = day == selectedDay;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDay = day;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.primary : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getDayShorthand(day),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Timetable Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : dayTimetable.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 48,
                                color: Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No classes on $selectedDay",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (isUsingSampleData)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.badge.withAlpha(35),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  "Showing sample timetable data",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ...dayTimetable.asMap().entries.map((entry) {
                              final item = entry.value;
                              final subject = item['subject'] ?? '-';
                              final teacher = item['teacher'] ?? '-';
                              final periodNum = item['period_number'] ?? '-';
                              final periodInfo = periods.firstWhere(
                                (p) =>
                                    p['number'] ==
                                    periodNum.toString(),
                                orElse: () => {
                                  'time': 'N/A',
                                  'number': periodNum.toString()
                                },
                              );
                              final time = periodInfo['time'] ?? 'N/A';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  color: AppColors.card,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Period Badge
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withAlpha(26),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "P$periodNum",
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                Text(
                                                  time,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Subject and Teacher
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                subject,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                teacher,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
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
                      itemCount: attendance.length,
                      itemBuilder: (context, index) {
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
                      itemCount: marks.length,
                      itemBuilder: (context, index) {
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
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
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
                      itemCount: materials.length,
                      itemBuilder: (context, index) {
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
  final int userId;
  final int parentId;
  final int studentId;
  final String studentName;
  final String? studentImage;

  const MessagesScreen({
    super.key,
    required this.userId,
    required this.parentId,
    required this.studentId,
    required this.studentName,
    this.studentImage,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List chats = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  List get groupChatsOnly {
    return chats.where((chat) => chat['is_group'] == true).toList();
  }

  List get directChatsOnly {
    return chats.where((chat) => chat['is_group'] != true).toList();
  }

  List get activeDirectChats {
    return directChatsOnly.where((chat) {
      final lastMessage = (chat['last_message'] ?? '').toString().trim();
      return lastMessage.isNotEmpty;
    }).toList();
  }

  List get teacherSearchResults {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return const [];
    }

    return directChatsOnly.where((chat) {
      final roomName = (chat['name'] ?? '').toString().toLowerCase();
      final className = (chat['class_name'] ?? '').toString().toLowerCase();
      final memberNames = ((chat['member_names'] as List?) ?? [])
          .map((e) => e.toString().toLowerCase())
          .join(' ');

      return roomName.contains(query) ||
          className.contains(query) ||
          memberNames.contains(query);
    }).toList();
  }

  List get filteredChats {
    if (searchQuery.trim().isNotEmpty) {
      return teacherSearchResults;
    }

    return [...groupChatsOnly, ...activeDirectChats];
  }

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchChats() async {
    try {
      final response = await http.get(
        Uri.parse(
          "$apiBaseUrl/api/chats/v2/?user_id=${widget.userId}&student_id=${widget.studentId}",
        ),
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
              imageUrl: widget.studentImage,
            ),
            if (!isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search teachers to start chat...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                searchQuery = "";
                              });
                            },
                          )
                        : null,
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
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredChats.isEmpty
                  ? Center(
                      child: Text(
                        searchQuery.trim().isEmpty
                            ? "No chats found"
                            : "No teachers found",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredChats.length,
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
                        final roomName = chat['name'] ?? 'Chat';
                        final isGroup = chat['is_group'] == true;
                        final className = chat['class_name'] ?? '';
                        final memberNames = (chat['member_names'] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                          <String>[];
                        final lastMessage = chat['last_message'] ?? '';
                        final roomId = chat['room_id'];

                        final subtitleText = lastMessage.isEmpty
                          ? (isGroup
                            ? (className.isEmpty
                              ? "No messages yet"
                              : "$className • Group chat")
                            : "Tap to start conversation")
                          : lastMessage;

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
                                color: isGroup
                                    ? AppColors.badge.withAlpha(45)
                                    : AppColors.primary.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isGroup ? Icons.groups : Icons.support_agent,
                                color: isGroup
                                    ? const Color(0xFF92400E)
                                    : AppColors.primary,
                              ),
                            ),
                            title: Text(
                              roomName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              isGroup && memberNames.isNotEmpty
                                  ? "$subtitleText\n${memberNames.take(2).join(', ')}"
                                  : subtitleText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.black45,
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                    roomId: roomId,
                                    userId: widget.userId,
                                    roomName: roomName,
                                    subtitle: isGroup ? className : widget.studentName,
                                    isGroup: isGroup,
                                  ),
                                ),
                              );

                              if (mounted) {
                                fetchChats();
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

class ChatDetailScreen extends StatefulWidget {
  final int roomId;
  final int userId;
  final String roomName;
  final String subtitle;
  final bool isGroup;

  const ChatDetailScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.roomName,
    required this.subtitle,
    required this.isGroup,
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
        Uri.parse(
          "$apiBaseUrl/api/chats/v2/rooms/${widget.roomId}/messages/?user_id=${widget.userId}",
        ),
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
        Uri.parse("$apiBaseUrl/api/chats/v2/rooms/${widget.roomId}/messages/"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": widget.userId,
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
              icon: widget.isGroup ? Icons.groups : Icons.chat,
              title: widget.roomName,
              subtitle: widget.subtitle,
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
                            final isCurrentUser =
                                message['sender_id'] == widget.userId;
                            return Align(
                              alignment: isCurrentUser
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
                                  color: isCurrentUser
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
                                        color: isCurrentUser
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message['content'] ?? '',
                                      style: TextStyle(
                                        color: isCurrentUser
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
                  userId: widget.userId,
                  studentId: student['id'],
                  parentId: widget.parentId,
                  classId: student['class_id'],
                  studentName: student['name'],
                  studentImage: student['image'],
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
                          itemCount: students.length,
                          itemBuilder: (context, index) {
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
                                  child: student['image'] != null &&
                                          student['image']
                                              .toString()
                                              .isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            "$apiBaseUrl${student['image']}",
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              _,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Icon(
                                                Icons.person,
                                                color: AppColors.primary,
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(
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
                                        userId: widget.userId,
                                        studentId: student['id'],
                                        parentId: widget.parentId,
                                        classId: student['class_id'],
                                        studentName: student['name'],
                                        studentImage: student['image'],
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
