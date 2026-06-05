import 'package:flutter/material.dart';
import 'snitch_assignments.dart';
import 'snitch_marks.dart';
import 'snitch_login.dart';
import 'snitch_student_selector.dart';
import '../../services/snitch_api.dart';
import '../../theme/snitch_theme.dart';
import '../../widgets/snitch_card.dart';

class SnitchDashboard extends StatefulWidget {
  const SnitchDashboard({super.key});

  @override
  State<SnitchDashboard> createState() => _SnitchDashboardState();
}

class _SnitchDashboardState extends State<SnitchDashboard> {
  Map<String, dynamic> _summary = {};
  bool _loading = true;
  double _contentOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final summary = await SnitchApi.fetchDashboardSummary();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
      _contentOpacity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignments = List<Map<String, dynamic>>.from(_summary['upcoming_assignments'] ?? []);
    final notifications = List<Map<String, dynamic>>.from(_summary['notifications'] ?? []);
    final feesDue = _summary['fees_due'] ?? 0;
    final avg = _summary['average_marks'] ?? 0;
    final attendanceTotal = _summary['attendance_total'] ?? 0;
    final attendancePresent = _summary['attendance_present'] ?? 0;
    final attendanceRate = attendanceTotal == 0 ? 0 : ((attendancePresent * 100) / attendanceTotal).round();
    final parentStudentsFuture = SnitchApi.fetchParentStudents();

    return Scaffold(
      backgroundColor: SnitchTheme.bg,
      bottomNavigationBar: const _DashboardBottomNav(activeIndex: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 450),
                  opacity: _contentOpacity,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                    child: Stack(
                      children: [
                      Positioned(
                        top: -80,
                        right: -50,
                        child: _GlowOrb(color: SnitchTheme.accent.withValues(alpha: 0.16), size: 180),
                      ),
                      Positioned(
                        top: 120,
                        left: -70,
                        child: _GlowOrb(color: SnitchTheme.tertiary.withValues(alpha: 0.10), size: 140),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _DashboardTopBar(
                              onLogout: () async {
                                final navigator = Navigator.of(context);
                                await SnitchApi.clearToken();
                                if (!mounted) return;
                                navigator.pushReplacement(MaterialPageRoute(builder: (_) => const SnitchLogin()));
                              },
                              onStudentTap: () async {
                                final changed = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SnitchStudentSelector()));
                                if (changed == true) _load();
                              },
                              studentsFuture: parentStudentsFuture,
                            ),
                            const SizedBox(height: 16),
                            SnitchCard(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 54,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [SnitchTheme.primary, SnitchTheme.accent]),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: const Icon(Icons.school_rounded, color: Colors.white),
                                      ),
                                      const SizedBox(width: 14),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Parent command center', style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
                                            SizedBox(height: 4),
                                            Text('Track school life at a glance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: _MetricPill(label: 'Fees Due', value: '₹ $feesDue', tone: SnitchTheme.primary)),
                                      const SizedBox(width: 10),
                                      Expanded(child: _MetricPill(label: 'Average', value: '$avg%', tone: SnitchTheme.secondary)),
                                      const SizedBox(width: 10),
                                      Expanded(child: _MetricPill(label: 'Attendance', value: '$attendanceRate%', tone: SnitchTheme.tertiary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionCard(
                                    icon: Icons.event_available_outlined,
                                    label: 'Attendance',
                                    subtitle: 'Daily presence trend',
                                    tint: SnitchTheme.primary,
                                    onTap: () => Navigator.pushNamed(context, '/snitch/attendance'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionCard(
                                    icon: Icons.schedule_outlined,
                                    label: 'Timetable',
                                    subtitle: 'Today\'s classes',
                                    tint: SnitchTheme.secondary,
                                    onTap: () => Navigator.pushNamed(context, '/snitch/timetable'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionCard(
                                    icon: Icons.bar_chart_rounded,
                                    label: 'Grades',
                                    subtitle: 'Exam performance',
                                    tint: SnitchTheme.tertiary,
                                    onTap: () => Navigator.pushNamed(context, '/snitch/grades'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionCard(
                                    icon: Icons.forum_outlined,
                                    label: 'Messages',
                                    subtitle: 'Teacher updates',
                                    tint: const Color(0xFF7B61FF),
                                    onTap: () => Navigator.pushNamed(context, '/snitch/communication'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _SectionHeader(
                              title: 'Upcoming assignments',
                              actionLabel: 'See all',
                              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SnitchAssignments())),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 162,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: assignments.isEmpty ? 1 : assignments.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 12),
                                itemBuilder: (ctx, i) {
                                  if (assignments.isEmpty) {
                                    return const SnitchCard(
                                      padding: EdgeInsets.all(16),
                                      child: SizedBox(width: 280, child: Center(child: Text('No assignments yet'))),
                                    );
                                  }
                                  final item = assignments[i];
                                  return SnitchCard(
                                    padding: const EdgeInsets.all(16),
                                    onTap: () {},
                                    child: SizedBox(
                                      width: 280,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: SnitchTheme.primary.withValues(alpha: 0.10),
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: const Icon(Icons.assignment_outlined, color: SnitchTheme.primary, size: 20),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(item['subject'] ?? '', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(item['title'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.15)),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Due ${item['due'] ?? ''}', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600)),
                                              Chip(
                                                label: Text(item['status'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                                backgroundColor: SnitchTheme.primary.withValues(alpha: 0.08),
                                                side: BorderSide.none,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            _SectionHeader(title: 'Notifications', actionLabel: 'Open all', onAction: () {}),
                            const SizedBox(height: 10),
                            if (notifications.isEmpty)
                              const SnitchCard(child: SizedBox(width: double.infinity, child: Text('No notifications right now')))
                            else
                              ...notifications.map(
                                (n) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: SnitchCard(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(color: SnitchTheme.tertiary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                                          child: const Icon(Icons.notifications_active_outlined, color: SnitchTheme.tertiary, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                                              const SizedBox(height: 4),
                                              Text(n['subtitle'] ?? '', style: const TextStyle(color: Colors.black54)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Center(child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SnitchMarks())), child: const Text('View detailed marks'))),
                          ],
                        ), // end Column
                      ), // end Padding
                    ], // end Stack children
                  ), // end Stack
                ), // end ConstrainedBox
              ), // end AnimatedOpacity
            ), // end SingleChildScrollView
          ), // end RefreshIndicator
        ); // end Scaffold
  }
}


class _DashboardTopBar extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> studentsFuture;
  final VoidCallback onLogout;
  final VoidCallback onStudentTap;

  const _DashboardTopBar({required this.studentsFuture, required this.onLogout, required this.onStudentTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [SnitchTheme.primary, SnitchTheme.accent]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.family_restroom_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EduParent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 2),
              Text('A clean school command center', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: studentsFuture,
          builder: (context, snap) {
            final students = snap.data ?? const [];
            return OutlinedButton.icon(
              onPressed: onStudentTap,
              icon: const Icon(Icons.switch_account_rounded),
              label: Text(students.isNotEmpty ? '${students.first['name']}' : 'Student'),
            );
          },
        ),
        const SizedBox(width: 8),
        IconButton(onPressed: onLogout, icon: const Icon(Icons.logout_rounded)),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;

  const _MetricPill({required this.label, required this.value, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: tone, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: tone, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.subtitle, required this.tint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SnitchCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.2)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({required this.title, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _DashboardBottomNav extends StatelessWidget {
  final int activeIndex;

  const _DashboardBottomNav({required this.activeIndex});

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

