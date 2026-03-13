import 'package:flutter/material.dart';

// Manager modules
import '../admin/Attendance/admin_own_attendance_screen.dart';
import 'leave/leave_approval_screen.dart';
import 'manager_chat_list_screen.dart';
import 'manager_task_update_screen.dart';
import '/screens/manager/content_calendar_manager.dart';

// Task Management - ADD THIS
import '/manager/manager_projects_list.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  int index = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = const [
      AdminOwnAttendanceScreen(), // 0 → Attendance
      LeaveApprovalScreen(), // 1 → Leave approvals
      ManagerChatListScreen(), // 2 → Chat (OLD working chat)
      ManagerProjectsList(), // 3 → Tasks (NEW!)
      ManagerTaskUpdateScreen(),
      ContentCalendarManager(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Panel'),
      ),
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Leaves',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Tasks update',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Create Culendar',
          ),
        ],
      ),
    );
  }
}
