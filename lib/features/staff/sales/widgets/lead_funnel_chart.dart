import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';

class LeadFunnelChart extends StatelessWidget {
  final Map<String, int> statusBreakdown;

  const LeadFunnelChart({super.key, required this.statusBreakdown});

  @override
  Widget build(BuildContext context) {
    final total = statusBreakdown.values.fold(0, (sum, count) => sum + count);
    
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lead Pipeline', style: AppTextStyles.headline3),
          const SizedBox(height: AppDimens.paddingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusColumn(
                label: 'New',
                count: statusBreakdown['new'] ?? 0,
                total: total,
                color: AppColors.statusNew,
              ),
              _StatusColumn(
                label: 'Contacted',
                count: statusBreakdown['contacted'] ?? 0,
                total: total,
                color: AppColors.statusContacted,
              ),
              _StatusColumn(
                label: 'Interested',
                count: statusBreakdown['interested'] ?? 0,
                total: total,
                color: AppColors.statusInterested,
              ),
              _StatusColumn(
                label: 'Proposal',
                count: statusBreakdown['proposal_sent'] ?? 0,
                total: total,
                color: AppColors.statusProposal,
              ),
              _StatusColumn(
                label: 'Converted',
                count: statusBreakdown['converted'] ?? 0,
                total: total,
                color: AppColors.statusConverted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusColumn extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusColumn({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;
    final barHeight = total > 0 ? (count / total * 120).clamp(20.0, 120.0) : 20.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: AppTextStyles.subtitle1.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimens.paddingS),
        Container(
          width: 40,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
          ),
        ),
        const SizedBox(height: AppDimens.paddingS),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        Text(
          '$percentage%',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
