import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pro_connect/staff/leave/leave_list_screen.dart';
import 'package:pro_connect/staff/more/staff_my_requests_screen.dart';

import 'admin/manage/admin_expense_requests_screen.dart';
import 'admin/manage/admin_management_hub.dart';
import 'admin/manage/admin_tickets_screen.dart';
import 'admin/manage/admin_trial_leads_screen.dart';
import 'firebase_options.dart';
import 'auth/auth_gate.dart';

import 'core/splash/splash_screen.dart';
import 'core/notifications/push_service.dart';
import 'modules/settings/notification_settings_screen.dart';

// SALES SCREENS
import 'staff/more/raise_expense_screen.dart';
import 'staff/more/raise_ticket_screen.dart';
import 'staff/more/staff_add_lead_screen.dart';
import 'staff/sales/sales_dashboard.dart';
import 'staff/sales/leads_page.dart';
import 'staff/sales/add_lead_screen.dart';
import 'staff/sales/edit_lead_screen.dart';
import 'staff/common/notification_screen.dart';

// MANAGER
import 'manager/manager_chat_list_screen.dart';
import 'admin/admin_badge_management.dart';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProConnectApp());
}

class ProConnectApp extends StatelessWidget {
  const ProConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pro Connect',

      // 🌗 LIGHT THEME
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366f1),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1a1a1a),
          iconTheme: IconThemeData(color: Color(0xFF1a1a1a)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6366f1),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366f1),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366f1), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF3F4F6),
          selectedColor: const Color(0xFF6366f1),
          labelStyle: const TextStyle(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // 🌑 DARK THEME
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366f1),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6366f1),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),

      themeMode: ThemeMode.light,

      // 🚀 ENTRY POINT — SplashScreen handles auth routing internally
      home: const SplashScreen(),

      // 🧭 GLOBAL NAMED ROUTES
      routes: {
        // === AUTH ===
        '/auth': (_) => const AuthGate(),

        // === NOTIFICATIONS ===
        '/notifications': (_) => const NotificationScreen(),
        '/notification-settings': (_) => const NotificationSettingsScreen(),

        // === SALES ROUTES ===
        '/sales/dashboard': (_) => const SalesDashboard(),
        '/sales/leads': (_) => const LeadsPage(),
        '/sales/add-lead': (_) => const AddLeadScreen(),
        '/sales/edit-lead': (_) => const EditLeadScreen(),
        '/admin/badges': (_) => const AdminBadgeManagement(),

        // Alternative route names (for compatibility)
        '/leads': (_) => const LeadsPage(),
        '/dashboard': (_) => const SalesDashboard(),

        // === MORE ROUTES ===
        '/more/raise-ticket': (_) => const RaiseTicketScreen(),
        '/more/raise-expense': (_) => const RaiseExpenseScreen(),
        '/more/add-lead': (_) => const StaffAddLeadScreen(),
        '/leave/leave-request': (_) => const LeaveListScreen(),
        '/more/staff-request': (_) => const StaffMyRequestsScreen(),

        // === ADMIN MANAGE ROUTES ===
        '/admin/manage/hub': (_) => const AdminManagementHub(),
        '/admin/manage/tickets': (_) => const AdminTicketsScreen(),
        '/admin/manage/expense-requests': (_) =>
            const AdminExpenseRequestsScreen(),
        '/admin/manage/trial-leads': (_) => const AdminTrialLeadsScreen(),

        // === MANAGER ROUTES ===
        '/manager/chat': (_) => const ManagerChatListScreen(),
      },

      // 🔴 404 FALLBACK
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    '404 - Page Not Found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Route: ${settings.name}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(_, '/sales/dashboard'),
                    child: const Text('Go to Dashboard'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
