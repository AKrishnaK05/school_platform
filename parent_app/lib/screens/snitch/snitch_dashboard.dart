import 'package:flutter/material.dart';

class SnitchDashboard extends StatelessWidget {
  const SnitchDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Snitch Dashboard (Prototype)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/snitch/parent_dashboard.png',
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Prototype dashboard imported from Stitch.\nConvert layout to native widgets per DESIGN_academic_clarity.md.',
            ),
          ],
        ),
      ),
    );
  }
}
