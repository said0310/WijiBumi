import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.info.withValues(alpha: 0.12);
    Color fg = AppColors.info;

    switch (status) {
      case AppConstants.statusPendingPayment:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        break;
      case AppConstants.statusAwaitingConfirmation:
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purple;
        break;
      case AppConstants.statusProcessing:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue;
        break;
      case AppConstants.statusReadyToShip:
        bg = Colors.teal.withValues(alpha: 0.15);
        fg = Colors.teal;
        break;
      case AppConstants.statusShipped:
        bg = AppColors.secondary.withValues(alpha: 0.15);
        fg = AppColors.secondary;
        break;
      case AppConstants.statusCompleted:
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case AppConstants.statusCancelled:
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppConstants.getStatusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
