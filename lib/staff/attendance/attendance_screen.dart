import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'qr_scan_screen.dart';
import 'attendance_service.dart';
import 'attendance_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with TickerProviderStateMixin {
  final AttendanceService _service = AttendanceService();
  bool _isProcessing = false;
  bool _isGridView = false;
  DateTime _selectedMonth = DateTime.now();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('dd - MM - yyyy').format(DateTime.now()),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Modern toggle view button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  _isGridView
                      ? Icons.view_agenda_rounded
                      : Icons.calendar_view_month_rounded,
                  key: ValueKey(_isGridView),
                  size: 26,
                ),
              ),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: _service.getAttendanceHistory(days: 90),
        builder: (context, snapshot) {
          final allRecords = snapshot.data ?? [];
          final monthRecords = _filterByMonth(allRecords, _selectedMonth);
          final stats = _calculateStatistics(monthRecords, _selectedMonth);

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Statistics Cards
                _buildStatisticsCards(stats),

                // Month Selector
                _buildMonthSelector(),

                // Content (List or Grid View)
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _isGridView
                        ? _buildGridView(monthRecords, stats)
                        : _buildListView(monthRecords),
                  ),
                ),

                // Punch In/Out Button
                _buildPunchButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  // Statistics Cards
  Widget _buildStatisticsCards(AttendanceStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatCard('${stats.total}', 'TOTAL', const Color(0xFF5C6BC0),
              const Color(0xFFE8EAF6)),
          const SizedBox(width: 12),
          _buildStatCard('${stats.present}', 'Present', const Color(0xFF66BB6A),
              const Color(0xFFE8F5E9)),
          const SizedBox(width: 12),
          _buildStatCard('${stats.absent}', 'Absent', const Color(0xFFEF5350),
              const Color(0xFFFFEBEE)),
          const SizedBox(width: 12),
          _buildStatCard('${stats.late}', 'Late', const Color(0xFFFFA726),
              const Color(0xFFFFF3E0)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Month Selector
  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chevron_left, size: 20),
                ),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chevron_right, size: 20),
                ),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // List View
  Widget _buildListView(List<AttendanceModel> records) {
    final daysInMonth = _getAllDaysInMonth(_selectedMonth);
    final today = DateTime.now();

    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: daysInMonth.length,
      itemBuilder: (context, index) {
        final day = daysInMonth[index];
        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        final isFutureDate =
            day.isAfter(DateTime(today.year, today.month, today.day));

        final record = records.firstWhere(
          (r) => r.date == dateStr,
          orElse: () => AttendanceModel(
            uid: '',
            date: dateStr,
            duration: 0,
            status: 'leave',
          ),
        );

        return _buildListItem(day, record, isFutureDate);
      },
    );
  }

  Widget _buildListItem(
      DateTime day, AttendanceModel record, bool isFutureDate) {
    Color statusColor;
    String statusText;
    Color bgColor;
    Color textColor;

    if (isFutureDate) {
      // Future dates - black/grey
      statusColor = Colors.grey.shade800;
      statusText = '-';
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade400;
    } else if (record.status == 'leave') {
      statusColor = const Color(0xFFEF5350);
      statusText = 'Leave';
      bgColor = const Color(0xFFFFEBEE);
      textColor = Colors.black87;
    } else if (record.status == 'late') {
      // Late status - show even after punch out
      statusColor = const Color(0xFFFFA726);
      statusText = 'Late';
      bgColor = const Color(0xFFFFF3E0);
      textColor = Colors.black87;
    } else if (record.status == 'working') {
      // Still working (no punch out)
      statusColor = const Color(0xFF42A5F5);
      statusText = 'Working';
      bgColor = const Color(0xFFE3F2FD);
      textColor = Colors.black87;
    } else if (record.status == 'on_time') {
      // On time and punched out
      statusColor = const Color(0xFF66BB6A);
      statusText = 'Present';
      bgColor = const Color(0xFFE8F5E9);
      textColor = Colors.black87;
    } else {
      // Default
      statusColor = const Color(0xFF66BB6A);
      statusText = 'Present';
      bgColor = const Color(0xFFE8F5E9);
      textColor = Colors.black87;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(day),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isFutureDate
                        ? Colors.grey.shade400
                        : const Color(0xFF5C6BC0),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM').format(day),
                  style: TextStyle(
                    fontSize: 12,
                    color: isFutureDate
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Time Range
          Expanded(
            child: Text(
              isFutureDate
                  ? '-'
                  : record.status == 'leave'
                      ? '-'
                      : '${_service.formatTime(record.punchIn)} - ${_service.formatTime(record.punchOut)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Status Indicator Bar
          Container(
            width: 4,
            height: 45,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // Grid View (Calendar)
  Widget _buildGridView(List<AttendanceModel> records, AttendanceStats stats) {
    final daysInMonth = _getAllDaysInMonth(_selectedMonth);
    final firstDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final today = DateTime.now();

    return SingleChildScrollView(
      key: const ValueKey('grid'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Weekday headers
            Row(
              children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            // Calendar days
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: firstWeekday + daysInMonth.length,
              itemBuilder: (context, index) {
                if (index < firstWeekday) {
                  return const SizedBox();
                }

                final dayIndex = index - firstWeekday;
                final day = daysInMonth[dayIndex];
                final dateStr = DateFormat('yyyy-MM-dd').format(day);
                final isFutureDate =
                    day.isAfter(DateTime(today.year, today.month, today.day));

                final record = records.firstWhere(
                  (r) => r.date == dateStr,
                  orElse: () => AttendanceModel(
                    uid: '',
                    date: dateStr,
                    duration: 0,
                    status: 'leave',
                  ),
                );

                return TweenAnimationBuilder(
                  duration: Duration(milliseconds: 300 + (dayIndex * 20)),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: _buildCalendarDay(day, record, isFutureDate),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDay(
      DateTime day, AttendanceModel record, bool isFutureDate) {
    final isToday = DateFormat('yyyy-MM-dd').format(day) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    Color bgColor;
    Color textColor;
    Color? borderColor;

    if (isFutureDate) {
      // Future dates - dark grey/black
      bgColor = Colors.grey.shade900;
      textColor = Colors.white70;
      borderColor = null;
    } else if (record.status == 'leave') {
      bgColor = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFEF5350);
      borderColor = isToday ? const Color(0xFFEF5350) : null;
    } else if (record.status == 'late') {
      bgColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFFFA726);
      borderColor = isToday ? const Color(0xFFFFA726) : null;
    } else if (record.status == 'working') {
      // Still working - blue color
      bgColor = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF42A5F5);
      borderColor = isToday ? const Color(0xFF42A5F5) : null;
    } else if (record.status == 'on_time') {
      // On time and completed
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF66BB6A);
      borderColor = isToday ? const Color(0xFF66BB6A) : null;
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      borderColor = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2.5)
            : null,
      ),
      child: Center(
        child: Text(
          DateFormat('dd').format(day),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  // Punch In/Out Button
  Widget _buildPunchButton() {
    return StreamBuilder<AttendanceModel?>(
      stream: _service.watchTodayAttendance(),
      builder: (context, snapshot) {
        final attendance = snapshot.data;
        final hasPunchedIn = attendance?.punchIn != null;
        final hasPunchedOut = attendance?.punchOut != null;

        return Container(
          padding: const EdgeInsets.fromLTRB(
              24, 12, 16, 12), // Left padding increased
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7C8BE8),
                const Color(0xFF5C6BC0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5C6BC0).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Punch In
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Punch In',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPunchedIn
                          ? _service.formatTime(attendance?.punchIn)
                          : '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                    width: 32), // Reduced gap between Punch In and Punch Out
                // Punch Out
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Punch Out',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPunchedOut
                          ? _service.formatTime(attendance?.punchOut)
                          : '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const Spacer(), // Push button to the right
                // Punch Button
                Container(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: hasPunchedOut
                        ? null
                        : (_isProcessing ? null : _handleQRScan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: hasPunchedOut
                          ? Colors.grey.shade600
                          : hasPunchedIn
                              ? const Color(0xFFEF5350)
                              : const Color(0xFF66BB6A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hasPunchedOut
                                    ? 'Done'
                                    : hasPunchedIn
                                        ? 'Punch Out'
                                        : 'Punch In',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // QR Scan Handler
  Future<void> _handleQRScan() async {
    if (_isProcessing) return;

    final todayAttendance = await _service.getTodayAttendance();
    if (todayAttendance?.punchOut != null) {
      _showSnackBar('Already completed for today', Colors.orange);
      return;
    }

    final scannedValue = await Navigator.push<String>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const QRScanScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    if (scannedValue == null) return;

    if (!_service.isValidQRCode(scannedValue)) {
      _showSnackBar('Invalid QR Code', Colors.red);
      return;
    }

    await _processAttendance(todayAttendance);
  }

  Future<void> _processAttendance(AttendanceModel? todayAttendance) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Verify location (20 meters from office)
      _showSnackBar('Verifying location...', Colors.blue);

      final isWithinOffice = await _service.verifyLocationWithinOffice();

      if (!isWithinOffice) {
        _showSnackBar(
          'You must be within 20 meters of office location to mark attendance',
          const Color(0xFFEF5350),
        );
        return;
      }

      // Step 2: Process attendance
      final hasPunchedIn = todayAttendance?.punchIn != null;

      if (!hasPunchedIn) {
        await _service.punchIn();
        _showSnackBar('Punched In Successfully! ✓', const Color(0xFF66BB6A));
      } else {
        await _service.punchOut();
        _showSnackBar('Punched Out Successfully! ✓', const Color(0xFF66BB6A));
      }
    } on Exception catch (e) {
      // Handle specific location errors
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showSnackBar(errorMessage, const Color(0xFFEF5350));
    } catch (e) {
      _showSnackBar('Error: $e', const Color(0xFFEF5350));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Helper methods
  List<DateTime> _getAllDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return List.generate(
      lastDay.day,
      (index) => DateTime(month.year, month.month, index + 1),
    );
  }

  List<AttendanceModel> _filterByMonth(
      List<AttendanceModel> records, DateTime month) {
    final monthStr = DateFormat('yyyy-MM').format(month);
    return records.where((r) => r.date.startsWith(monthStr)).toList();
  }

  AttendanceStats _calculateStatistics(
      List<AttendanceModel> monthRecords, DateTime month) {
    // Get actual days in the month
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;

    // Total = All days in month (28-31 depending on month)
    final total = daysInMonth;

    // For current month, only count days up to today for absent calculation
    final daysToCount = isCurrentMonth ? now.day : daysInMonth;

    int present = 0;
    int late = 0;

    for (var record in monthRecords) {
      if (record.status == 'late') {
        late++;
        // Late does NOT count as present
      } else if (record.status != 'leave') {
        // Only on_time, working, overtime count as present
        present++;
      }
    }

    // Absent = days till today - (present + late)
    // This excludes future dates from absent count
    final absent = daysToCount - present - late;

    return AttendanceStats(
      total: total,
      present: present,
      absent: absent > 0 ? absent : 0,
      late: late,
    );
  }
}

// Statistics Model
class AttendanceStats {
  final int total;
  final int present;
  final int absent;
  final int late;

  AttendanceStats({
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
  });
}
