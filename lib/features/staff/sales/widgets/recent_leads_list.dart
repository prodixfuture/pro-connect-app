import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../client/models/lead.dart';

class RecentLeadsList extends StatelessWidget {
  final List<Lead> leads;
  final Function(Lead)? onLeadTap;

  const RecentLeadsList({
    super.key,
    required this.leads,
    this.onLeadTap,
  });

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'No leads yet',
              style: AppTextStyles.subtitle1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Add your first lead to get started',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: leads
          .take(10)
          .map((lead) => _LeadCard(
                lead: lead,
                onTap: () => onLeadTap?.call(lead),
              ))
          .toList(),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback? onTap;

  const _LeadCard({
    required this.lead,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusM),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.marginM),
        padding: const EdgeInsets.all(AppDimens.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Lead avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(lead.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  child: Center(
                    child: Text(
                      lead.businessName.isNotEmpty
                          ? lead.businessName[0].toUpperCase()
                          : 'L',
                      style: AppTextStyles.headline3.copyWith(
                        color: _getStatusColor(lead.status),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                // Lead info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead.businessName, style: AppTextStyles.subtitle1),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lead.contactPerson,
                              style: AppTextStyles.body2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                _StatusBadge(status: lead.status),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),
            // Additional info row
            Row(
              children: [
                // Priority indicator
                _PriorityChip(priority: lead.priority),
                const SizedBox(width: AppDimens.paddingS),
                // Source tag
                _SourceTag(source: lead.leadSource),
                const Spacer(),
                // Time indicator
                Text(
                  DateFormatter.formatRelative(lead.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            // Follow-up indicator
            if (lead.nextFollowUpDate != null) ...[
              const SizedBox(height: AppDimens.paddingM),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppDimens.paddingM),
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 16,
                    color: DateFormatter.isOverdue(lead.nextFollowUpDate!)
                        ? AppColors.error
                        : DateFormatter.isToday(lead.nextFollowUpDate!)
                            ? AppColors.warning
                            : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Follow-up: ${DateFormatter.formatFollowUpDate(lead.nextFollowUpDate!)}',
                      style: AppTextStyles.caption.copyWith(
                        color: DateFormatter.isOverdue(lead.nextFollowUpDate!)
                            ? AppColors.error
                            : DateFormatter.isToday(lead.nextFollowUpDate!)
                                ? AppColors.warning
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return AppColors.statusNew;
      case LeadStatus.contacted:
        return AppColors.statusContacted;
      case LeadStatus.interested:
        return AppColors.statusInterested;
      case LeadStatus.proposalSent:
        return AppColors.statusProposal;
      case LeadStatus.converted:
        return AppColors.statusConverted;
      case LeadStatus.lost:
        return AppColors.statusLost;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final LeadStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case LeadStatus.newLead:
        return AppColors.statusNew;
      case LeadStatus.contacted:
        return AppColors.statusContacted;
      case LeadStatus.interested:
        return AppColors.statusInterested;
      case LeadStatus.proposalSent:
        return AppColors.statusProposal;
      case LeadStatus.converted:
        return AppColors.statusConverted;
      case LeadStatus.lost:
        return AppColors.statusLost;
    }
  }
}

class _PriorityChip extends StatelessWidget {
  final LeadPriority priority;

  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            priority.emoji,
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

class _SourceTag extends StatelessWidget {
  final LeadSource source;

  const _SourceTag({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        source.label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.info,
          fontSize: 11,
        ),
      ),
    );
  }
}
