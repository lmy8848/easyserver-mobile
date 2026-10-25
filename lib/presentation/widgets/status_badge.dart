import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
      case 'running':
      case 'success':
        color = Colors.green;
        break;
      case 'inactive':
      case 'stopped':
      case 'failed':
      case 'error':
        color = Colors.red;
        break;
      case 'activating':
      case 'deactivating':
      case 'reloading':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: fontSize, fontWeight: FontWeight.w500)),
    );
  }
}
