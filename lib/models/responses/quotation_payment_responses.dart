/// Response models for the three review-3 flows the owner app was missing:
/// quotations, instalment payments and the daily construction log.
///
/// Kept in their own file for the same reason as `review3_responses.dart` —
/// `api_responses.dart` is already very large. Parsing style matches both.
library;

DateTime _parseDate(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

DateTime? _parseNullableDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

/// Money arrives as a JSON number, but a `decimal` serialised by .NET can also
/// come through as a string depending on the converter in play. Parsing both
/// avoids a crash that would only ever show up in production data.
double _parseAmount(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

double? _parseNullableAmount(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

// ── Quotation ────────────────────────────────────────────────────────────────

/// One priced line of a quotation. `amount` is computed server-side from
/// quantity × unitPrice, so the owner's total always matches its lines.
class QuotationItemResponse {
  final String id;
  final String name;
  final String? description;
  final String? unit;
  final double quantity;
  final double unitPrice;
  final double amount;
  final String? note;
  final int sortOrder;

  QuotationItemResponse({
    required this.id,
    required this.name,
    this.description,
    this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    this.note,
    required this.sortOrder,
  });

  factory QuotationItemResponse.fromJson(Map<String, dynamic> json) =>
      QuotationItemResponse(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        unit: json['unit']?.toString(),
        quantity: _parseAmount(json['quantity']),
        unitPrice: _parseAmount(json['unitPrice']),
        amount: _parseAmount(json['amount']),
        note: json['note']?.toString(),
        sortOrder: json['sortOrder'] ?? 0,
      );
}

/// One instalment of the payment schedule. These exact rows become the
/// project's payment batches when the contract is signed, so what the owner
/// approves here is what they will be asked to pay against.
class QuotationPaymentTermResponse {
  final String id;
  final int sortOrder;
  final String name;
  final double? percentage;
  final double amount;
  final String? condition;

  QuotationPaymentTermResponse({
    required this.id,
    required this.sortOrder,
    required this.name,
    this.percentage,
    required this.amount,
    this.condition,
  });

  factory QuotationPaymentTermResponse.fromJson(Map<String, dynamic> json) =>
      QuotationPaymentTermResponse(
        id: json['id']?.toString() ?? '',
        sortOrder: json['sortOrder'] ?? 0,
        name: json['name']?.toString() ?? '',
        percentage: _parseNullableAmount(json['percentage']),
        amount: _parseAmount(json['amount']),
        condition: json['condition']?.toString(),
      );
}

class QuotationAttachmentResponse {
  final String id;
  final String fileUrl;

  /// Absolute URL — this is the one to open. `fileUrl` is the storage key.
  final String? fileViewUrl;
  final String? fileName;
  final DateTime createdAt;

  QuotationAttachmentResponse({
    required this.id,
    required this.fileUrl,
    this.fileViewUrl,
    this.fileName,
    required this.createdAt,
  });

  factory QuotationAttachmentResponse.fromJson(Map<String, dynamic> json) =>
      QuotationAttachmentResponse(
        id: json['id']?.toString() ?? '',
        fileUrl: json['fileUrl']?.toString() ?? '',
        fileViewUrl: json['fileViewUrl']?.toString(),
        fileName: json['fileName']?.toString(),
        createdAt: _parseDate(json['createdAt']),
      );
}

/// A provider's priced bid.
///
/// This is what review 3 asked for: before it, an owner choosing between three
/// providers had one free-text line each and no basis to decide. Approving one
/// of these **is** how a provider is chosen — for a quotation attached to an
/// application, `POST /accept` also accepts that application, opens the
/// engagement and closes the post.
class QuotationResponse {
  final String id;
  final String? applyId;
  final String? projectWorkingId;
  final int version;
  final String title;
  final String? note;
  final double totalAmount;
  final int? estimatedDurationDays;
  final int? freeRevisionCount;
  final double? extraRevisionFee;

  /// `draft` | `sent` | `revision_requested` | `accepted` | `rejected` |
  /// `superseded`. Only `sent` is actionable by the owner.
  final String status;

  final String? revisionReason;
  final String? rejectReason;
  final DateTime? sentAt;
  final DateTime? respondedAt;
  final DateTime? lockedAt;
  final bool isLocked;

  /// Provider snapshot, included so several bids can be compared without a
  /// profile call per row.
  final String? providerName;
  final String? serviceProviderProfileId;
  final double? providerAvgRating;
  final int? providerYearsExperience;
  final bool? providerIsVerified;

  final List<QuotationItemResponse> items;
  final List<QuotationPaymentTermResponse> paymentTerms;
  final List<QuotationAttachmentResponse> attachments;

  final DateTime createdAt;
  final DateTime updatedAt;

  QuotationResponse({
    required this.id,
    this.applyId,
    this.projectWorkingId,
    required this.version,
    required this.title,
    this.note,
    required this.totalAmount,
    this.estimatedDurationDays,
    this.freeRevisionCount,
    this.extraRevisionFee,
    required this.status,
    this.revisionReason,
    this.rejectReason,
    this.sentAt,
    this.respondedAt,
    this.lockedAt,
    required this.isLocked,
    this.providerName,
    this.serviceProviderProfileId,
    this.providerAvgRating,
    this.providerYearsExperience,
    this.providerIsVerified,
    required this.items,
    required this.paymentTerms,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The owner can still act on it. `revision_requested` is excluded: the ball
  /// is with the provider until they send a new version.
  bool get isAwaitingOwner => status == 'sent';

  /// Nothing further will happen to this one — grey it out rather than hide
  /// it, so the owner can still see what they turned down.
  bool get isClosed =>
      status == 'accepted' || status == 'rejected' || status == 'superseded';

  factory QuotationResponse.fromJson(Map<String, dynamic> json) =>
      QuotationResponse(
        id: json['id']?.toString() ?? '',
        applyId: json['applyId']?.toString(),
        projectWorkingId: json['projectWorkingId']?.toString(),
        version: json['version'] ?? 1,
        title: json['title']?.toString() ?? '',
        note: json['note']?.toString(),
        totalAmount: _parseAmount(json['totalAmount']),
        estimatedDurationDays: json['estimatedDurationDays'],
        freeRevisionCount: json['freeRevisionCount'],
        extraRevisionFee: _parseNullableAmount(json['extraRevisionFee']),
        status: json['status']?.toString() ?? 'draft',
        revisionReason: json['revisionReason']?.toString(),
        rejectReason: json['rejectReason']?.toString(),
        sentAt: _parseNullableDate(json['sentAt']),
        respondedAt: _parseNullableDate(json['respondedAt']),
        lockedAt: _parseNullableDate(json['lockedAt']),
        isLocked: json['isLocked'] == true,
        providerName: json['providerName']?.toString(),
        serviceProviderProfileId: json['serviceProviderProfileId']?.toString(),
        providerAvgRating: _parseNullableAmount(json['providerAvgRating']),
        providerYearsExperience: json['providerYearsExperience'],
        providerIsVerified: json['providerIsVerified'] as bool?,
        items: ((json['items'] as List?) ?? const [])
            .map((e) => QuotationItemResponse.fromJson(e))
            .toList(),
        paymentTerms: ((json['paymentTerms'] as List?) ?? const [])
            .map((e) => QuotationPaymentTermResponse.fromJson(e))
            .toList(),
        attachments: ((json['attachments'] as List?) ?? const [])
            .map((e) => QuotationAttachmentResponse.fromJson(e))
            .toList(),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );
}

// ── Payment batch ────────────────────────────────────────────────────────────

/// One proof upload. Kept as a list rather than overwritten: an instalment can
/// be transferred in parts, and a proof the provider rejected still has to be
/// there to compare against.
class PaymentProofResponse {
  final String id;
  final String? imageUrl;
  final String? imageViewUrl;

  /// What this particular transfer covered. Null means the whole instalment —
  /// rendering it as 0 would be wrong.
  final double? amount;
  final DateTime? transferredAt;
  final String? note;
  final String? uploadedBy;
  final DateTime createdAt;

  PaymentProofResponse({
    required this.id,
    this.imageUrl,
    this.imageViewUrl,
    this.amount,
    this.transferredAt,
    this.note,
    this.uploadedBy,
    required this.createdAt,
  });

  factory PaymentProofResponse.fromJson(Map<String, dynamic> json) =>
      PaymentProofResponse(
        id: json['id']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString(),
        imageViewUrl: json['imageViewUrl']?.toString(),
        amount: _parseNullableAmount(json['amount']),
        transferredAt: _parseNullableDate(json['transferredAt']),
        note: json['note']?.toString(),
        uploadedBy: json['uploadedBy']?.toString(),
        createdAt: _parseDate(json['createdAt']),
      );
}

/// An instalment owed under a contract.
///
/// The platform holds no money: the owner transfers directly and uploads
/// proof, the provider reconciles it against their own account and confirms.
/// The status is therefore the state of an agreement between two people, not
/// of a bank transaction.
class PaymentBatchResponse {
  final String id;
  final String contractId;

  /// The milestone this instalment pays for. Confirming the batch flips that
  /// milestone's `isPaid` — the "paid, and paid for what" link of review 3.
  final String? constructionItemId;
  final String? constructionItemName;

  /// Set when the batch came from a change order rather than the original
  /// quotation, so it does not read as an instalment that appeared from
  /// nowhere.
  final String? changeOrderId;

  final int sortOrder;
  final String name;
  final double? percentage;
  final double amount;

  /// `yyyy-MM-dd` as sent by the server.
  final String? dueAt;

  /// `pending` | `proof_submitted` | `confirmed` | `rejected`.
  /// `rejected` is not terminal: fresh proof puts it back to `proof_submitted`.
  final String status;

  final DateTime? proofSubmittedAt;
  final DateTime? confirmedAt;
  final String? confirmedBy;
  final String? rejectReason;
  final String? note;

  /// Sum of the amounts declared on the proofs; proofs with no amount count 0.
  final double paidAmount;

  final List<PaymentProofResponse> proofs;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentBatchResponse({
    required this.id,
    required this.contractId,
    this.constructionItemId,
    this.constructionItemName,
    this.changeOrderId,
    required this.sortOrder,
    required this.name,
    this.percentage,
    required this.amount,
    this.dueAt,
    required this.status,
    this.proofSubmittedAt,
    this.confirmedAt,
    this.confirmedBy,
    this.rejectReason,
    this.note,
    required this.paidAmount,
    required this.proofs,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The owner still has something to do here — either nothing has been paid,
  /// or the provider bounced the last proof.
  bool get needsOwnerAction => status == 'pending' || status == 'rejected';

  factory PaymentBatchResponse.fromJson(Map<String, dynamic> json) =>
      PaymentBatchResponse(
        id: json['id']?.toString() ?? '',
        contractId: json['contractId']?.toString() ?? '',
        constructionItemId: json['constructionItemId']?.toString(),
        constructionItemName: json['constructionItemName']?.toString(),
        changeOrderId: json['changeOrderId']?.toString(),
        sortOrder: json['sortOrder'] ?? 0,
        name: json['name']?.toString() ?? '',
        percentage: _parseNullableAmount(json['percentage']),
        amount: _parseAmount(json['amount']),
        dueAt: json['dueAt']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        proofSubmittedAt: _parseNullableDate(json['proofSubmittedAt']),
        confirmedAt: _parseNullableDate(json['confirmedAt']),
        confirmedBy: json['confirmedBy']?.toString(),
        rejectReason: json['rejectReason']?.toString(),
        note: json['note']?.toString(),
        paidAmount: _parseAmount(json['paidAmount']),
        proofs: ((json['proofs'] as List?) ?? const [])
            .map((e) => PaymentProofResponse.fromJson(e))
            .toList(),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );
}

/// Totals for the payment screen header.
class PaymentBatchSummary {
  final double total;
  final double confirmed;
  final double awaitingConfirmation;
  final double outstanding;
  final int confirmedCount;
  final int awaitingCount;
  final int actionableCount;

  const PaymentBatchSummary({
    required this.total,
    required this.confirmed,
    required this.awaitingConfirmation,
    required this.outstanding,
    required this.confirmedCount,
    required this.awaitingCount,
    required this.actionableCount,
  });

  /// `confirmed` counts each batch's own amount, not `paidAmount`: once the
  /// provider has confirmed receipt the instalment is settled whatever the
  /// owner happened to type on the proof, and a proof with no amount would
  /// otherwise read as nothing received.
  factory PaymentBatchSummary.from(List<PaymentBatchResponse> batches) {
    var total = 0.0;
    var confirmed = 0.0;
    var awaiting = 0.0;
    var confirmedCount = 0;
    var awaitingCount = 0;
    var actionableCount = 0;

    for (final batch in batches) {
      total += batch.amount;
      if (batch.status == 'confirmed') {
        confirmed += batch.amount;
        confirmedCount++;
      } else if (batch.status == 'proof_submitted') {
        awaiting += batch.amount;
        awaitingCount++;
      }
      if (batch.needsOwnerAction) actionableCount++;
    }

    return PaymentBatchSummary(
      total: total,
      confirmed: confirmed,
      awaitingConfirmation: awaiting,
      outstanding: total - confirmed,
      confirmedCount: confirmedCount,
      awaitingCount: awaitingCount,
      actionableCount: actionableCount,
    );
  }
}

// ── Daily construction log ───────────────────────────────────────────────────

class DailyLogMediaResponse {
  final String id;
  final String mediaUrl;

  /// Absolute URL — use this for `Image.network`.
  final String? mediaViewUrl;

  /// `image` | `video`.
  final String mediaType;
  final String? caption;
  final int sortOrder;

  DailyLogMediaResponse({
    required this.id,
    required this.mediaUrl,
    this.mediaViewUrl,
    required this.mediaType,
    this.caption,
    required this.sortOrder,
  });

  factory DailyLogMediaResponse.fromJson(Map<String, dynamic> json) =>
      DailyLogMediaResponse(
        id: json['id']?.toString() ?? '',
        mediaUrl: json['mediaUrl']?.toString() ?? '',
        mediaViewUrl: json['mediaViewUrl']?.toString(),
        mediaType: json['mediaType']?.toString() ?? 'image',
        caption: json['caption']?.toString(),
        sortOrder: json['sortOrder'] ?? 0,
      );
}

/// A day of work as reported from site.
///
/// Read-only for the owner: the provider writes it, the owner follows progress
/// without driving out. Reading stays open at every engagement status, so the
/// log is still consultable after handover.
class DailyLogResponse {
  final String id;
  final String projectWorkingId;
  final String? constructionItemId;
  final String? constructionItemName;
  final String? constructionTaskId;
  final String? constructionTaskName;

  /// `yyyy-MM-dd`. The day the work happened, not when it was typed up.
  final String logDate;
  final String workDone;
  final String? issueNote;
  final String? weatherNote;
  final int? workerCount;

  final String? createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  final List<DailyLogMediaResponse> media;

  DailyLogResponse({
    required this.id,
    required this.projectWorkingId,
    this.constructionItemId,
    this.constructionItemName,
    this.constructionTaskId,
    this.constructionTaskName,
    required this.logDate,
    required this.workDone,
    this.issueNote,
    this.weatherNote,
    this.workerCount,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    required this.media,
  });

  factory DailyLogResponse.fromJson(Map<String, dynamic> json) =>
      DailyLogResponse(
        id: json['id']?.toString() ?? '',
        projectWorkingId: json['projectWorkingId']?.toString() ?? '',
        constructionItemId: json['constructionItemId']?.toString(),
        constructionItemName: json['constructionItemName']?.toString(),
        constructionTaskId: json['constructionTaskId']?.toString(),
        constructionTaskName: json['constructionTaskName']?.toString(),
        logDate: json['logDate']?.toString() ?? '',
        workDone: json['workDone']?.toString() ?? '',
        issueNote: json['issueNote']?.toString(),
        weatherNote: json['weatherNote']?.toString(),
        workerCount: json['workerCount'],
        createdBy: json['createdBy']?.toString(),
        createdByName: json['createdByName']?.toString(),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
        media: ((json['media'] as List?) ?? const [])
            .map((e) => DailyLogMediaResponse.fromJson(e))
            .toList(),
      );
}
