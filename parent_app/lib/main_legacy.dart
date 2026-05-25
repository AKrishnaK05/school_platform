import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
// Import snitch screens
import 'screens/snitch/snitch_dashboard.dart';
import 'screens/snitch/snitch_assignments.dart';
import 'screens/snitch/snitch_marks.dart';
import 'screens/snitch/snitch_login.dart';

// Snitch feature flag: enable to surface prototype screens from Stitch
const bool enableSnitch = true;

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

class DemoData {
  static List<Map<String, dynamic>> students() {
    return [
      {
        "id": 801,
        "name": "Anika K P",
        "class_id": 8,
        "image": "",
      },
      {
        "id": 802,
        "name": "Vedhika Sai",
        "class_id": 8,
        "image": "",
      },
    ];
  }

  static List<Map<String, dynamic>> reportCards() {
    return [
      {
        "id": -1,
        "exam": "Mid Term",
        "generated_on": "2026-03-28",
        "pdf_file": "",
        "is_demo": true,
      },
      {
        "id": -2,
        "exam": "Periodic Assessment 2",
        "generated_on": "2026-01-15",
        "pdf_file": "",
        "is_demo": true,
      },
    ];
  }

  // ... (legacy main.dart content truncated in backup file)
}

// Note: full legacy `main.dart` content preserved here for reference.
