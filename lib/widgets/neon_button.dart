import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// A stylized neon button with glow effects
class NeonButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isLarge;
  final bool disabled;

  const NeonButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
    this.isLarge = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onPressed == null;
    final effectiveColor = isDisabled ? AppColors.textDisabled : color;
    
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 32 : 20,
          vertical: isLarge ? 20 : 14,
        ),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: isDisabled ? 0.1 : 0.15),
          borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
          border: Border.all(
            color: effectiveColor.withValues(alpha: isDisabled ? 0.3 : 0.6),
            width: 2,
          ),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: effectiveColor,
              size: isLarge ? 28 : 22,
            ),
            SizedBox(width: isLarge ? 12 : 8),
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: isLarge ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: effectiveColor,
                letterSpacing: isLarge ? 2 : 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
