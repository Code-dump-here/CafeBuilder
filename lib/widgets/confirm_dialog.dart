import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Generic yes/no confirmation dialog. Returns true only if the user tapped
/// the confirm button — dismissing the dialog any other way (back button,
/// tapping outside) returns false.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.espresso),
          child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Confirmation that also collects the *reason* for the decision.
///
/// Returns null when the user backs out, and the trimmed text otherwise — an
/// empty string is a valid answer when [requireText] is false.
///
/// Set [requireText] for endpoints that refuse a blank reason (quotation
/// `request-revision` answers 400 without one): the confirm button stays
/// disabled until something is typed, so the rejection never reaches the user
/// as a server error they can't act on.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String hint,
  String confirmLabel = 'Submit',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  bool requireText = false,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          // Rebuilds so the confirm button can enable itself as soon as the
          // box stops being empty.
          onChanged: (_) => setLocal(() {}),
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  destructive ? Colors.red.shade700 : AppColors.espresso,
            ),
            onPressed: requireText && controller.text.trim().isEmpty
                ? null
                : () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(confirmLabel,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result;
}
