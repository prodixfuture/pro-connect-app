import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dashboard/client_dashboard.dart';
import '/client/client_invoice_screen.dart';
import 'client_task_screen.dart';
import 'client_notification_screen.dart';
import 'client_profile_screen.dart';
// ⬇ Use your existing staff chat — just reuse it
import '../../staff/chat/chat_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ClientHome  ←  entry point for role == "client"
// Route it the same way you route staff to StaffHome
// In your auth router: if (role == 'client') → ClientHome()
// ─────────────────────────────────────────────────────────────────────────────

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});
  @override
  State<ClientHome> createState() => ClientHomeState();
}

class ClientHomeState extends State<ClientHome> {
  int _tab = 0;
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  void goTo(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        ClientDashboard(
          uid: _uid,
          onTabChange: goTo,
          department: 'client',
        ),
        ClientInvoiceScreen(clientId: _uid),
        ClientTaskScreen(clientId: _uid),
        ChatListScreen(),
        ClientProfileSimple(
            uid: _uid), // ← your existing staff chat (works for clients too)
      ]),
      bottomNavigationBar: _BottomNav(current: _tab, uid: _uid, onTap: goTo),
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  final String uid;
  final void Function(int) onTap;
  const _BottomNav(
      {required this.current, required this.uid, required this.onTap});

  static const _teal = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (_, snap) {
        final notifCount = snap.data?.docs.length ?? 0;

        // Unread messages count
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('messages')
              .where('receiverId', isEqualTo: uid)
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (_, msgSnap) {
            final msgCount = msgSnap.data?.docs.length ?? 0;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.09),
                    blurRadius: 24,
                    offset: const Offset(0, -3),
                  )
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Row(children: [
                    _NavBtn(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        idx: 0,
                        cur: current,
                        onTap: onTap),
                    _NavBtn(
                        icon: Icons.receipt_long_rounded,
                        label: 'Invoices',
                        idx: 1,
                        cur: current,
                        onTap: onTap),
                    _NavBtn(
                        icon: Icons.task_alt_rounded,
                        label: 'Tasks',
                        idx: 2,
                        cur: current,
                        onTap: onTap),
                    _NavBtn(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chat',
                        idx: 3,
                        cur: current,
                        onTap: onTap,
                        badge: msgCount),
                    _NavBtn(
                        icon: Icons.person,
                        label: 'Profile',
                        idx: 4,
                        cur: current,
                        onTap: onTap),
                  ]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final int idx, cur, badge;
  final void Function(int) onTap;
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.idx,
    required this.cur,
    required this.onTap,
    this.badge = 0,
  });

  static const _teal = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    final sel = idx == cur;
    return Expanded(
        child: GestureDetector(
      onTap: () => onTap(idx),
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(clipBehavior: Clip.none, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? _teal.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 22, color: sel ? _teal : Colors.black38),
          ),
          if (badge > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                    color: Color(0xFFE53935), shape: BoxShape.circle),
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
            ),
        ]),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: sel ? _teal : Colors.black38,
            )),
      ]),
    ));
  }
}
