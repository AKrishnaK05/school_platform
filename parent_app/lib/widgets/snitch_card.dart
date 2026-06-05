import 'package:flutter/material.dart';
import '../theme/snitch_theme.dart';

class SnitchCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const SnitchCard({required this.child, this.padding = const EdgeInsets.all(12), this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: SnitchTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECF5)),
        boxShadow: const [BoxShadow(color: Color(0x14083457), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: card);
    }
    return card;
  }
}
