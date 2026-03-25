import 'package:flutter/material.dart';

class EditLeadScreen extends StatefulWidget {
  final String leadId;
  const EditLeadScreen({super.key, required this.leadId});

  @override
  State<EditLeadScreen> createState() => _EditLeadScreenState();
}

class _EditLeadScreenState extends State<EditLeadScreen> {
  // Same as AddLeadScreen but load existing data
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Lead')),
      body: const Center(
          child: Text('Edit Lead Screen - Implementation coming soon')),
    );
  }
}
