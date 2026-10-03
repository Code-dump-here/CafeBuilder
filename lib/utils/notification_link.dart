import 'package:flutter/material.dart';

import '../models/responses/api_responses.dart';
import '../pages/project_detail_page.dart';
import '../pages/quotation_details_page.dart';
import '../services/apply_service.dart';
import '../services/construction_service.dart';
import '../services/contract_service.dart';
import '../services/payment_batch_service.dart';
import '../services/post_service.dart';
import '../services/project_working_service.dart';
import '../services/quotation_service.dart';

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
  return _openableTypes.contains(type);
}

/// Every `referenceType` the backend writes (`NotificationService`, named after
/// the table). Before 03/10/2026 only the first three opened anything, so a
/// "New quotation" notification led nowhere.
const _openableTypes = {
  'project',
  'project_provider',
  'project_application',
  'quotation',
  'contract',
  'payment_batch',
  'construction_item',
};

/// Resolves a notification's (referenceType, referenceId) to a screen and
/// opens it.
///
/// A quotation opens on its own page, where the owner can approve it — that is
/// what the notification asks of them. Everything else opens the project it
/// belongs to: only `project` carries a project id directly, the rest need one
/// or two lookups (row → engagement → project). Unknown or missing reference
/// data no-ops rather than guessing.
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
    if (type == 'quotation') return await _openQuotation(context, id);

    Future<String> projectOfEngagement(String workingId) async =>
        (await ProjectWorkingService.getProjectWorking(workingId)).projectShopOwnerId;

    String? projectId;
    switch (type) {
      case 'project':
        projectId = id;
        break;
      case 'project_provider':
        projectId = await projectOfEngagement(id);
        break;
      case 'project_application':
        final apply = await ApplyService.getApply(id);
        projectId = apply.projectShopOwnerId;
        break;
      case 'contract':
        final contract = await ContractService.getContract(id);
        projectId = await projectOfEngagement(contract.projectWorkingId);
        break;
      case 'payment_batch':
        final batch = await PaymentBatchService.getById(id);
        final contract = await ContractService.getContract(batch.contractId);
        projectId = await projectOfEngagement(contract.projectWorkingId);
        break;
      case 'construction_item':
        final item = await ConstructionService.getMilestone(id);
        projectId = await projectOfEngagement(item.projectWorkingId);
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

/// Opens a quotation on its own page — approve, reject or ask for a revision
/// right from the notification.
///
/// The page needs the scope of the work to label the document and decide
/// whether design revision terms belong on it, and the quotation does not carry
/// it: an engagement states it as `contractType`, a bid inherits the post's
/// `serviceKind`. A failed scope lookup still opens the page, unlabelled.
Future<bool> _openQuotation(BuildContext context, String id) async {
  final quotation = await QuotationService.getQuotation(id);

  String? scope;
  try {
    final workingId = quotation.projectWorkingId;
    final applyId = quotation.applyId;
    if (workingId != null && workingId.isNotEmpty) {
      scope = (await ProjectWorkingService.getProjectWorking(workingId)).contractType;
    } else if (applyId != null && applyId.isNotEmpty) {
      final apply = await ApplyService.getApply(applyId);
      scope = (await PostService.getPost(apply.postId)).serviceKind;
    }
  } catch (_) {}

  if (!context.mounted) return false;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => QuotationDetailsPage(
        quotationId: quotation.id,
        initialQuotation: quotation,
        scope: scope,
      ),
    ),
  );
  return true;
}
