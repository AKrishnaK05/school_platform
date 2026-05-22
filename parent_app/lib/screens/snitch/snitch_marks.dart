import 'package:flutter/material.dart';

class SnitchMarks extends StatelessWidget {
  const SnitchMarks({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Snitch Marks')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Marks prototype placeholder'),
          ],
        ),
      ),
    );
  }
}
