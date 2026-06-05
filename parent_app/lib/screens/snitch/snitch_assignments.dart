import 'package:flutter/material.dart';
import '../../services/snitch_api.dart';
import '../../widgets/snitch_card.dart';
import '../../theme/snitch_theme.dart';


class SnitchAssignments extends StatefulWidget {
  const SnitchAssignments({super.key});

  @override
  State<SnitchAssignments> createState() => _SnitchAssignmentsState();
}

class _SnitchAssignmentsState extends State<SnitchAssignments> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await SnitchApi.fetchAssignments();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnitchTheme.bg,
      appBar: AppBar(title: const Text('Assignments')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final item = _items[i];
                  final subject = item['subject'] ?? '';
                  final title = item['title'] ?? 'Untitled';
                  final due = item['due'] ?? '';
                  final status = item['status'] ?? '';
                  return SnitchCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(title.toString()),
                        content: Text('Subject: $subject\nDue: $due\nStatus: $status'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: SnitchTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                          child: Center(child: Text(subject.toString().isNotEmpty ? subject.toString()[0] : '?', style: const TextStyle(color: SnitchTheme.primary, fontWeight: FontWeight.w800))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('$subject • Due $due', style: const TextStyle(color: Colors.black54))])),
                        const SizedBox(width: 8),
                        Chip(label: Text(status.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), backgroundColor: SnitchTheme.primary.withValues(alpha: 0.08), side: BorderSide.none),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
