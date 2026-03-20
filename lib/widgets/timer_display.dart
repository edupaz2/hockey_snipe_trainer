import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// Displays the game timer
class TimerDisplay extends StatelessWidget {
  final String timeText;
  final bool isCountdown;
  final Color color;

  const TimerDisplay({
    super.key,
    required this.timeText,
    this.isCountdown = true,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCountdown ? Icons.timer : Icons.timer_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            timeText,
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
