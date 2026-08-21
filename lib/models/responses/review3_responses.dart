/// Response models for the review-3 additions: the acceptance checklist and
/// the material price list / cost roll-up.
///
/// Kept out of `api_responses.dart` only because that file is already very
/// large; the shapes and parsing style match it exactly.
library;

DateTime _parseDate(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

// ── Acceptance checklist ─────────────────────────────────────────────────────

/// One item on the acceptance checklist for a design or a construction
/// milestone.
///
/// The provider writes the list; the **shop owner** marks each item passed or
/// failed and says what needs fixing. Required items that are not `passed`
/// block closing the milestone, approving the design, and accepting the
/// engagement — so grading here is the sign-off itself, not a log of it.
class ChecklistItemResponse {
  final String id;

  /// Set when the item belongs to a design; null for construction milestones.
  final String? designId;

  /// Set when the item belongs to a milestone; null for designs.
  final String? constructionItemId;

  final String name;
  final String? description;
  final int sortOrder;

  /// Only required items block sign-off. Optional ones are advisory.
  final bool isRequired;

  /// `pending` | `passed` | `failed`.
  final String status;

  /// Storage object name of the evidence file.
  final String? evidenceUrl;

  /// Absolute URL for displaying the evidence.
  final String? evidenceViewUrl;

  /// The owner note. Mandatory when failing an item, so the provider always
  /// learns what to fix.
  final String? note;

  final String? checkedBy;
  final DateTime? checkedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChecklistItemResponse({
    required this.id,
    this.designId,
    this.constructionItemId,
    required this.name,
    this.description,
    required this.sortOrder,
    required this.isRequired,
    required this.status,
    this.evidenceUrl,
    this.evidenceViewUrl,
    this.note,
    this.checkedBy,
    this.checkedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPassed => status == 'passed';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';

  factory ChecklistItemResponse.fromJson(Map<String, dynamic> json) =>
      ChecklistItemResponse(
        // Ids are uuids server-side — keep them as strings, never parse to int.
        id: json['id']?.toString() ?? '',
        designId: json['designId']?.toString(),
        constructionItemId: json['constructionItemId']?.toString(),
        name: json['name'] ?? '',
        description: json['description'],
        sortOrder: json['sortOrder'] ?? 0,
        isRequired: json['isRequired'] == true,
        status: json['status'] ?? 'pending',
        evidenceUrl: json['evidenceUrl'],
        evidenceViewUrl: json['evidenceViewUrl'],
        note: json['note'],
        checkedBy: json['checkedBy']?.toString(),
        checkedAt: json['checkedAt'] != null
            ? DateTime.tryParse(json['checkedAt'].toString())
            : null,
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );
}

/// Counts behind the question "why can it not be signed off yet".
class ChecklistProgress {
  final int total;
  final int requiredTotal;
  final int requiredPassed;
  final int requiredPending;
  final int requiredFailed;

  const ChecklistProgress({
    required this.total,
    required this.requiredTotal,
    required this.requiredPassed,
    required this.requiredPending,
    required this.requiredFailed,
  });

  /// True when every required item has passed.
  bool get isSatisfied => requiredPending == 0 && requiredFailed == 0;

  /// How many required items still stand in the way.
  int get blockingCount => requiredPending + requiredFailed;

  factory ChecklistProgress.from(List<ChecklistItemResponse> items) {
    final required = items.where((i) => i.isRequired).toList();
    return ChecklistProgress(
      total: items.length,
      requiredTotal: required.length,
      requiredPassed: required.where((i) => i.isPassed).length,
      requiredPending: required.where((i) => i.isPending).length,
      requiredFailed: required.where((i) => i.isFailed).length,
    );
  }
}

// ── Materials ────────────────────────────────────────────────────────────────

/// A row on the project published material price list.
class MaterialResponse {
  final String id;
  final String projectWorkingId;
  final String name;
  final String? description;

  /// md | m2 | m3 | kg | litre | item | set | manday.
  final String unit;

  final double unitPrice;
  final int sortOrder;

  MaterialResponse({
    required this.id,
    required this.projectWorkingId,
    required this.name,
    this.description,
    required this.unit,
    required this.unitPrice,
    required this.sortOrder,
  });

  factory MaterialResponse.fromJson(Map<String, dynamic> json) =>
      MaterialResponse(
        id: json['id']?.toString() ?? '',
        projectWorkingId: json['projectWorkingId']?.toString() ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        unit: json['unit'] ?? '',
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        sortOrder: json['sortOrder'] ?? 0,
      );
}

/// A "this milestone or task uses N of material X" line.
class ConstructionMaterialResponse {
  final String id;
  final String? constructionItemId;
  final String? constructionTaskId;
  final String materialId;
  final String materialName;
  final String unit;

  /// The rate captured when the material was picked — not a live read of the
  /// price list, so repricing later cannot restate work already costed.
  final double unitPrice;

  final double estimatedQuantity;

  /// Null until the work is done and the real figure is recorded.
  final double? actualQuantity;

  final double estimatedCost;
  final double? actualCost;
  final String? note;

  ConstructionMaterialResponse({
    required this.id,
    this.constructionItemId,
    this.constructionTaskId,
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.unitPrice,
    required this.estimatedQuantity,
    this.actualQuantity,
    required this.estimatedCost,
    this.actualCost,
    this.note,
  });

  factory ConstructionMaterialResponse.fromJson(Map<String, dynamic> json) =>
      ConstructionMaterialResponse(
        id: json['id']?.toString() ?? '',
        constructionItemId: json['constructionItemId']?.toString(),
        constructionTaskId: json['constructionTaskId']?.toString(),
        materialId: json['materialId']?.toString() ?? '',
        materialName: json['materialName'] ?? '',
        unit: json['unit'] ?? '',
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        estimatedQuantity: (json['estimatedQuantity'] as num?)?.toDouble() ?? 0,
        actualQuantity: (json['actualQuantity'] as num?)?.toDouble(),
        estimatedCost: (json['estimatedCost'] as num?)?.toDouble() ?? 0,
        actualCost: (json['actualCost'] as num?)?.toDouble(),
        note: json['note'],
      );
}

/// Cost roll-up for a milestone: its own lines plus every child task lines.
///
/// [totalActualCost] is null while any line still lacks an actual quantity.
/// The server withholds it deliberately — a partial sum shown as "actual cost"
/// reads as authoritative while being wrong — and reports how many lines are
/// outstanding in [missingActualCount] instead.
class MaterialCostSummaryResponse {
  final String constructionItemId;
  final double ownEstimatedCost;
  final double? ownActualCost;
  final double tasksEstimatedCost;
  final double? tasksActualCost;
  final double totalEstimatedCost;
  final double? totalActualCost;
  final int missingActualCount;
  final List<ConstructionMaterialResponse> lines;

  MaterialCostSummaryResponse({
    required this.constructionItemId,
    required this.ownEstimatedCost,
    this.ownActualCost,
    required this.tasksEstimatedCost,
    this.tasksActualCost,
    required this.totalEstimatedCost,
    this.totalActualCost,
    required this.missingActualCount,
    required this.lines,
  });

  factory MaterialCostSummaryResponse.fromJson(Map<String, dynamic> json) =>
      MaterialCostSummaryResponse(
        constructionItemId: json['constructionItemId']?.toString() ?? '',
        ownEstimatedCost: (json['ownEstimatedCost'] as num?)?.toDouble() ?? 0,
        ownActualCost: (json['ownActualCost'] as num?)?.toDouble(),
        tasksEstimatedCost:
            (json['tasksEstimatedCost'] as num?)?.toDouble() ?? 0,
        tasksActualCost: (json['tasksActualCost'] as num?)?.toDouble(),
        totalEstimatedCost:
            (json['totalEstimatedCost'] as num?)?.toDouble() ?? 0,
        totalActualCost: (json['totalActualCost'] as num?)?.toDouble(),
        missingActualCount: json['missingActualCount'] ?? 0,
        lines: (json['lines'] as List<dynamic>? ?? [])
            .map((e) =>
                ConstructionMaterialResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
