# Parent App (Snitch integration)

This Flutter app is the mobile parent app for the school platform. It contains a "Snitch" prototype integrated as native screens.

Features implemented
- Native Snitch login with token persistence (`SharedPreferences`).
- Dashboard: fees summary, marks summary, assignments carousel, notifications.
- Assignments: list with details and pull-to-refresh.
- Marks: grouped by exam taxonomy (Periodic Assessment 1, Periodic Assessment 2, Mid Term, End Term).
- Lightweight API client: `lib/services/snitch_api.dart` with safe demo fallbacks.
- Logout/clear token flow.

Run the app
```bash
cd parent_app
flutter pub get
flutter run
```

Run analyzer
```bash
cd parent_app
flutter analyze
```

Run widget tests
```bash
cd parent_app
flutter test
```

Notes
- The API client provides demo fallback data if backend endpoints are unreachable.
- Update `lib/services/snitch_api.dart` to match your backend endpoints and auth format as needed.
