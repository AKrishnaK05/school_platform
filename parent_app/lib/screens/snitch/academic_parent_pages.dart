import 'package:flutter/material.dart';

import '../../services/snitch_api.dart';
import '../../theme/snitch_theme.dart';
import '../../widgets/snitch_card.dart';

class AcademicParentScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final int activeIndex;

  const AcademicParentScaffold({super.key, required this.title, required this.body, this.actions = const [], this.activeIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnitchTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  const CircleAvatar(radius: 15, backgroundColor: SnitchTheme.primary, child: Icon(Icons.school_rounded, color: Colors.white, size: 16)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EduParent', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        SizedBox(height: 1),
                        Text('Academic parent view', style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  ...actions,
                  if (actions.isNotEmpty) const SizedBox(width: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: const Icon(Icons.more_horiz_rounded, size: 18, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
            _PrototypeBottomNav(activeIndex: activeIndex),
          ],
        ),
      ),
    );
  }
}

class AttendanceTrackingPage extends StatefulWidget {
  const AttendanceTrackingPage({super.key});

  @override
  State<AttendanceTrackingPage> createState() => _AttendanceTrackingPageState();
}

class _AttendanceTrackingPageState extends State<AttendanceTrackingPage> {
  Future<_AttendanceData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AttendanceData> _load() async {
    final student = await SnitchApi.getPrimaryStudent();
    final studentId = student?['id'] as int?;
    final records = studentId == null ? <Map<String, dynamic>>[] : await SnitchApi.fetchStudentAttendance(studentId);
    return _AttendanceData.fromRecords(records);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AcademicParentScaffold(
      title: 'Attendance Tracking',
      activeIndex: 1,
      body: FutureBuilder<_AttendanceData>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data ?? const _AttendanceData.empty();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(child: _StatTile(label: 'TOTAL DAYS', value: '${data.totalDays}', tone: SnitchTheme.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatTile(label: 'PRESENT', value: '${data.presentDays}', tone: SnitchTheme.secondary)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatTile(label: 'ABSENT', value: '${data.absentDays}', tone: const Color(0xFFDC2626))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatTile(label: 'LATE', value: '${data.lateDays}', tone: SnitchTheme.tertiary)),
                  ],
                ),
                const SizedBox(height: 16),
                SnitchCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.monthLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                        children: List.generate(35, (index) {
                          final day = (index % 30) + 1;
                          final selected = data.highlightedDays.contains(day);
                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? SnitchTheme.primary.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text('$day', style: const TextStyle(fontSize: 12)),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Recent Absences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (data.recentAbsences.isEmpty)
                  const _EmptyState(label: 'No attendance records yet')
                else
                  ...data.recentAbsences.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RecentAttendanceTile(
                        date: record.dateDay,
                        month: record.monthLabel,
                        title: record.title,
                        subtitle: record.subtitle,
                        tone: record.tone,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () {}, child: const Text('Download Full Report')),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StudentTimetablePage extends StatefulWidget {
  const StudentTimetablePage({super.key});

  @override
  State<StudentTimetablePage> createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<StudentTimetablePage> {
  Future<_TimetableData>? _future;
  String? _selectedDay;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TimetableData> _load() async {
    final student = await SnitchApi.getPrimaryStudent();
    final classId = student?['class_id'] as int?;
    final studentName = student?['name']?.toString() ?? 'Student';
    final className = student?['class_name']?.toString() ?? '';
    final rows = classId == null ? <Map<String, dynamic>>[] : await SnitchApi.fetchTimetable(classId);
    final data = _TimetableData.fromRows(studentName: studentName, className: className, rows: rows);
    _selectedDay ??= data.days.firstOrNull;
    return data;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AcademicParentScaffold(
      title: 'Student Timetable',
      activeIndex: 0,
      body: FutureBuilder<_TimetableData>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data ?? const _TimetableData.empty();
          final day = _selectedDay ?? data.days.firstOrNull;
          final dayItems = day == null ? const <_ScheduleItem>[] : data.scheduleByDay[day] ?? const <_ScheduleItem>[];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Weekly Schedule', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('${data.studentName} ${data.className.isEmpty ? '' : '• ${data.className}'}', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.days.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final value = data.days[index];
                      final selected = value == day;
                      return _DayPill(
                        day: value.substring(0, 3).toUpperCase(),
                        selected: selected,
                        onTap: () => setState(() => _selectedDay = value),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (dayItems.isEmpty)
                  const _EmptyState(label: 'No timetable entries available')
                else
                  ...dayItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ScheduleCard(
                        time: item.timeLabel,
                        subject: item.subject,
                        teacher: item.teacher,
                        room: item.room,
                        tone: item.tone,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CommunicationCenterPage extends StatefulWidget {
  const CommunicationCenterPage({super.key});

  @override
  State<CommunicationCenterPage> createState() => _CommunicationCenterPageState();
}

class _CommunicationCenterPageState extends State<CommunicationCenterPage> {
  late Future<_CommunicationData> _future;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CommunicationData> _load() async {
    final student = await SnitchApi.getPrimaryStudent();
    final studentId = student?['id'] as int?;
    final announcements = await SnitchApi.fetchAnnouncements();
    final threads = await SnitchApi.fetchParentChatThreads(studentId: studentId);
    return _CommunicationData.fromBackend(announcements: announcements, threads: threads);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _showThreadMessages(Map<String, dynamic> thread) async {
    final threadId = thread['thread_id'] as int?;
    if (threadId == null) return;
    final messages = await SnitchApi.fetchThreadMessages(threadId);
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  Text(thread['student_name']?.toString() ?? 'Messages', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(thread['teacher_name']?.toString() ?? '', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  if (messages.isEmpty)
                    const _EmptyState(label: 'No messages yet')
                  else
                    ...messages.map(
                      (message) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SnitchCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message['sender_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(message['content']?.toString() ?? ''),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AcademicParentScaffold(
      title: 'Communication Center',
      activeIndex: 3,
      body: FutureBuilder<_CommunicationData>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data ?? const _CommunicationData.empty();
          final rows = _tabIndex == 0 ? data.announcements : data.threads;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(child: _SegmentButton(label: 'Announcements', selected: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0))),
                    const SizedBox(width: 8),
                    Expanded(child: _SegmentButton(label: 'Direct Messages', selected: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1))),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_tabIndex == 0 ? 'School Updates' : 'Direct Messages', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const _EmptyState(label: 'No items to display')
                else if (_tabIndex == 0)
                  ...rows.map(
                    (announcement) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AnnouncementCard(
                        title: announcement['title']?.toString() ?? '',
                        subtitle: announcement['body']?.toString() ?? '',
                        cta: 'View Details',
                        meta: announcement['created_at']?.toString(),
                      ),
                    ),
                  )
                else
                  ...rows.map(
                    (thread) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ThreadCard(
                        title: thread['teacher_name']?.toString() ?? 'Conversation',
                        subtitle: thread['last_message']?.toString() ?? '',
                        meta: thread['student_name']?.toString() ?? '',
                        onTap: () => _showThreadMessages(thread),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class GradesPerformancePage extends StatefulWidget {
  const GradesPerformancePage({super.key});

  @override
  State<GradesPerformancePage> createState() => _GradesPerformancePageState();
}

class _GradesPerformancePageState extends State<GradesPerformancePage> {
  late Future<_GradesData> _future;
  String? _selectedExam;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_GradesData> _load() async {
    final marks = await SnitchApi.fetchAllMarks();
    final data = _GradesData.fromMarks(marks);
    _selectedExam ??= data.exams.firstOrNull;
    return data;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AcademicParentScaffold(
      title: 'Grades & Performance',
      activeIndex: 2,
      body: FutureBuilder<_GradesData>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data ?? const _GradesData.empty();
          final selectedExam = _selectedExam ?? data.exams.firstOrNull;
          final rows = selectedExam == null ? const <_GradeRow>[] : data.rowsByExam[selectedExam] ?? const <_GradeRow>[];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Academic Performance', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.exams
                      .map(
                        (exam) => ChoiceChip(
                          label: Text(exam),
                          selected: exam == selectedExam,
                          selectedColor: SnitchTheme.primary,
                          labelStyle: TextStyle(color: exam == selectedExam ? Colors.white : Colors.black87, fontWeight: FontWeight.w700),
                          onSelected: (_) => setState(() => _selectedExam = exam),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                if (rows.isEmpty)
                  const _EmptyState(label: 'No marks available for the selected exam')
                else
                  ...rows.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _GradeTile(subject: row.subject, grade: row.grade, score: row.scoreLabel, tone: row.tone),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Recent Teacher Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _FeedbackCard(name: 'Strong performance', note: 'Selected exam results are loaded from the backend marks records.', tone: SnitchTheme.secondary),
                const SizedBox(height: 8),
                _FeedbackCard(name: 'Focus area', note: 'Use the same chip selection to inspect each exam grouping.', tone: SnitchTheme.primary),
                const SizedBox(height: 16),
                SnitchCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Term 1 Report Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('PDF report is now available for download.', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: SnitchTheme.primary),
                        child: const Text('Download PDF'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SchoolCalendarPage extends StatefulWidget {
  const SchoolCalendarPage({super.key});

  @override
  State<SchoolCalendarPage> createState() => _SchoolCalendarPageState();
}

class _SchoolCalendarPageState extends State<SchoolCalendarPage> {
  late Future<_CalendarData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CalendarData> _load() async {
    final reminders = await SnitchApi.fetchFeeReminders();
    final announcements = await SnitchApi.fetchAnnouncements();
    return _CalendarData.fromBackend(reminders: reminders, announcements: announcements);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AcademicParentScaffold(
      title: 'School Calendar',
      activeIndex: 0,
      body: FutureBuilder<_CalendarData>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data ?? const _CalendarData.empty();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SnitchCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.monthLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: List.generate(35, (index) => Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(10)), child: Center(child: Text('${(index % 30) + 1}')))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (data.events.isEmpty)
                  const _EmptyState(label: 'No calendar events available')
                else
                  ...data.events.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CalendarEventTile(date: event.dateDay, title: event.title, subtitle: event.subtitle, tone: event.tone),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SupportHelpPage extends StatelessWidget {
  const SupportHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AcademicParentScaffold(
      title: 'Support & Help',
      activeIndex: 0,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('How can we help?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _SupportTile(icon: Icons.chat_bubble_outline, title: 'Chat with support', subtitle: 'Get help from the school help desk'),
          const SizedBox(height: 8),
          const _SupportTile(icon: Icons.call_outlined, title: 'Call the office', subtitle: 'Speak with the administration team'),
          const SizedBox(height: 8),
          const _SupportTile(icon: Icons.mail_outline, title: 'Email support', subtitle: 'Send us a message from your inbox'),
          const SizedBox(height: 16),
          const Text('Frequently Asked Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const _FaqTile(question: 'How do I pay fees?', answer: 'Open Fee Payments and tap Pay now on the due invoice.'),
          const SizedBox(height: 8),
          const _FaqTile(question: 'Where can I see attendance?', answer: 'Attendance Tracking shows monthly records and recent absences.'),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AcademicParentScaffold(
      title: 'Settings',
      activeIndex: 0,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SnitchCard(
            child: Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: SnitchTheme.primary, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                FutureBuilder<_SelectedStudentData>(
                  future: _selectedStudentInfo(),
                  builder: (context, snap) {
                    final data = snap.data ?? const _SelectedStudentData.empty();
                    return Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data.studentName.isEmpty ? 'EduParent User' : data.studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(data.accountLabel.isEmpty ? 'Parent ID: ${data.parentId ?? '—'}' : data.accountLabel, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SettingsTile(title: 'Notifications', subtitle: 'Payment reminders, announcements, and message alerts'),
          const SizedBox(height: 8),
          const _SettingsTile(title: 'Privacy', subtitle: 'Control profile and student visibility settings'),
          const SizedBox(height: 8),
          const _SettingsTile(title: 'Language', subtitle: 'English'),
          const SizedBox(height: 8),
          const _SettingsTile(title: 'Theme', subtitle: 'Academic Clarity'),
        ],
      ),
    );
  }
}

class StudentInfoPage extends StatelessWidget {
  const StudentInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AcademicParentScaffold(
      title: 'Student Info',
      activeIndex: 0,
      body: FutureBuilder<_SelectedStudentData>(
        future: _selectedStudentInfo(),
        builder: (context, snap) {
          final data = snap.data ?? const _SelectedStudentData.empty();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SnitchCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [SnitchTheme.primary, SnitchTheme.accent]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: data.photoUrl.isNotEmpty ? NetworkImage(data.photoUrl) : null,
                            backgroundColor: Colors.white.withValues(alpha: 0.18),
                            child: data.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data.studentName.isEmpty ? 'Student' : data.studentName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text(data.className.isEmpty ? 'Selected student details' : data.className, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                if (data.admissionNo.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('Admission No. ${data.admissionNo}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Personal Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _InfoTile(label: 'Student ID', value: data.studentId?.toString() ?? '—')),
                  const SizedBox(width: 10),
                  Expanded(child: _InfoTile(label: 'Date of Birth', value: data.dateOfBirth.isEmpty ? '—' : data.dateOfBirth)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _InfoTile(label: 'Blood Group', value: data.bloodGroup.isEmpty ? '—' : data.bloodGroup)),
                  const SizedBox(width: 10),
                  Expanded(child: _InfoTile(label: 'Gender', value: data.gender.isEmpty ? '—' : data.gender)),
                ],
              ),
              const SizedBox(height: 8),
              _InfoTile(label: 'Address', value: data.address.isEmpty ? '—' : data.address),
              const SizedBox(height: 16),
              const Text('Contacts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _InfoTile(label: 'Class Teacher', value: data.teacherName.isEmpty ? '—' : data.teacherName),
              const SizedBox(height: 8),
              _InfoTile(label: 'Emergency Contact', value: data.emergencyContact.isEmpty ? '—' : data.emergencyContact),
            ],
          );
        },
      ),
    );
  }
}

class _AttendanceData {
  final List<_AttendanceRecord> recentAbsences;
  final List<int> highlightedDays;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final String monthLabel;

  const _AttendanceData({required this.recentAbsences, required this.highlightedDays, required this.totalDays, required this.presentDays, required this.absentDays, required this.lateDays, required this.monthLabel});

  const _AttendanceData.empty()
      : recentAbsences = const [],
        highlightedDays = const [],
        totalDays = 0,
        presentDays = 0,
        absentDays = 0,
        lateDays = 0,
        monthLabel = 'Attendance';

  factory _AttendanceData.fromRecords(List<Map<String, dynamic>> records) {
    final recentAbsences = <_AttendanceRecord>[];
    final highlightedDays = <int>[];
    var present = 0;
    var absent = 0;
    var late = 0;

    for (final row in records) {
      final status = row['status']?.toString().toUpperCase() ?? '';
      final date = DateTime.tryParse(row['date']?.toString() ?? '');
      if (date != null) highlightedDays.add(date.day);

      if (status == 'PRESENT') {
        present++;
      } else if (status == 'ABSENT') {
        absent++;
        recentAbsences.add(_AttendanceRecord.fromRow(row));
      } else if (status == 'LATE') {
        late++;
        recentAbsences.add(_AttendanceRecord.fromRow(row));
      }
    }

    recentAbsences.sort((a, b) => b.date.compareTo(a.date));

    return _AttendanceData(
      recentAbsences: recentAbsences.take(4).toList(),
      highlightedDays: highlightedDays,
      totalDays: records.length,
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      monthLabel: 'Attendance Overview',
    );
  }
}

class _AttendanceRecord {
  final DateTime date;
  final String dateDay;
  final String monthLabel;
  final String title;
  final String subtitle;
  final Color tone;

  const _AttendanceRecord({required this.date, required this.dateDay, required this.monthLabel, required this.title, required this.subtitle, required this.tone});

  factory _AttendanceRecord.fromRow(Map<String, dynamic> row) {
    final date = DateTime.tryParse(row['date']?.toString() ?? '') ?? DateTime.now();
    final status = row['status']?.toString().toUpperCase() ?? 'ABSENT';
    final reason = row['reason']?.toString() ?? 'Marked by school office';

    final tone = status == 'LATE'
        ? SnitchTheme.tertiary
        : status == 'ABSENT'
            ? const Color(0xFFDC2626)
            : SnitchTheme.primary;

    final title = status == 'LATE'
        ? 'Late arrival'
        : status == 'ABSENT'
            ? 'Absent'
            : 'Present';

    return _AttendanceRecord(
      date: date,
      dateDay: date.day.toString().padLeft(2, '0'),
      monthLabel: _shortMonth(date.month),
      title: title,
      subtitle: reason,
      tone: tone,
    );
  }
}

class _TimetableData {
  final String studentName;
  final String className;
  final List<String> days;
  final Map<String, List<_ScheduleItem>> scheduleByDay;

  const _TimetableData({required this.studentName, required this.className, required this.days, required this.scheduleByDay});

  const _TimetableData.empty()
      : studentName = '',
        className = '',
        days = const [],
        scheduleByDay = const {};

  factory _TimetableData.fromRows({required String studentName, required String className, required List<Map<String, dynamic>> rows}) {
    final days = <String>[];
    final scheduleByDay = <String, List<_ScheduleItem>>{};

    for (final row in rows) {
      final day = row['day_of_week']?.toString().trim().isNotEmpty == true ? row['day_of_week'].toString() : 'Monday';
      final item = _ScheduleItem.fromRow(row);
      days.add(day);
      scheduleByDay.putIfAbsent(day, () => []).add(item);
    }

    for (final list in scheduleByDay.values) {
      list.sort((a, b) => a.period.compareTo(b.period));
    }

    final orderedDays = days.toSet().toList();
    return _TimetableData(studentName: studentName, className: className, days: orderedDays, scheduleByDay: scheduleByDay);
  }
}

class _ScheduleItem {
  final int period;
  final String timeLabel;
  final String subject;
  final String teacher;
  final String room;
  final Color tone;

  const _ScheduleItem({required this.period, required this.timeLabel, required this.subject, required this.teacher, required this.room, required this.tone});

  factory _ScheduleItem.fromRow(Map<String, dynamic> row) {
    final period = int.tryParse(row['period_number']?.toString() ?? row['period']?.toString() ?? '0') ?? 0;
    final subject = row['subject']?.toString() ?? '';
    final teacher = row['teacher']?.toString() ?? '';
    final room = row['room']?.toString() ?? row['class_section']?.toString() ?? '';
    final tone = [SnitchTheme.primary, SnitchTheme.secondary, SnitchTheme.tertiary][period % 3];

    return _ScheduleItem(
      period: period,
      timeLabel: period > 0 ? 'P$period' : '--',
      subject: subject,
      teacher: teacher,
      room: room,
      tone: tone,
    );
  }
}

class _CommunicationData {
  final List<Map<String, dynamic>> announcements;
  final List<Map<String, dynamic>> threads;

  const _CommunicationData({required this.announcements, required this.threads});

  const _CommunicationData.empty() : announcements = const [], threads = const [];

  factory _CommunicationData.fromBackend({required List<Map<String, dynamic>> announcements, required List<Map<String, dynamic>> threads}) {
    return _CommunicationData(announcements: announcements, threads: threads);
  }
}

class _GradesData {
  final List<String> exams;
  final Map<String, List<_GradeRow>> rowsByExam;

  const _GradesData({required this.exams, required this.rowsByExam});

  const _GradesData.empty() : exams = const [], rowsByExam = const {};

  factory _GradesData.fromMarks(List<Map<String, dynamic>> marks) {
    final rowsByExam = <String, List<_GradeRow>>{};
    for (final row in marks) {
      final exam = row['exam']?.toString().trim().isNotEmpty == true ? row['exam'].toString() : 'Exam';
      final subject = row['subject']?.toString() ?? '';
      final score = double.tryParse(row['score']?.toString() ?? '0') ?? 0;
      rowsByExam.putIfAbsent(exam, () => []).add(_GradeRow(subject: subject, score: score));
    }

    for (final rows in rowsByExam.values) {
      rows.sort((a, b) => b.score.compareTo(a.score));
    }

    return _GradesData(exams: rowsByExam.keys.toList(), rowsByExam: rowsByExam);
  }
}

class _GradeRow {
  final String subject;
  final double score;
  final String grade;
  final String scoreLabel;
  final Color tone;

  _GradeRow({required this.subject, required this.score})
      : grade = _gradeFor(score),
        scoreLabel = '${score.toStringAsFixed(1)}%',
        tone = _toneFor(score);

  static String _gradeFor(double score) {
    if (score >= 90) return 'A';
    if (score >= 85) return 'A-';
    if (score >= 80) return 'B+';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    return 'D';
  }

  static Color _toneFor(double score) {
    if (score >= 90) return SnitchTheme.primary;
    if (score >= 80) return SnitchTheme.secondary;
    if (score >= 70) return SnitchTheme.tertiary;
    return const Color(0xFFDC2626);
  }
}

class _CalendarData {
  final String monthLabel;
  final List<_CalendarEvent> events;

  const _CalendarData({required this.monthLabel, required this.events});

  const _CalendarData.empty() : monthLabel = 'School Calendar', events = const [];

  factory _CalendarData.fromBackend({required List<Map<String, dynamic>> reminders, required List<Map<String, dynamic>> announcements}) {
    final events = <_CalendarEvent>[];

    for (final reminder in reminders.take(4)) {
      final dueDate = DateTime.tryParse(reminder['due_date']?.toString() ?? '') ?? DateTime.now();
      events.add(_CalendarEvent(
        dateDay: dueDate.day.toString().padLeft(2, '0'),
        title: reminder['title']?.toString() ?? 'Fee reminder',
        subtitle: reminder['body']?.toString() ?? '',
        tone: reminder['reminder_type']?.toString() == 'OVERDUE' ? const Color(0xFFDC2626) : SnitchTheme.tertiary,
      ));
    }

    for (final announcement in announcements.take(3)) {
      events.add(_CalendarEvent(
        dateDay: '!',
        title: announcement['title']?.toString() ?? 'School update',
        subtitle: announcement['body']?.toString() ?? '',
        tone: SnitchTheme.primary,
      ));
    }

    return _CalendarData(monthLabel: 'Upcoming Events', events: events);
  }
}

class _CalendarEvent {
  final String dateDay;
  final String title;
  final String subtitle;
  final Color tone;

  const _CalendarEvent({required this.dateDay, required this.title, required this.subtitle, required this.tone});
}

class _SelectedStudentData {
  final int? studentId;
  final int? parentId;
  final String studentName;
  final String className;
  final String teacherName;
  final String emergencyContact;
  final String photoUrl;
  final String admissionNo;
  final String dateOfBirth;
  final String bloodGroup;
  final String gender;
  final String address;
  final String accountLabel;

  const _SelectedStudentData({required this.studentId, required this.parentId, required this.studentName, required this.className, required this.teacherName, required this.emergencyContact, required this.photoUrl, required this.admissionNo, required this.dateOfBirth, required this.bloodGroup, required this.gender, required this.address, required this.accountLabel});

  const _SelectedStudentData.empty()
      : studentId = null,
        parentId = null,
        studentName = '',
        className = '',
        teacherName = '',
        emergencyContact = '',
        photoUrl = '',
        admissionNo = '',
        dateOfBirth = '',
        bloodGroup = '',
        gender = '',
    address = '',
        accountLabel = '';
}

Future<_SelectedStudentData> _selectedStudentInfo() async {
  final parentId = await SnitchApi.getParentId();
  final studentId = await SnitchApi.getPrimaryStudentId();
  final student = studentId == null ? await SnitchApi.getPrimaryStudent() : await SnitchApi.fetchStudentProfile(studentId);
  return _SelectedStudentData(
    studentId: student?['id'] as int?,
    parentId: parentId,
    studentName: student?['name']?.toString() ?? student?['full_name']?.toString() ?? '',
    className: student?['class_name']?.toString() ?? '',
    teacherName: student?['teacher_name']?.toString() ?? '',
    emergencyContact: student?['emergency_contact']?.toString() ?? '',
    photoUrl: student?['image']?.toString() ?? '',
    admissionNo: student?['admission_no']?.toString() ?? '',
    dateOfBirth: student?['date_of_birth']?.toString() ?? '',
    bloodGroup: student?['blood_group']?.toString() ?? '',
    gender: student?['gender']?.toString() ?? '',
    address: student?['address']?.toString() ?? '',
    accountLabel: [student?['parent_username']?.toString(), student?['parent_phone']?.toString()].map((value) => value ?? '').where((value) => value.isNotEmpty).join(' • '),
  );
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;
  const _StatTile({required this.label, required this.value, required this.tone});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: tone)),
        ],
      ),
    );
  }
}

class _RecentAttendanceTile extends StatelessWidget {
  final String date;
  final String month;
  final String title;
  final String subtitle;
  final Color tone;

  const _RecentAttendanceTile({required this.date, required this.month, required this.title, required this.subtitle, required this.tone});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 56,
            decoration: BoxDecoration(color: tone.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(date, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tone)), Text(month, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tone))]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.black54))])),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  final String day;
  final bool selected;
  final VoidCallback onTap;

  const _DayPill({required this.day, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? SnitchTheme.primary : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Text(day, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.black87)),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String time;
  final String subject;
  final String teacher;
  final String room;
  final Color tone;

  const _ScheduleCard({required this.time, required this.subject, required this.teacher, required this.room, required this.tone});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(
      child: Row(
        children: [
          SizedBox(width: 52, child: Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tone))),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subject, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('$teacher • $room', style: const TextStyle(color: Colors.black54))])),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? SnitchTheme.primary : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.black87)),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cta;
  final String? meta;

  const _AnnouncementCard({required this.title, required this.subtitle, required this.cta, this.meta});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meta != null) Text(meta!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
          if (meta != null) const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, child: Text(cta))),
        ],
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback onTap;

  const _ThreadCard({required this.title, required this.subtitle, required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: SnitchTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.message_outlined, color: SnitchTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(meta, style: const TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _GradeTile extends StatelessWidget {
  final String subject;
  final String grade;
  final String score;
  final Color tone;

  const _GradeTile({required this.subject, required this.grade, required this.score, required this.tone});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subject, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(score, style: TextStyle(color: tone, fontWeight: FontWeight.w600))])),
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tone.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Text(grade, style: TextStyle(color: tone, fontSize: 20, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final String name;
  final String note;
  final Color tone;

  const _FeedbackCard({required this.name, required this.note, required this.tone});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: tone)), const SizedBox(height: 4), Text(note, style: const TextStyle(color: Colors.black54))]));
  }
}

class _CalendarEventTile extends StatelessWidget {
  final String date;
  final String title;
  final String subtitle;
  final Color tone;

  const _CalendarEventTile({required this.date, required this.title, required this.subtitle, required this.tone});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(
      child: Row(
        children: [
          Container(width: 48, height: 56, alignment: Alignment.center, decoration: BoxDecoration(color: tone.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Text(date, style: TextStyle(color: tone, fontWeight: FontWeight.w800, fontSize: 18))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.black54))])),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SettingsTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(
      child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.black54))])), const Icon(Icons.chevron_right)]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]));
  }
}

class _EmptyState extends StatelessWidget {
  final String label;

  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        ),
      ),
    );
  }
}

class _PrototypeBottomNav extends StatelessWidget {
  final int activeIndex;

  const _PrototypeBottomNav({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: '/snitch/dashboard'),
      _NavItem(icon: Icons.event_available_rounded, label: 'Attendance', route: '/snitch/attendance'),
      _NavItem(icon: Icons.star_rounded, label: 'Grades', route: '/snitch/grades'),
      _NavItem(icon: Icons.message_rounded, label: 'Messages', route: '/snitch/communication'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == activeIndex;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushReplacementNamed(context, item.route),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? SnitchTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 18, color: selected ? Colors.white : Colors.black54),
                    const SizedBox(height: 2),
                    Text(item.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.black54)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({required this.icon, required this.label, required this.route});
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SupportTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: SnitchTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: SnitchTheme.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.black54))])),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(question, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(answer, style: const TextStyle(color: Colors.black54))]),
    );
  }
}

String _shortMonth(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
