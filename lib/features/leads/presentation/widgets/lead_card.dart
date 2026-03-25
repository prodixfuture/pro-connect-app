import 'package:flutter/material.dart';
import '../../data/models/lead_model.dart';
import 'lead_status_chip.dart';

class LeadCard extends StatelessWidget {
  final LeadModel lead;

  const LeadCard({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          lead.name,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lead.contactPerson),
            const SizedBox(height: 6),
            LeadStatusChip(status: lead.status),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/lead-detail',
            arguments: lead,
          );
        },
      ),
    );
  }
}
