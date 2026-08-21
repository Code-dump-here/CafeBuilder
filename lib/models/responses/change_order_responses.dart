/// Response models for change orders: money agreed after the contract is
/// signed.
///
/// The handshake is deliberately two-sided. One party raises the charge and the
/// *other* accepts or rejects it — the owner can never approve something they
/// raised themselves, and neither can the provider. The contract value never
/// moves; [ChangeOrderSummaryResponse.totalCommitted] is what the job now costs.
library;

DateTime _parseDate(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

double _parseMoney(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _parseMoneyOrNull(dynamic value) {
  if (value == null) return null;
  return _parseMoney(value);
}

int? _parseIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

class ChangeOrderResponse {
  final String id;
  final String projectWorkingId;

  /// Set when the charge belongs to a design — revision fees do.
  final String? designId;

  /// Set when the charge belongs to a milestone.
  final String? constructionItemId;

  /// `extra_revision` | `scope_change` | `material_change` | `other`.
  final String kind;

  final String title;
  final String reason;
  final double amount;

  /// Which revision round triggered it. Only ever set for `extra_revision`.
  final int? revisionNo;

  /// `pending` | `accepted` | `rejected`. Terminal once it leaves `pending`.
  final String status;

  /// `owner` | `provider` — which side raised it.
  final String requestedByParty;

  final String? createdBy;
  final String? respondedBy;
  final DateTime? respondedAt;
  final String? rejectReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The payment batch this became once both sides agreed. Null while it is
  /// still pending, if it was rejected, if it is worth nothing, or if no
  /// contract is signed to hang a batch on — agreeing a number and having a
  /// way to pay it are two different things.
  final String? paymentBatchId;

  /// `pending` | `proof_submitted` | `confirmed` | `rejected`.
  final String? paymentBatchStatus;

  /// A revision fee the system opened that the provider has not priced yet,
  /// because the quotation never published a rate. It sits at 0 until they
  /// fill it in, and there is nothing for the owner to decide until then.
  final bool needsPricing;

  ChangeOrderResponse({
    required this.id,
    required this.projectWorkingId,
    this.designId,
    this.constructionItemId,
    required this.kind,
    required this.title,
    required this.reason,
    required this.amount,
    this.revisionNo,
    required this.status,
    required this.requestedByParty,
    this.createdBy,
    this.respondedBy,
    this.respondedAt,
    this.rejectReason,
    required this.createdAt,
    required this.updatedAt,
    this.paymentBatchId,
    this.paymentBatchStatus,
    this.needsPricing = false,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  /// True when the provider raised it, which is when the owner is the one who
  /// has to answer.
  bool get raisedByProvider => requestedByParty == 'provider';

  /// Accepted money that never turned into a batch the owner can pay — either
  /// no contract is signed, or it was agreed before extras generated batches.
  bool get acceptedButNotBilled =>
      isAccepted && amount > 0 && paymentBatchId == null;

  factory ChangeOrderResponse.fromJson(Map<String, dynamic> json) =>
      ChangeOrderResponse(
        // Ids are uuids server-side — keep them as strings, never parse to int.
        id: json['id']?.toString() ?? '',
        projectWorkingId: json['projectWorkingId']?.toString() ?? '',
        designId: json['designId']?.toString(),
        constructionItemId: json['constructionItemId']?.toString(),
        kind: json['kind'] ?? 'other',
        title: json['title'] ?? '',
        reason: json['reason'] ?? '',
        amount: _parseMoney(json['amount']),
        revisionNo: _parseIntOrNull(json['revisionNo']),
        status: json['status'] ?? 'pending',
        requestedByParty: json['requestedByParty'] ?? 'provider',
        createdBy: json['createdBy']?.toString(),
        respondedBy: json['respondedBy']?.toString(),
        respondedAt: json['respondedAt'] != null
            ? DateTime.tryParse(json['respondedAt'].toString())
            : null,
        rejectReason: json['rejectReason'],
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
        paymentBatchId: json['paymentBatchId']?.toString(),
        paymentBatchStatus: json['paymentBatchStatus']?.toString(),
        needsPricing: json['needsPricing'] == true,
      );
}

/// What the engagement is committed to, all in.
class ChangeOrderSummaryResponse {
  final String projectWorkingId;

  /// Null until a contract is signed — "nothing to add up yet" is not "zero".
  final double? contractValue;

  final double acceptedAmount;
  final double pendingAmount;

  /// Contract + accepted extras. Null while [contractValue] is.
  final double? totalCommitted;

  final int acceptedCount;
  final int pendingCount;
  final int rejectedCount;

  /// Of the accepted total, how much came from extra design revisions.
  final double acceptedRevisionFee;

  /// How much of the accepted total turned into a real payment batch.
  final double billedAmount;

  /// How much of that the provider has confirmed receiving.
  final double paidAmount;

  /// `acceptedAmount - billedAmount`. Above zero means money both sides agreed
  /// that no payment batch covers yet.
  final double unbilledAmount;

  ChangeOrderSummaryResponse({
    required this.projectWorkingId,
    this.contractValue,
    required this.acceptedAmount,
    required this.pendingAmount,
    this.totalCommitted,
    required this.acceptedCount,
    required this.pendingCount,
    required this.rejectedCount,
    required this.acceptedRevisionFee,
    this.billedAmount = 0,
    this.paidAmount = 0,
    this.unbilledAmount = 0,
  });

  factory ChangeOrderSummaryResponse.fromJson(Map<String, dynamic> json) =>
      ChangeOrderSummaryResponse(
        projectWorkingId: json['projectWorkingId']?.toString() ?? '',
        contractValue: _parseMoneyOrNull(json['contractValue']),
        acceptedAmount: _parseMoney(json['acceptedAmount']),
        pendingAmount: _parseMoney(json['pendingAmount']),
        totalCommitted: _parseMoneyOrNull(json['totalCommitted']),
        acceptedCount: _parseIntOrNull(json['acceptedCount']) ?? 0,
        pendingCount: _parseIntOrNull(json['pendingCount']) ?? 0,
        rejectedCount: _parseIntOrNull(json['rejectedCount']) ?? 0,
        acceptedRevisionFee: _parseMoney(json['acceptedRevisionFee']),
        billedAmount: _parseMoney(json['billedAmount']),
        paidAmount: _parseMoney(json['paidAmount']),
        unbilledAmount: _parseMoney(json['unbilledAmount']),
      );
}

/// How many revision rounds a design has left before they start costing.
///
/// [freeRevisionCount] null means no accepted quotation fixed a number, so
/// nothing is gated: unlimited rounds, no fee.
class RevisionQuotaResponse {
  final String designId;
  final String projectWorkingId;
  final String? quotationId;
  final int? freeRevisionCount;

  /// Rounds spent on *this* design. Shown, but not what the quota measures.
  final int usedRevisionCount;

  /// Rounds spent across every design in the engagement. This is the figure the
  /// server compares to [freeRevisionCount], because the quota comes from the
  /// quotation and a quotation covers the whole engagement, not one drawing.
  final int engagementUsedRevisionCount;

  final int? remainingFreeRevisions;
  final bool nextRevisionCharged;

  /// Null when the provider never published a price for extra rounds — the two
  /// sides then have to agree one on a change order.
  final double? extraRevisionFee;

  RevisionQuotaResponse({
    required this.designId,
    this.projectWorkingId = '',
    this.quotationId,
    this.freeRevisionCount,
    required this.usedRevisionCount,
    this.engagementUsedRevisionCount = 0,
    this.remainingFreeRevisions,
    required this.nextRevisionCharged,
    this.extraRevisionFee,
  });

  factory RevisionQuotaResponse.fromJson(Map<String, dynamic> json) =>
      RevisionQuotaResponse(
        designId: json['designId']?.toString() ?? '',
        projectWorkingId: json['projectWorkingId']?.toString() ?? '',
        quotationId: json['quotationId']?.toString(),
        freeRevisionCount: _parseIntOrNull(json['freeRevisionCount']),
        usedRevisionCount: _parseIntOrNull(json['usedRevisionCount']) ?? 0,
        engagementUsedRevisionCount:
            _parseIntOrNull(json['engagementUsedRevisionCount']) ?? 0,
        remainingFreeRevisions: _parseIntOrNull(json['remainingFreeRevisions']),
        nextRevisionCharged: json['nextRevisionCharged'] == true,
        extraRevisionFee: _parseMoneyOrNull(json['extraRevisionFee']),
      );
}

const Map<String, String> kChangeOrderKindLabels = {
  'extra_revision': 'Phí sửa thêm',
  'scope_change': 'Đổi phạm vi',
  'material_change': 'Đổi vật tư',
  'other': 'Khác',
};

const Map<String, String> kChangeOrderStatusLabels = {
  'pending': 'Chờ bạn duyệt',
  'accepted': 'Đã duyệt',
  'rejected': 'Đã từ chối',
};

/// Where the money got to after both sides agreed. Written from the owner's
/// side: they are the one who transfers, the provider confirms receipt.
const Map<String, String> kChangeOrderBillingLabels = {
  'pending': 'Đã ra đợt thu — chờ bạn chuyển khoản',
  'proof_submitted': 'Bạn đã báo chuyển — chờ nhà cung cấp đối chiếu',
  'confirmed': 'Đã thanh toán xong',
  'rejected': 'Nhà cung cấp bác minh chứng — nộp lại ở trang thanh toán',
};
