import 'package:flutter/material.dart';
import '../../services/snitch_api.dart';

class SnitchStudentSelector extends StatefulWidget {
  const SnitchStudentSelector({super.key});

  @override
  State<SnitchStudentSelector> createState() => _SnitchStudentSelectorState();
}

class _SnitchStudentSelectorState extends State<SnitchStudentSelector> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await SnitchApi.fetchParentStudents();
    if (!mounted) return;
    setState(() {
      _students = s;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Student')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _students.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (c, i) {
                final s = _students[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage: s['image'] != null ? NetworkImage(s['image'] as String) : null,
                      child: s['image'] == null ? const Icon(Icons.person, color: Colors.blue) : null,
                    ),
                    title: Text(s['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(s['class_name'] ?? ''),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      await SnitchApi.setPrimaryStudent(s['id'] as int);
                      if (!mounted) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        Navigator.pop(context, true);
                      });
                    },
                  ),
                );
              },
            ),
    );
  }
}
