import 'package:flutter/material.dart';
import '../../core/localization/strings.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (status) {
      'resolved' => (
        Icons.check_circle_outline,
        AppPalette.green,
        AppPalette.softGreen,
      ),
      'in_progress' || 'accepted' => (
        Icons.build_outlined,
        const Color(0xFF775315),
        const Color(0xFFF5EDDA),
      ),
      'resolved_pending_confirmation' => (
        Icons.task_alt,
        const Color(0xFF775315),
        const Color(0xFFF5EDDA),
      ),
      'rejected' => (
        Icons.block_outlined,
        const Color(0xFF9A3934),
        const Color(0xFFF7E8E5),
      ),
      'under_review' => (
        Icons.schedule,
        AppPalette.muted,
        const Color(0xFFEEF0EB),
      ),
      _ => (Icons.radio_button_checked, AppPalette.green, AppPalette.softGreen),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              context.statusLabel(status),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
