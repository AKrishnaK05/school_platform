Snitch UI — Per-screen Feature & API Checklist

Purpose: detailed checklist mapping UI elements, interactions, data sources, and gaps to implement pixel-perfect parity with the legacy system.

1) Dashboard (parent_dashboard.png)
- Visual elements:
  - Top bar: app logo avatar (54x54), app title, subtitle, student selector button, logout icon
  - Hero card: large gradient (primary→accent), title, subtitle, metric pills (Fees Due, Average, Attendance)
  - Action grid: 2x2 action cards (Attendance, Timetable, Grades, Messages)
  - Upcoming assignments: horizontal card carousel (280px card width) with subject icon, title, due, status chip
  - Notifications list: stacked cards with icon, title, subtitle
  - Bottom nav: 4 items (Dashboard, Attendance, Grades, Messages) — selected state primary color
- Interactions:
  - Student selector opens `SnitchStudentSelector` and updates active student
  - Action cards navigate to respective pages via named routes
  - 'See all' opens Assignments list
  - Notifications open details
- API mappings:
  - `SnitchApi.fetchDashboardSummary()` aggregates: `fetchFeeReminders`, `fetchAnnouncements`, `fetchAllMarks`, `fetchStudentAttendance`, `fetchAssignments`.
- Acceptance criteria (exact): spacing, gradients, pill shapes, chip styles, font sizes and weights must match screenshot; assignment card width/height and horizontal scroll behavior identical.
- Gaps: verify exact font family/weights (Manrope/Inter used), ensure shadows/borders match stitch screenshot.

2) Login (stitch login screenshot)
- Visual elements:
  - Gradient header area with logo tile (54x54), app title, subtitle
  - Sign in large heading, supporting description
  - Form fields: Email/Username, Password with prefix icons and outlined/filled fields
  - Buttons: primary Sign In (48 height), outlined Google sign-in, 'View Prototype' link
- Interactions:
  - Submit posts to `/api/login/` and stores `snitch_parent_id` & `snitch_user_id` to prefs
  - Google sign-in placeholder; may require OAuth flow
  - View Prototype loads local prototype HTML
- API mappings:
  - POST `/api/login/` (payload username/password); fallback demo logic present
- Acceptance criteria: header gradient colors, rounded card radius, field spacing, primary button size and spinner state identical
- Gaps: full Google OAuth integration and error handling messages need implementation

3) Assignments
- Visual: AppBar title, list of horizontally scrollable cards in dashboard and full assignments list with chips and due metadata
- Interactions: Pull to refresh, tap card opens modal with details
- API: GET `/api/student/{id}/assignments/` (SnitchApi.fetchAssignments)
- Gaps: none critical; ensure horizontal card sizes match prototype

4) Marks
- Visual: exam choice chips, list of subject rows with subject name + marks displayed right
- Interactions: chip tap filters marks, pull-to-refresh
- API: GET `/api/student/{id}/marks/` (SnitchApi.fetchMarks)
- Gaps: visual alignment of grade badges and chip colors

5) Fee Payments
- Visual: outstanding balance card, list of invoices with pay button
- Interactions: tap Pay opens dialog entry → POST to pay endpoint → show success/failure snackbar
- API: GET `/api/student/{id}/fees/`, POST `/api/student/{id}/fees/{invoiceId}/pay/`
- Gaps: Payment gateway integration (UI just records on backend via API). Add receipt and payment method selection.

6) Student Selector
- Visual: list tiles with avatar, name, class, chevron
- Interactions: tap sets primary student in prefs and returns to previous screen
- API: GET `/api/parent/{id}/students/`

7) Attendance Tracking
- Visual: stat tiles (Total, Present, Absent, Late), calendar grid (7 columns × 5 rows), recent absence cards
- Interactions: download full report, refresh
- API: GET `/api/student/{id}/attendance/`
- Gaps: export/download implementation

8) Timetable
- Visual: day pills (horizontal scroller), schedule cards with time/subject/teacher/room
- Interactions: day selection, refresh
- API: GET `/api/timetable/{classId}/`

9) Communication Center
- Visual: segment control (Announcements / Direct Messages), announcement cards, thread cards
- Interactions: open thread -> fetch messages -> show in bottom sheet (draggable), compose not implemented
- API: GET `/api/announcements/`, GET `/api/chats/{parentId}/` and `/api/chats/thread/{id}/messages/`
- Gaps: compose, send, and attachments plus real-time updates

10) Grades & Performance
- Visual: chips for exams, grade tiles with circular grade badge, performance cards, report PDF CTA
- Interactions: choose exam chips, download PDF (stub)
- API: GET `/api/student/{id}/marks/`, GET for PDF endpoint (not yet implemented on front)

11) School Calendar
- Visual: small calendar grid in a card + list of upcoming events
- API: `fetchFeeReminders()` and `fetchAnnouncements()` used to build events
- Gaps: calendar export / event details

12) Support / Settings / Student Info
- Visual: list items, profile card with avatar and meta, info tiles
- Interactions: navigate to support options (placeholders)
- API: `fetchStudentProfile`, local prefs
- Gaps: edit profile flows, privacy settings storage

13) Preview overlay (new)
- Visual: full-screen screenshot background + draggable overlay with opacity slider and nudge buttons
- Interactions: drag to align, adjust opacity, center/nudge
- Purpose: developer helper to align live UI to screenshot pixel-by-pixel

Assets
- `assets/snitch/`: contains screenshots. Ensure higher-res variants for different device sizes or add `stitch_full.png` for tablet/desktop.

Priority checklist (initial implementation order)
1. Login (auth flow & exact visuals)
2. Dashboard (px-perfect hero card, pills, actions, notifications)
3. Assignments & Marks
4. Fees (add layout + pay dialog + receipts)
5. Attendance & Timetable
6. Communication (read-only threads → then compose + send)
7. Student Info, Settings, Support

Next actions I will take when you confirm:
- Start implementing Login pixel-perfect visuals + connect real `/api/login/` flow and Google OAuth skeleton.
- Or create issue-by-issue tasks for each UI element and begin implementing Dashboard changes.


