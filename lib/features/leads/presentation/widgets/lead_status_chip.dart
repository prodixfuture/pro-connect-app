import 'package:flutter/material.dart';

class LeadStatusChip extends StatelessWidget {
  final String status;

  const LeadStatusChip({super.key, required this.status});

  Color get color {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'contacted':
        return Colors.orange;
      case 'converted':
        return Colors.green;
      case 'lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
    );
  }
}
