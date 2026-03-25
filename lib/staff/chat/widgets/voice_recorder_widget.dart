import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '/../services/voice_recorder_service.dart';

/// Voice recorder widget for recording audio messages
class VoiceRecorderWidget extends StatefulWidget {
  final Function(File) onRecordingComplete;
  final VoidCallback? onCancel;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.onCancel,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();
  Timer? _recordingTimer;
  Duration _recordDuration = Duration.zero;
  bool isRecording = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _startRecording();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _voiceRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final started = await _voiceRecorder.startRecording();

    if (started) {
      setState(() {
        isRecording = true;
      });

      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration = Duration(seconds: timer.tick);
          _voiceRecorder.updateRecordDuration(_recordDuration);
        });

        // Auto-stop at 5 minutes
        if (_recordDuration.inMinutes >= 5) {
          _stopRecording();
        }
      });
    } else {
      // Permission denied or error
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Microphone permission is required for voice messages'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();

    final path = await _voiceRecorder.stopRecording();

    if (path != null && mounted) {
      final file = File(path);
      Navigator.pop(context);
      widget.onRecordingComplete(file);
    } else if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save recording'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _voiceRecorder.cancelRecording();

    if (mounted) {
      Navigator.pop(context);
      widget.onCancel?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          _buildRecordingIndicator(),

          const SizedBox(height: 24),

          // Timer
          _buildTimer(),

          const SizedBox(height: 16),

          // Waveform animation
          _buildWaveform(),

          const SizedBox(height: 32),

          // Controls
          _buildControls(),

          const SizedBox(height: 16),

          // Instructions
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.1 + (_pulseController.value * 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.red
                    .withOpacity(0.3 + (_pulseController.value * 0.3)),
                blurRadius: 20 + (_pulseController.value * 10),
                spreadRadius: 5 + (_pulseController.value * 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.mic,
            size: 40,
            color: Colors.red,
          ),
        );
      },
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Text(
          _voiceRecorder.formatDuration(_recordDuration),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Recording...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (index) {
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final delay = index * 0.05;
              final value = (_pulseController.value + delay) % 1.0;
              final height = 10 + (value * 40);

              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Cancel button
        FloatingActionButton(
          heroTag: 'cancel_voice',
          backgroundColor: Colors.grey[300],
          onPressed: _cancelRecording,
          child: const Icon(
            Icons.close,
            color: Colors.black87,
            size: 28,
          ),
        ),

        // Delete button
        FloatingActionButton(
          heroTag: 'delete_voice',
          backgroundColor: Colors.red[100],
          onPressed: _cancelRecording,
          child: Icon(
            Icons.delete,
            color: Colors.red[700],
            size: 28,
          ),
        ),

        // Send button
        FloatingActionButton(
          heroTag: 'send_voice',
          backgroundColor: Theme.of(context).colorScheme.primary,
          onPressed: _recordDuration.inSeconds >= 1 ? _stopRecording : null,
          child: const Icon(
            Icons.send,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        Text(
          _recordDuration.inSeconds < 1 ? 'Speak now...' : 'Tap send when done',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Max duration: 5 minutes',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
