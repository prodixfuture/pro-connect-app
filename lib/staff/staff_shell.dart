import 'package:flutter/material.dart';

// Common
import 'attendance/attendance_screen.dart';
import 'common/staff_profile.dart';
import '/staff/common/more_screen.dart';

// Chat
import 'chat/chat_list_screen.dart';

class StaffShell extends StatefulWidget {
  final Widget home;

  const StaffShell({
    super.key,
    required this.home,
  });

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int index = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      widget.home, // ✅ dynamic dashboard (sales / common)
      const AttendanceScreen(),
      const ChatListScreen(),
      const StaffMoreScreen(),
      const StaffProfile(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
