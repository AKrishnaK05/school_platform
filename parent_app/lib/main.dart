import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppColors {
  static const primaryGradientStart = Color(0xFFFF8A65);
  static const primaryGradientEnd = Color(0xFFFFC107);
  static const cardBackground = Color(0xFFF5F1E8);
  static const accent = Color(0xFFFFA726);
  static const darkText = Color(0xFF333333);
}

void main() {
  runApp(const MaterialApp(home: LoginScreen()));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> login() async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8000/api/login/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "username": usernameController.text,
        "password": passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentListScreen(
            parentId: data["parent_id"],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parent Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text("Login"),
            )
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
  final String studentName;

  const DashboardScreen({super.key, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildHeader(),
              const SizedBox(height: 20),
              buildTimetableCard(),
              const SizedBox(height: 20),
              buildQuickActions(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNav(),
    );
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGradientStart,
            AppColors.primaryGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Dashboard",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                studentName,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Icon(Icons.notifications, color: Colors.white),
        ],
      ),
    );
  }

  Widget buildTimetableCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryGradientStart,
            AppColors.primaryGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Timetable",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Math - 10:00 AM",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        children: [
          buildTile(Icons.campaign, "Announcements"),
          buildTile(Icons.check_circle, "Attendance"),
          buildTile(Icons.bar_chart, "Marks"),
          buildTile(Icons.book, "Materials"),
          buildTile(Icons.chat, "Messages"),
        ],
      ),
    );
  }

  Widget buildTile(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.accent),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          )
        ],
      ),
    );
  }

  Widget buildBottomNav() {
    return BottomNavigationBar(
      selectedItemColor: AppColors.accent,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: "Dashboard",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: "Happenings",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: "Marks",
        ),
      ],
    );
  }
}


class _StudentListScreenState extends State<StudentListScreen> {
  List students = [];

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8000/api/parent/${widget.parentId}/students/"),
    );

    if (response.statusCode == 200) {
      setState(() {
        students = json.decode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Children")),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(students[index]['name']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardScreen(
                    studentName: students[index]['name'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
