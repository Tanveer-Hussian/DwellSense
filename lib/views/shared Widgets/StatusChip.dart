import 'package:flutter/material.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/shared%20Widgets/StatusConfig.dart';

// Colored chip to display booking/hostel/complaint status.
// ─────────────────────────────────────────────────────────────────────────────

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  // Map status string → display label + color
   StatusConfig _getConfig() {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'confirmed':
      case 'resolved':
        return StatusConfig(_capitalize(status), AppColors.success,
            AppColors.chipApproved);
      case 'pending':
        return StatusConfig(
            'Pending', AppColors.warning, AppColors.chipPending);
      case 'rejected':
      case 'cancelled':
        return StatusConfig(_capitalize(status), AppColors.error,
            AppColors.chipRejected);
      case 'expired':
        return StatusConfig('Expired', AppColors.textSecondary,
            AppColors.divider.withValues(alpha: 0.5));
      case 'in_progress':
        return StatusConfig('In Progress', AppColors.info,
            AppColors.info.withValues(alpha: 0.1));
      default:
        return StatusConfig(status, AppColors.textSecondary, AppColors.divider);
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
