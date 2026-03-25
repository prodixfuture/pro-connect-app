import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../client/models/lead.dart';
import '../../../../client/services/firestore_service.dart';

class AddLeadScreen extends ConsumerStatefulWidget {
  const AddLeadScreen({super.key});

  @override
  ConsumerState<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends ConsumerState<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  // Controllers
  final _businessNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  // Form values
  LeadSource _selectedSource = LeadSource.website;
  LeadPriority _selectedPriority = LeadPriority.warm;
  DateTime? _followUpDate;

  bool _isLoading = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLead() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final lead = Lead(
        id: '',
        businessName: _businessNameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        leadSource: _selectedSource,
        status: LeadStatus.newLead,
        priority: _selectedPriority,
        assignedTo: user.uid,
        assignedToName: user.displayName ?? 'User',
        department: 'sales',
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        nextFollowUpDate: _followUpDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createLead(lead);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lead created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectFollowUpDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _followUpDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Lead', style: AppTextStyles.headline2),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          children: [
            // Business Name
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name *',
                hintText: 'Enter business or company name',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) =>
                  Validators.required(value, fieldName: 'Business name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Contact Person
            TextFormField(
              controller: _contactPersonController,
              decoration: const InputDecoration(
                labelText: 'Contact Person *',
                hintText: 'Enter contact person name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) =>
                  Validators.required(value, fieldName: 'Contact person'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: 'Enter phone number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (Optional)',
                hintText: 'Enter email address',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: AppDimens.paddingL),

            // Lead Source
            Text('Lead Source *', style: AppTextStyles.subtitle2),
            const SizedBox(height: AppDimens.paddingS),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LeadSource.values.map((source) {
                final isSelected = _selectedSource == source;
                return ChoiceChip(
                  label: Text(source.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedSource = source);
                  },
                  selectedColor: AppColors.primaryLight,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.paddingL),

            // Priority
            Text('Priority *', style: AppTextStyles.subtitle2),
            const SizedBox(height: AppDimens.paddingS),
            Row(
              children: [
                Expanded(
                  child: _PriorityButton(
                    priority: LeadPriority.hot,
                    isSelected: _selectedPriority == LeadPriority.hot,
                    onTap: () =>
                        setState(() => _selectedPriority = LeadPriority.hot),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PriorityButton(
                    priority: LeadPriority.warm,
                    isSelected: _selectedPriority == LeadPriority.warm,
                    onTap: () =>
                        setState(() => _selectedPriority = LeadPriority.warm),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PriorityButton(
                    priority: LeadPriority.cold,
                    isSelected: _selectedPriority == LeadPriority.cold,
                    onTap: () =>
                        setState(() => _selectedPriority = LeadPriority.cold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingL),

            // Follow-up Date
            Text('Next Follow-up Date (Optional)',
                style: AppTextStyles.subtitle2),
            const SizedBox(height: AppDimens.paddingS),
            InkWell(
              onTap: _selectFollowUpDate,
              child: Container(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _followUpDate == null
                          ? 'Select date and time'
                          : '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year} at ${_followUpDate!.hour}:${_followUpDate!.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyles.body1,
                    ),
                    const Spacer(),
                    if (_followUpDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _followUpDate = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional notes',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppDimens.paddingXL),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveLead,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Lead'),
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Cancel Button
            OutlinedButton(
              onPressed: _isLoading ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: AppDimens.paddingXL),
          ],
        ),
      ),
    );
  }
}

class _PriorityButton extends StatelessWidget {
  final LeadPriority priority;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityButton({
    required this.priority,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              priority.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              priority.label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor() {
    switch (priority) {
      case LeadPriority.hot:
        return AppColors.priorityHot;
      case LeadPriority.warm:
        return AppColors.priorityWarm;
      case LeadPriority.cold:
        return AppColors.priorityCold;
    }
  }
}
