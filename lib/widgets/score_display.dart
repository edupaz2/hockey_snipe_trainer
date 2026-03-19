import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// Displays the current score
class ScoreDisplay extends StatelessWidget {
  final int score;
  final String label;
  final Color? color;

  const ScoreDisplay({
    super.key,
    required this.score,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          score.toString(),
          style: GoogleFonts.orbitron(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            color: color ?? AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
