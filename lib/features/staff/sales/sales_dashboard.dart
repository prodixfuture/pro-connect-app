import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../client/models/dashboard_metrics.dart';
import '../../../../client/models/lead.dart';
import 'widgets/kpi_card.dart';
import 'widgets/lead_funnel_chart.dart';
import 'widgets/quick_action_button.dart';
import 'widgets/recent_leads_list.dart';

// TEMPORARY: Mock providers until you add the real ones
// Once you add the provider files, remove these and import the real ones

final mockDashboardProvider =
    StateProvider<DashboardMetrics>((ref) => DashboardMetrics.empty());
final mockRecentLeadsProvider = StateProvider<List<Lead>>((ref) => []);
final mockUserNameProvider = StateProvider<String>((ref) => 'Sales Team');

class SalesDashboardScreen extends ConsumerStatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  ConsumerState<SalesDashboardScreen> createState() =>
      _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends ConsumerState<SalesDashboardScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // TODO: Replace with real data loading
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data for now
    ref.read(mockDashboardProvider.notifier).state = DashboardMetrics(
      totalLeads: 45,
      newLeadsToday: 5,
      followUpsDueToday: 8,
      convertedLeads: 12,
      conversionRate: 26.7,
      statusBreakdown: {
        'new': 8,
        'contacted': 12,
        'interested': 10,
        'proposal_sent': 3,
        'converted': 12,
        'lost': 0,
      },
      lastUpdated: DateTime.now(),
    );

    setState(() => _isLoading = false);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(mockDashboardProvider);
    final recentLeads = ref.watch(mockRecentLeadsProvider);
    final userName = ref.watch(mockUserNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: AppTextStyles.headline2),
        actions: [
          // Notifications button
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context),
          ),
          // User profile avatar
          Padding(
            padding: const EdgeInsets.only(right: AppDimens.paddingM),
            child: GestureDetector(
              onTap: () => _navigateToProfile(context),
              child: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting with user name
              Text(
                'Good ${_getGreeting()}, $userName!',
                style: AppTextStyles.headline1,
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                'Here\'s what\'s happening with your leads today',
                style: AppTextStyles.body2,
              ),
              const SizedBox(height: AppDimens.paddingL),

              // KPI Cards with real data
              if (_isLoading)
                _buildKPIGridSkeleton(context)
              else
                _buildKPIGrid(context, metrics),
              const SizedBox(height: AppDimens.paddingL),

              // Lead Funnel with real data
              if (!_isLoading)
                LeadFunnelChart(statusBreakdown: metrics.statusBreakdown),
              const SizedBox(height: AppDimens.paddingL),

              // Quick Actions
              Text(
                'Quick Actions',
                style: AppTextStyles.headline3,
              ),
              const SizedBox(height: AppDimens.paddingM),
              _buildQuickActions(context),
              const SizedBox(height: AppDimens.paddingL),

              // Recent Leads
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Leads',
                    style: AppTextStyles.headline3,
                  ),
                  TextButton(
                    onPressed: () => _navigateToLeadsList(context),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.paddingM),

              // Recent leads list
              if (_isLoading)
                _buildLeadsListSkeleton()
              else
                RecentLeadsList(
                  leads: recentLeads,
                  onLeadTap: (lead) => _navigateToLeadDetail(context, lead),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddLead(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Lead'),
      ),
    );
  }

  Widget _buildKPIGrid(BuildContext context, DashboardMetrics metrics) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200 ? 5 : (width > 768 ? 3 : 2);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: AppDimens.marginM,
      mainAxisSpacing: AppDimens.marginM,
      childAspectRatio: width > 768 ? 1.5 : 1.2,
      children: [
        KPICard(
          icon: Icons.people_outline,
          label: 'Total Leads',
          value: metrics.totalLeads.toString(),
          iconColor: AppColors.primary,
          trend: '+5',
          isPositive: true,
          onTap: () => _navigateToLeadsList(context),
        ),
        KPICard(
          icon: Icons.fiber_new,
          label: 'New Today',
          value: metrics.newLeadsToday.toString(),
          iconColor: AppColors.statusNew,
          trend: '+${metrics.newLeadsToday}',
          isPositive: true,
          onTap: () => _navigateToLeadsList(context, filter: 'today'),
        ),
        KPICard(
          icon: Icons.event_outlined,
          label: 'Follow-ups Due',
          value: metrics.followUpsDueToday.toString(),
          iconColor: AppColors.warning,
          onTap: () => _navigateToFollowUps(context),
        ),
        KPICard(
          icon: Icons.check_circle_outline,
          label: 'Converted',
          value: metrics.convertedLeads.toString(),
          iconColor: AppColors.success,
          trend: '+2',
          isPositive: true,
          onTap: () => _navigateToLeadsList(context, filter: 'converted'),
        ),
        KPICard(
          icon: Icons.trending_up,
          label: 'Conversion Rate',
          value: '${metrics.conversionRate.toStringAsFixed(1)}%',
          iconColor: AppColors.info,
          trend: '+3.2%',
          isPositive: true,
          onTap: () => _showConversionDetails(context, metrics),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        QuickActionButton(
          icon: Icons.add_circle_outline,
          title: 'Add New Lead',
          subtitle: 'Create a new lead entry',
          onTap: () => _navigateToAddLead(context),
        ),
        const SizedBox(height: AppDimens.marginM),
        QuickActionButton(
          icon: Icons.list_alt,
          title: 'View My Leads',
          subtitle: 'See all your leads',
          onTap: () => _navigateToLeadsList(context),
        ),
        const SizedBox(height: AppDimens.marginM),
        QuickActionButton(
          icon: Icons.today,
          title: 'Today\'s Follow-ups',
          subtitle: 'Manage scheduled follow-ups',
          onTap: () => _navigateToFollowUps(context),
        ),
      ],
    );
  }

  // Navigation methods
  void _navigateToAddLead(BuildContext context) {
    context.push('/sales/add-lead');
  }

  void _navigateToLeadsList(BuildContext context, {String? filter}) {
    if (filter != null) {
      context.push('/sales/leads?filter=$filter');
    } else {
      context.push('/sales/leads');
    }
  }

  void _navigateToLeadDetail(BuildContext context, Lead lead) {
    context.push('/sales/leads/${lead.id}');
  }

  void _navigateToFollowUps(BuildContext context) {
    context.push('/sales/follow-ups');
  }

  void _navigateToProfile(BuildContext context) {
    context.push('/profile');
  }

  // Action methods
  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_outlined),
            SizedBox(width: 8),
            Text('Notifications'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationItem(
              'Follow-up reminder',
              'You have 3 follow-ups due today',
              Icons.event,
              AppColors.warning,
              () {
                Navigator.pop(context);
                _navigateToFollowUps(context);
              },
            ),
            const Divider(),
            _buildNotificationItem(
              'New lead assigned',
              '2 new leads added to your pipeline',
              Icons.person_add,
              AppColors.primary,
              () {
                Navigator.pop(context);
                _navigateToLeadsList(context, filter: 'today');
              },
            ),
            const Divider(),
            _buildNotificationItem(
              'Overdue follow-ups',
              'You have 1 overdue follow-up',
              Icons.warning_amber,
              AppColors.error,
              () {
                Navigator.pop(context);
                _navigateToFollowUps(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: AppTextStyles.subtitle2),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showConversionDetails(BuildContext context, DashboardMetrics metrics) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conversion Details', style: AppTextStyles.headline2),
            const SizedBox(height: AppDimens.paddingL),
            _buildDetailRow('Total Leads', metrics.totalLeads.toString()),
            _buildDetailRow(
                'Converted Leads', metrics.convertedLeads.toString()),
            _buildDetailRow('Conversion Rate',
                '${metrics.conversionRate.toStringAsFixed(1)}%'),
            const SizedBox(height: AppDimens.paddingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToLeadsList(context, filter: 'converted');
                },
                child: const Text('View Converted Leads'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body2),
          Text(value, style: AppTextStyles.subtitle1),
        ],
      ),
    );
  }

  // Loading states
  Widget _buildKPIGridSkeleton(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200 ? 5 : (width > 768 ? 3 : 2);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: AppDimens.marginM,
      mainAxisSpacing: AppDimens.marginM,
      childAspectRatio: width > 768 ? 1.5 : 1.2,
      children: List.generate(
        5,
        (index) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadsListSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: AppDimens.marginM),
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}
