Integration notes: Stitch prototype -> Flutter merge

What I copied
- `lib/snitch/parent_dashboard.html` (prototype reference)
- `lib/snitch/DESIGN_academic_clarity.md` (visual system excerpt)
- `assets/snitch/.gitkeep` placeholder (create folder to hold prototype assets/screenshots)

Recommended next steps to complete the merge

1. Move images/screenshots
- Copy the images from `stitch_academic_parent_mobile_app/stitch_academic_parent_mobile_app/*/screen.png` into `parent_app/assets/snitch/`.

2. Create Flutter screens from prototype
- Implement new files under `parent_app/lib/screens/`:
  - `snitch_dashboard.dart` (use design tokens from `DESIGN_academic_clarity.md`)
  - `snitch_assignments.dart` (match Assignments API)
  - `snitch_marks.dart` (expose exam dropdown and filtered list)
- Keep these files in a `snitch/` subfolder if you want to isolate the prototype.

3. Wire navigation
- Import and expose the new screens in `parent_app/lib/main.dart` via routes or by replacing sample screens in `buildCard` temporarily.

4. API wiring & demo fallback
- Use existing `apiBaseUrl` logic in `main.dart` and implement API calls consistent with other screens:
  - `/api/student/{studentId}/assignments/`
  - `/api/student/{studentId}/marks/`
  - `/api/student/{studentId}/fees/` and `/fees/summary/`
- Provide demo fallback similar to `DemoData` in `main.dart`.

5. Add assets to `pubspec.yaml`
- Under `flutter:` add:
  assets:
    - assets/snitch/

6. Run checks
```bash
cd parent_app
flutter pub get
flutter analyze
flutter run -d chrome
```

7. Commit
- Create a branch `feat/frontend-snitch` and commit the added files and any new Flutter screens you implement.

If you want, I can now:
- Copy the prototype screenshots into `parent_app/assets/snitch/` for you (I can move the existing `screen.png` files into that folder).
- Generate starter Flutter widget files (`snitch_dashboard.dart`, `snitch_marks.dart`, `snitch_assignments.dart`) that replicate the prototype structure and wire them into `main.dart` behind a feature flag.

Which of those would you like me to do next?"