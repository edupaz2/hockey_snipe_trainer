import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../models/game_state.dart';

/// Grid layout displaying the 4 targets
class TargetGrid extends StatelessWidget {
  final List<TargetState> targets;
  final Function(int)? onTargetTap;

  const TargetGrid({
    super.key,
    required this.targets,
    this.onTargetTap,
  });

  @override
  Widget build(BuildContext context) {
    // Arrange targets in 2x2 grid representing goal corners
    // Top-Left (0), Top-Right (1)
    // Bottom-Left (2), Bottom-Right (3)
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final targetSize = (maxSize - 24) / 2;
        
        return Center(
          child: SizedBox(
            width: maxSize,
            height: maxSize,
            child: Stack(
              children: [
                // Goal outline
                _buildGoalOutline(maxSize),
                
                // Targets
                ...List.generate(targets.length.clamp(0, 4), (index) {
                  final target = targets[index];
                  return _buildTarget(
                    index: index,
                    target: target,
                    size: targetSize,
                    gridSize: maxSize,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalOutline(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Vertical center line
          Positioned(
            left: size / 2 - 1,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          // Horizontal center line
          Positioned(
            top: size / 2 - 1,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarget({
    required int index,
    required TargetState target,
    required double size,
    required double gridSize,
  }) {
    // Calculate position based on index
    final row = index ~/ 2;
    final col = index % 2;
    final padding = 12.0;
    
    final left = col == 0 ? padding : gridSize - size - padding;
    final top = row == 0 ? padding : gridSize - size - padding;
    
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: onTargetTap != null ? () => onTargetTap!(index) : null,
        child: _TargetWidget(
          target: target,
          size: size - padding * 2,
          index: index,
        ),
      ),
    );
  }
}

class _TargetWidget extends StatelessWidget {
  final TargetState target;
  final double size;
  final int index;

  const _TargetWidget({
    required this.target,
    required this.size,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = target.isActive ? target.color : AppColors.targetOff;
    
    Widget targetWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.3),
        border: Border.all(
          color: color,
          width: target.isActive ? 4 : 2,
        ),
        boxShadow: target.isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: target.isActive ? color : Colors.transparent,
            boxShadow: target.isActive
                ? [
                    BoxShadow(
                      color: color,
                      blurRadius: 15,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: target.isActive 
                    ? Colors.white 
                    : AppColors.textDisabled,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.2,
              ),
            ),
          ),
        ),
      ),
    );

    // Add pulse animation when active
    if (target.isActive) {
      targetWidget = targetWidget
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: const Duration(milliseconds: 600),
          );
    }

    return targetWidget;
  }
}
