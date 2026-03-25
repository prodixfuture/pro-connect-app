// PRIORITY CHIP WIDGET
// File: lib/modules/task_management/widgets/priority_chip.dart

import 'package:flutter/material.dart';
import '../utils/task_constants.dart';

class PriorityChip extends StatelessWidget {
  final String priority;
  final ChipSize size;

  const PriorityChip({
    Key? key,
    required this.priority,
    this.size = ChipSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = TaskPriority.getColor(priority);
    final label = TaskPriority.getLabel(priority);
    final icon = TaskPriority.getIcon(priority);

    double fontSize;
    double iconSize;
    EdgeInsets padding;

    switch (size) {
      case ChipSize.small:
        fontSize = 10;
        iconSize = 12;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        break;
      case ChipSize.large:
        fontSize = 14;
        iconSize = 18;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        break;
      case ChipSize.medium:
      default:
        fontSize = 12;
        iconSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
