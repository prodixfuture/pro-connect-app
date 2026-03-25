import 'package:flutter/material.dart';

// Shell
import 'staff_shell.dart';

// Dashboards
import 'common/staff_dashboard.dart';
import 'sales/sales_dashboard.dart';
import 'staff_task_dashboard.dart';
import '/modules/accounts/screens/accounts_dashboard.dart';

class StaffHome extends StatelessWidget {
  final String? department;

  const StaffHome({
    super.key,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    late final Widget homeScreen;

    switch (department) {
      // SALES DASHBOARD
      case 'sales':
        homeScreen = const SalesDashboard();
        break;

      // DESIGN DASHBOARD (FIXED)
      case 'design':
        homeScreen = const StaffTaskDashboard();
        break;

      // ACCOUNTS DASHBOARD (FIXED)
      case 'accounts':
        homeScreen = const AccountsDashboard();
        break;

      // DEFAULT STAFF DASHBOARD
      default:
        homeScreen = const StaffDashboard(
          child: Center(
            child: Text(
              'Welcome Staff',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        );
    }

    return StaffShell(home: homeScreen);
  }
}
