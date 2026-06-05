import 'package:flutter/material.dart';

class SnitchPreview extends StatefulWidget {
  const SnitchPreview({super.key});

  @override
  State<SnitchPreview> createState() => _SnitchPreviewState();
}

class _SnitchPreviewState extends State<SnitchPreview> {
  double _opacity = 0.5;
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixel-Perfect Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_full),
            onPressed: () => Navigator.pushReplacementNamed(context, '/snitch/dashboard'),
            tooltip: 'Open live UI',
          ),
        ],
      ),
      body: Stack(
        children: [
          // background checker for contrast
          Container(color: Theme.of(context).scaffoldBackgroundColor),
          // screenshot layer (bottom)
          Positioned.fill(
            child: Image.asset('assets/snitch/stitch_mobile.png', fit: BoxFit.cover),
          ),
          // interactive overlay layer (draggable)
          Positioned(
            left: _offset.dx,
            top: _offset.dy,
            right: -_offset.dx,
            bottom: -_offset.dy,
            child: GestureDetector(
              onPanUpdate: (d) => setState(() => _offset += d.delta),
              child: Opacity(
                opacity: _opacity,
                child: Image.asset('assets/snitch/stitch_mobile.png', fit: BoxFit.cover),
              ),
            ),
          ),
          // controls
          Positioned(
            left: 12,
            right: 12,
            bottom: 18,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('Overlay opacity', style: TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text('${(_opacity * 100).round()}%'),
                      ],
                    ),
                    Slider(value: _opacity, onChanged: (v) => setState(() => _opacity = v)),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _offset = Offset.zero),
                          icon: const Icon(Icons.center_focus_strong),
                          label: const Text('Center'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _offset = const Offset(0, -30)),
                          icon: const Icon(Icons.arrow_upward),
                          label: const Text('Nudge Up'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _offset = const Offset(0, 30)),
                          icon: const Icon(Icons.arrow_downward),
                          label: const Text('Nudge Down'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
