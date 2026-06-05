import 'package:flutter/material.dart';
import '../../services/snitch_api.dart';
import '../../widgets/snitch_card.dart';
import '../../theme/snitch_theme.dart';

class SnitchMarks extends StatefulWidget {
  const SnitchMarks({super.key});

  @override
  State<SnitchMarks> createState() => _SnitchMarksState();
}

class _SnitchMarksState extends State<SnitchMarks> {
  final exams = ['Periodic Assessment 1', 'Periodic Assessment 2', 'Mid Term', 'End Term'];
  String selected = 'Periodic Assessment 1';
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFor(selected);
  }

  Future<void> _loadFor(String exam) async {
    setState(() => _loading = true);
    final items = await SnitchApi.fetchMarks(exam);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      backgroundColor: SnitchTheme.bg,
      appBar: AppBar(title: const Text('Marks')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select exam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exams.map((e) {
                final active = e == selected;
                return ChoiceChip(
                  label: Text(e, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.w700)),
                  selected: active,
                  onSelected: (v) {
                    if (!v) return;
                    setState(() => selected = e);
                    _loadFor(e);
                  },
                  selectedColor: SnitchTheme.primary,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: active ? SnitchTheme.primary : const Color(0xFFE2E8F0)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final row = items[i];
                        return SnitchCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(color: SnitchTheme.secondary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.menu_book_rounded, color: SnitchTheme.secondary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(row['subject'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                              Text('${row['marks']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: SnitchTheme.primary)),
                            ],
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
