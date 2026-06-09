import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF112A22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x3366CDAE)),
      ),
      child: child,
    );
  }
}
