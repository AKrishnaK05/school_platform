import 'package:flutter/material.dart';

class SnitchAssignments extends StatelessWidget {
  const SnitchAssignments({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Snitch Assignments')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Assignments prototype placeholder'),
          ],
        ),
      ),
    );
  }
}
