// STEP 2.1: TASK CONSTANTS
// File: lib/modules/task_management/utils/task_constants.dart

import 'package:flutter/material.dart';

// ==================== TASK STATUS ====================
class TaskStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String review = 'review';
  static const String completed = 'completed';
  static const String rejected = 'rejected';

  static List<String> get all =>
      [pending, inProgress, review, completed, rejected];

  static String getLabel(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case inProgress:
        return 'In Progress';
      case review:
        return 'In Review';
      case completed:
        return 'Completed';
      case rejected:
        return 'Rejected';
      default:
        return status;
    }
  }

  static Color getColor(String status) {
    switch (status) {
      case pending:
        return Colors.orange;
      case inProgress:
        return Colors.blue;
      case review:
        return Colors.purple;
      case completed:
        return Colors.green;
      case rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData getIcon(String status) {
    switch (status) {
      case pending:
        return Icons.pending_outlined;
      case inProgress:
        return Icons.work_outline;
      case review:
        return Icons.rate_review_outlined;
      case completed:
        return Icons.check_circle_outline;
      case rejected:
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

// ==================== TASK PRIORITY ====================
class TaskPriority {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String urgent = 'urgent';

  static List<String> get all => [low, medium, high, urgent];

  static String getLabel(String priority) {
    switch (priority) {
      case low:
        return 'Low';
      case medium:
        return 'Medium';
      case high:
        return 'High';
      case urgent:
        return 'Urgent';
      default:
        return priority;
    }
  }

  static Color getColor(String priority) {
    switch (priority) {
      case low:
        return Colors.green;
      case medium:
        return Colors.blue;
      case high:
        return Colors.orange;
      case urgent:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData getIcon(String priority) {
    switch (priority) {
      case low:
        return Icons.arrow_downward;
      case medium:
        return Icons.drag_handle;
      case high:
        return Icons.arrow_upward;
      case urgent:
        return Icons.priority_high;
      default:
        return Icons.circle;
    }
  }

  static int getPriorityWeight(String priority) {
    switch (priority) {
      case urgent:
        return 4;
      case high:
        return 3;
      case medium:
        return 2;
      case low:
        return 1;
      default:
        return 0;
    }
  }
}

// ==================== PROJECT STATUS ====================
class ProjectStatus {
  static const String active = 'active';
  static const String completed = 'completed';
  static const String onHold = 'on_hold';
  static const String cancelled = 'cancelled';

  static List<String> get all => [active, completed, onHold, cancelled];

  static String getLabel(String status) {
    switch (status) {
      case active:
        return 'Active';
      case completed:
        return 'Completed';
      case onHold:
        return 'On Hold';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Color getColor(String status) {
    switch (status) {
      case active:
        return Colors.green;
      case completed:
        return Colors.blue;
      case onHold:
        return Colors.orange;
      case cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ==================== DESIGN TYPES ====================
class DesignType {
  static const String logo = 'logo';
  static const String banner = 'banner';
  static const String illustration = 'illustration';
  static const String uiUx = 'ui_ux';
  static const String socialMedia = 'social_media';
  static const String branding = 'branding';
  static const String infographic = 'infographic';
  static const String packaging = 'packaging';
  static const String other = 'other';

  static List<String> get all => [
        logo,
        banner,
        illustration,
        uiUx,
        socialMedia,
        branding,
        infographic,
        packaging,
        other
      ];

  static String getLabel(String type) {
    switch (type) {
      case logo:
        return 'Logo Design';
      case banner:
        return 'Banner Design';
      case illustration:
        return 'Illustration';
      case uiUx:
        return 'UI/UX Design';
      case socialMedia:
        return 'Social Media';
      case branding:
        return 'Branding';
      case infographic:
        return 'Infographic';
      case packaging:
        return 'Packaging';
      case other:
        return 'Other';
      default:
        return type;
    }
  }

  static IconData getIcon(String type) {
    switch (type) {
      case logo:
        return Icons.brush;
      case banner:
        return Icons.panorama;
      case illustration:
        return Icons.color_lens;
      case uiUx:
        return Icons.dashboard_customize;
      case socialMedia:
        return Icons.share;
      case branding:
        return Icons.local_offer;
      case infographic:
        return Icons.bar_chart;
      case packaging:
        return Icons.inventory_2;
      default:
        return Icons.design_services;
    }
  }
}

// ==================== FILE TYPES ====================
class FileType {
  static const String image = 'image';
  static const String pdf = 'pdf';
  static const String zip = 'zip';
  static const String other = 'other';

  static String getFileType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
      case '.svg':
        return image;
      case '.pdf':
        return pdf;
      case '.zip':
      case '.rar':
      case '.7z':
        return zip;
      default:
        return other;
    }
  }

  static IconData getIcon(String type) {
    switch (type) {
      case image:
        return Icons.image;
      case pdf:
        return Icons.picture_as_pdf;
      case zip:
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  static Color getColor(String type) {
    switch (type) {
      case image:
        return Colors.blue;
      case pdf:
        return Colors.red;
      case zip:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// ==================== TASK ACTIONS ====================
class TaskAction {
  static const String created = 'created';
  static const String assigned = 'assigned';
  static const String statusChanged = 'status_changed';
  static const String priorityChanged = 'priority_changed';
  static const String startedWork = 'started_work';
  static const String stoppedWork = 'stopped_work';
  static const String submitted = 'submitted';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String fileUploaded = 'file_uploaded';
  static const String commentAdded = 'comment_added';
}

// ==================== THEME COLORS ====================
class TaskColors {
  // Primary gradient
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Success gradient
  static const successGradient = LinearGradient(
    colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warning gradient
  static const warningGradient = LinearGradient(
    colors: [Color(0xFFf12711), Color(0xFFf5af19)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Info gradient
  static const infoGradient = LinearGradient(
    colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Danger gradient
  static const dangerGradient = LinearGradient(
    colors: [Color(0xFFEB3349), Color(0xFFF45C43)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ==================== CHIP SIZE ====================
enum ChipSize { small, medium, large }
