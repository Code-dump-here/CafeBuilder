import 'package:flutter/material.dart';

import '../models/responses/api_responses.dart';
import '../pages/project_detail_page.dart';
import '../services/apply_service.dart';
import '../services/project_working_service.dart';

/// Shared notification formatting and deep-link resolution.
///
/// Three screens show notifications — the bell sheet, the full inbox, and the
/// detail screen — and all three need the same relative time, the same type
/// label, and the same answer to "where does this one lead?". Keeping that in
/// one place stops the three drifting apart as new notification types land.

/// Compact relative time for a list row — "now", "5m", "3h", "2d", then a short
/// date once it's over a week old.
String notificationRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}/${dt.month}/${dt.year}';
}

/// Exact timestamp for the detail screen, where there is room to spell it out.
String notificationFullTime(DateTime dt) {
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} at ${two(local.hour)}:${two(local.minute)}';
}

/// Human label for `Notification.type`, which arrives as a snake_case tag such
/// as `engagement_completion_requested`.
///
/// Deliberately generic rather than a lookup table: the backend adds types as
/// new flows land, and a table would render those as a blank chip until someone
/// remembered to extend it here.
String notificationTypeLabel(String type) {
  if (type.isEmpty) return 'Notification';
  final words = type.replaceAll('_', ' ').trim();
  if (words.isEmpty) return 'Notification';
  return words[0].toUpperCase() + words.substring(1);
}

/// True when a notification points at something this app can open.
///
/// `referenceId` deserialises to an empty string rather than null when the
/// backend omits it, so an emptiness check is what actually distinguishes
/// "no target" here — a null check alone never fires.
bool notificationHasReference(NotificationResponse noti) {
  final type = noti.referenceType;
  final id = noti.referenceId;
  if (type == null || type.isEmpty) return false;
  if (id == null || id.isEmpty) return false;
  return type == 'project' ||
      type == 'project_provider' ||
      type == 'project_application';
}

/// Resolves a notification's (referenceType, referenceId) to a project and
/// opens it.
///
/// Only `project` carries a project id directly; `project_provider` and
/// `project_application` reference an engagement or an apply row, so those need
/// one extra lookup to find the project they belong to. Unknown or missing
/// reference data no-ops rather than guessing.
///
/// Returns true when a screen was actually pushed, so callers can tell the
/// difference between "opened it" and "nothing to open".
Future<bool> openNotificationReference(
  BuildContext context,
  NotificationResponse noti,
) async {
  if (!notificationHasReference(noti)) return false;
  final type = noti.referenceType!;
  final id = noti.referenceId!;

  try {
    String? projectId;
    switch (type) {
      case 'project':
        projectId = id;
        break;
      case 'project_provider':
        final working = await ProjectWorkingService.getProjectWorking(id);
        projectId = working.projectShopOwnerId;
        break;
      case 'project_application':
        final apply = await ApplyService.getApply(id);
        projectId = apply.projectShopOwnerId;
        break;
    }
    if (projectId == null || projectId.isEmpty) return false;
    if (!context.mounted) return false;

    final target = projectId;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailPage(projectId: target),
      ),
    );
    return true;
  } catch (_) {
    // The referenced project/engagement/apply may have been deleted since the
    // notification was created — fail quietly rather than erroring out of the
    // screen the user is on.
    return false;
  }
}
