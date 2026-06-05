import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

String get apiBaseUrl {
  if (kIsWeb) return "http://127.0.0.1:8000";
  // Android emulator localhost
  return "http://10.0.2.2:8000";
}

class SnitchApi {
  static const _tokenKey = 'snitch_token';
  static const _parentKey = 'snitch_parent_id';
  static const _userKey = 'snitch_user_id';
  static const _studentKey = 'snitch_student_id';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<int?> getParentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_parentKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userKey);
  }

  static Future<List<Map<String, dynamic>>> fetchParentStudents() async {
    try {
      final parentId = await getParentId();
      if (parentId == null) return [];
      final url = Uri.parse('$apiBaseUrl/api/parent/$parentId/students/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) return List<Map<String, dynamic>>.from(body);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> getPrimaryStudent() async {
    final studentId = await getPrimaryStudentId();
    if (studentId == null) return null;

    final students = await fetchParentStudents();
    for (final student in students) {
      if (student['id'] == studentId) return student;
    }
    return null;
  }

  static Future<void> setPrimaryStudent(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_studentKey, id);
  }

  static Future<List<Map<String, dynamic>>> fetchStudentInvoices(int studentId) async {
    try {
      final url = Uri.parse('$apiBaseUrl/api/student/$studentId/fees/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) return List<Map<String, dynamic>>.from(body);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> fetchStudentProfile(int studentId) async {
    try {
      final url = Uri.parse('$apiBaseUrl/api/student/$studentId/profile/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is Map<String, dynamic>) return body;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchStudentAttendance(int studentId) async {
    try {
      final url = Uri.parse('$apiBaseUrl/api/student/$studentId/attendance/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) return List<Map<String, dynamic>>.from(body);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchTimetable(int classId) async {
    try {
      final url = Uri.parse('$apiBaseUrl/api/timetable/$classId/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) return List<Map<String, dynamic>>.from(body);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    try {
      final url = Uri.parse('$apiBaseUrl/api/announcements/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) return List<Map<String, dynamic>>.from(body);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchParentChatThreads({int? studentId}) async {
    try {
      final parentId = await getParentId();
      if (parentId == null) return [];
      final query = studentId == null ? '' : '?student_id=$studentId';
      final url = Uri.parse('$apiBaseUrl/api/chats/$parentId/$query');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) return List<Map<String, dynamic>>.from(body);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchChatRoomMessages(int roomId) async {
    try {
      final userId = await getUserId();
      if (userId == null) return [];
      final url = Uri.parse('$apiBaseUrl/api/chats/v2/rooms/$roomId/messages/?user_id=$userId');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) return List<Map<String, dynamic>>.from(body);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchThreadMessages(int threadId) async {
    try {
      final url = Uri.parse('$apiBaseUrl/api/chats/thread/$threadId/messages/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) return List<Map<String, dynamic>>.from(body);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> fetchStudentFeeSummary(int studentId) async {
    try {
      final url = Uri.parse('$apiBaseUrl/api/student/$studentId/fees/summary/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is Map<String, dynamic>) return body;
      }
    } catch (_) {}
    return {'student_id': studentId, 'pending_total': '0', 'overdue_count': 0, 'due_soon_count': 0};
  }

  static Future<List<Map<String, dynamic>>> fetchFeeReminders() async {
    try {
      final parentId = await getParentId();
      if (parentId == null) return [];
      final url = Uri.parse('$apiBaseUrl/api/parent/$parentId/fees/reminders/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) return List<Map<String, dynamic>>.from(body);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> payInvoice(int studentId, int invoiceId, {String? amount, String? method}) async {
    try {
      final url = Uri.parse('$apiBaseUrl/api/student/$studentId/fees/$invoiceId/pay/');
      final body = <String, dynamic>{};
      if (amount != null) body['amount'] = amount;
      if (method != null) body['payment_method'] = method;
      final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map<String, dynamic>) return data;
      }
    } catch (_) {}
    return null;
  }

  static Future<int?> getPrimaryStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getInt(_studentKey);
    if (cached != null) return cached;

    final parentId = await getParentId();
    if (parentId == null) return null;

    try {
      final url = Uri.parse('$apiBaseUrl/api/parent/$parentId/students/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List && body.isNotEmpty) {
          final first = body.first;
          final sid = first['id'] as int?;
          if (sid != null) {
            await prefs.setInt(_studentKey, sid);
            return sid;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_parentKey);
    await prefs.remove(_studentKey);
    await prefs.remove(_userKey);
    await prefs.remove('snitch_logged_in');
  }

  // Public accessor for token (used by app startup logic)
  static Future<String?> getToken() => _getToken();

  static Future<List<Map<String, dynamic>>> fetchAssignments() async {
    try {
      final sid = await getPrimaryStudentId();
      if (sid == null) throw Exception('no student');
      final url = Uri.parse('$apiBaseUrl/api/student/$sid/assignments/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) return List<Map<String, dynamic>>.from(body);
      }
    } catch (_) {}

    // fallback demo data
    return [
      {'title': 'Math - Worksheet 5', 'subject': 'Math', 'due': '2026-06-01', 'status': 'Due'},
      {'title': 'Science - Project', 'subject': 'Science', 'due': '2026-06-05', 'status': 'Open'},
    ];
  }

  static Future<List<Map<String, dynamic>>> fetchMarks(String exam) async {
    try {
      final sid = await getPrimaryStudentId();
      if (sid == null) throw Exception('no student');
      final url = Uri.parse('$apiBaseUrl/api/student/$sid/marks/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) {
          final all = List<Map<String, dynamic>>.from(body);
          if (exam.trim().isEmpty) return all;
          return all.where((row) => (row['exam']?.toString() ?? '') == exam).toList();
        }
      }
    } catch (_) {}

    // fallback demo marks per exam
    final demo = {
      'Periodic Assessment 1': [
        {'subject': 'Math', 'marks': 78},
        {'subject': 'Science', 'marks': 82},
      ],
      'Periodic Assessment 2': [
        {'subject': 'Math', 'marks': 74},
        {'subject': 'Science', 'marks': 79},
      ],
      'Mid Term': [
        {'subject': 'Math', 'marks': 80},
        {'subject': 'Science', 'marks': 85},
      ],
      'End Term': [
        {'subject': 'Math', 'marks': 86},
        {'subject': 'Science', 'marks': 88},
      ],
    };

    return List<Map<String, dynamic>>.from(demo[exam] ?? demo.values.first);
  }

  static Future<List<Map<String, dynamic>>> fetchAllMarks() async {
    try {
      final sid = await getPrimaryStudentId();
      if (sid == null) return [];
      final url = Uri.parse('$apiBaseUrl/api/student/$sid/marks/');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) return List<Map<String, dynamic>>.from(body);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<String>> fetchExamNames() async {
    final rows = await fetchAllMarks();
    final exams = <String>{};
    for (final row in rows) {
      final exam = row['exam']?.toString();
      if (exam != null && exam.isNotEmpty) exams.add(exam);
    }
    if (exams.isNotEmpty) return exams.toList();
    return ['Periodic Assessment 1', 'Periodic Assessment 2', 'Mid Term', 'End Term'];
  }

  static Future<Map<String, dynamic>> fetchDashboardSummary() async {
    try {
      final parentId = await getParentId();
      if (parentId == null) throw Exception('no parent');
      final sid = await getPrimaryStudentId();
      final notifications = await fetchFeeReminders();
      final announcements = await fetchAnnouncements();
      final allMarks = await fetchAllMarks();
      final attendance = sid != null ? await fetchStudentAttendance(sid) : <Map<String, dynamic>>[];

      final markValues = allMarks
          .map((row) => num.tryParse(row['score']?.toString() ?? '0') ?? 0)
          .where((value) => value > 0)
          .toList();
      final avgMarks = markValues.isEmpty ? 0 : (markValues.reduce((a, b) => a + b) / markValues.length).round();

      final presentCount = attendance.where((row) => (row['status']?.toString() ?? '').toUpperCase() == 'PRESENT').length;
      final attendanceTotal = attendance.isNotEmpty ? attendance.length : 0;

      final feeSummary = sid != null ? await fetchStudentFeeSummary(sid) : {'pending_total': '0', 'overdue_count': 0, 'due_soon_count': 0};

      return {
        'fees_due': feeSummary['pending_total'] ?? '0',
        'average_marks': avgMarks,
        'attendance_total': attendanceTotal,
        'attendance_present': presentCount,
        'notifications': notifications.isNotEmpty
            ? notifications
            : announcements.take(3).map((item) {
                return {
                  'title': item['title'] ?? '',
                  'subtitle': item['body'] ?? '',
                };
              }).toList(),
        'upcoming_assignments': sid != null ? await fetchAssignments() : [],
      };
    } catch (_) {}

    return {
      'fees_due': 4200,
      'average_marks': 78,
      'attendance_total': 0,
      'attendance_present': 0,
      'notifications': [
        {'title': 'Fee overdue reminder', 'subtitle': 'Monthly tuition due 3 days ago'},
        {'title': 'New assignment posted', 'subtitle': 'Science - Project uploaded'},
      ],
      'upcoming_assignments': [
        {'title': 'Math - Worksheet 5', 'due': '2026-06-01', 'status': 'Due'},
      ],
    };
  }

}
