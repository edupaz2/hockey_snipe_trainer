import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// Shows connection status at the top of screens
class ConnectionStatusBar extends StatelessWidget {
  final int deviceCount;

  const ConnectionStatusBar({
    super.key,
    required this.deviceCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
            const Icon(
            Icons.bluetooth_connected,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '$deviceCount target${deviceCount != 1 ? 's' : ''} connected',
            style: GoogleFonts.roboto(
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            'Ready to play',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
