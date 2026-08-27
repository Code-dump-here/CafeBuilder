import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// How one `QuotationStatus` should read and look to the owner.
///
/// The server sends its enum names verbatim (`revision_requested`), which are
/// not meant to be shown as-is, and the same six values are rendered on both
/// the comparison list and the single-bid screen. Keeping the mapping here
/// stops the two from drifting apart — they used to disagree on both the
/// wording and the colour of every state.
class QuotationStatusStyle {
  final String label;
  final Color background;
  final Color foreground;

  const QuotationStatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });
}

/// Labels are written from the owner's side: `sent` is the provider's word for
/// it, but what it means to the owner is that the ball is in their court.
QuotationStatusStyle quotationStatusStyle(String status) {
  switch (status.toLowerCase()) {
    case 'draft':
      return QuotationStatusStyle(
        label: 'Draft',
        background: AppColors.background,
        foreground: Colors.black54,
      );
    case 'sent':
      return QuotationStatusStyle(
        label: 'Awaiting your decision',
        background: Colors.amber.shade50,
        foreground: Colors.amber.shade900,
      );
    case 'revision_requested':
      return QuotationStatusStyle(
        label: 'Revision requested',
        background: Colors.orange.shade50,
        foreground: Colors.orange.shade900,
      );
    case 'accepted':
      return QuotationStatusStyle(
        label: 'Accepted',
        background: Colors.green.shade50,
        foreground: Colors.green.shade800,
      );
    case 'rejected':
      return QuotationStatusStyle(
        label: 'Rejected',
        background: Colors.red.shade50,
        foreground: Colors.red.shade700,
      );
    case 'superseded':
      return QuotationStatusStyle(
        label: 'Superseded',
        background: Colors.red.shade50,
        foreground: Colors.red.shade700,
      );
    default:
      // An unknown state is shown rather than hidden: a new server enum value
      // should be visible in the UI, not silently rendered as "Draft".
      return QuotationStatusStyle(
        label: status,
        background: AppColors.background,
        foreground: Colors.black54,
      );
  }
}
