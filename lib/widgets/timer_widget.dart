// TIMER WIDGET
// File: lib/modules/task_management/widgets/timer_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/task_helpers.dart';

class TimerWidget extends StatefulWidget {
  final DateTime? startTime;
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const TimerWidget({
    Key? key,
    this.startTime,
    required this.isRunning,
    required this.onStart,
    required this.onStop,
  }) : super(key: key);

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning ||
        widget.startTime != oldWidget.startTime) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();

    if (widget.isRunning && widget.startTime != null) {
      _updateElapsed();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateElapsed();
      });
    }
  }

  void _updateElapsed() {
    if (widget.startTime != null) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.startTime!);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: widget.isRunning
            ? LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.isRunning
                ? Colors.blue.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Timer Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isRunning ? Icons.timer : Icons.timer_off,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                widget.isRunning ? _formatDuration(_elapsed) : '00:00:00',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Control Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isRunning ? widget.onStop : widget.onStart,
              icon: Icon(
                widget.isRunning ? Icons.stop : Icons.play_arrow,
                size: 24,
              ),
              label: Text(
                widget.isRunning ? 'Stop Work' : 'Start Work',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: widget.isRunning
                    ? Colors.blue.shade700
                    : Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),

          // Info Text
          if (widget.isRunning && widget.startTime != null) ...[
            const SizedBox(height: 12),
            Text(
              'Started ${TaskHelpers.getTimeAgo(widget.startTime!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
