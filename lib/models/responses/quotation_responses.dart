DateTime _parseDate(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

double _parseMoney(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _parseInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class QuotationItemResponse {
  final String id;
  final String name;
  final String description;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;

  QuotationItemResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory QuotationItemResponse.fromJson(Map<String, dynamic> json) =>
      QuotationItemResponse(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        quantity: _parseMoney(json['quantity']),
        unit: json['unit']?.toString() ?? '',
        unitPrice: _parseMoney(json['unitPrice']),
        totalPrice: _parseMoney(json['totalPrice']),
      );
}

class QuotationPaymentTermResponse {
  final String id;
  final String description;
  final double amount;
  final DateTime? expectedPaymentDate;

  QuotationPaymentTermResponse({
    required this.id,
    required this.description,
    required this.amount,
    this.expectedPaymentDate,
  });

  factory QuotationPaymentTermResponse.fromJson(Map<String, dynamic> json) =>
      QuotationPaymentTermResponse(
        id: json['id']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        amount: _parseMoney(json['amount']),
        expectedPaymentDate: json['expectedPaymentDate'] != null
            ? DateTime.tryParse(json['expectedPaymentDate'].toString())
            : null,
      );
}

class QuotationResponse {
  final String id;
  final String applyId;
  final String projectWorkingId;
  final String title;
  final String description;
  final double totalAmount;
  final String status; // 'Draft', 'Pending', 'Accepted', 'Rejected', 'RevisionRequested'
  final int maxRevisions;
  final double revisionFee;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<QuotationItemResponse> items;
  final List<QuotationPaymentTermResponse> paymentTerms;
  final String? documentUrl;

  QuotationResponse({
    required this.id,
    required this.applyId,
    required this.projectWorkingId,
    required this.title,
    required this.description,
    required this.totalAmount,
    required this.status,
    required this.maxRevisions,
    required this.revisionFee,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.paymentTerms,
    this.documentUrl,
  });

  factory QuotationResponse.fromJson(Map<String, dynamic> json) =>
      QuotationResponse(
        id: json['id']?.toString() ?? '',
        applyId: json['applyId']?.toString() ?? '',
        projectWorkingId: json['projectWorkingId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        totalAmount: _parseMoney(json['totalAmount']),
        status: json['status']?.toString() ?? 'Draft',
        maxRevisions: _parseInt(json['maxRevisions']),
        revisionFee: _parseMoney(json['revisionFee']),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => QuotationItemResponse.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        paymentTerms: (json['paymentTerms'] as List<dynamic>?)
                ?.map((e) => QuotationPaymentTermResponse.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        documentUrl: json['documentUrl']?.toString(),
      );
}
