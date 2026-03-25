import 'package:flutter/material.dart';

class AppColors {
  // Base
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFF3F4F6);

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);

  // Brand
  static const primary = Color(0xFF3B82F6);
  static const primaryLight = Color(0xFFDEEAFF);
  static const primaryDark = Color(0xFF1E40AF);

  // Status
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const info = Color(0xFF6366F1);
  static const infoLight = Color(0xFFE0E7FF);

  // Lead Status
  static const statusNew = Color(0xFF8B5CF6);
  static const statusNewLight = Color(0xFFEDE9FE);
  static const statusContacted = Color(0xFF3B82F6);
  static const statusContactedLight = Color(0xFFDBEAFE);
  static const statusInterested = Color(0xFF06B6D4);
  static const statusInterestedLight = Color(0xFFCFFAFE);
  static const statusProposal = Color(0xFFF59E0B);
  static const statusProposalLight = Color(0xFFFEF3C7);
  static const statusConverted = Color(0xFF10B981);
  static const statusConvertedLight = Color(0xFFD1FAE5);
  static const statusLost = Color(0xFF6B7280);
  static const statusLostLight = Color(0xFFF3F4F6);

  // Priority
  static const priorityHot = Color(0xFFEF4444);
  static const priorityHotLight = Color(0xFFFEE2E2);
  static const priorityWarm = Color(0xFFF59E0B);
  static const priorityWarmLight = Color(0xFFFEF3C7);
  static const priorityCold = Color(0xFF3B82F6);
  static const priorityColdLight = Color(0xFFDBEAFE);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
