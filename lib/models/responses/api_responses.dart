/// Parses a required createdAt/updatedAt-style timestamp. Falls back to
/// DateTime.now() on a missing or malformed value instead of throwing —
/// mirrors the tolerant pattern already used by ProjectResponse/CommentResponse,
/// applied consistently across every response class instead of a handful.
DateTime _parseDate(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

class ResponseData<T> {
  final bool success;
  final String? message;
  final T? data;
  final int statusCode;

  ResponseData({
    required this.success,
    this.message,
    this.data,
    required this.statusCode,
  });

  factory ResponseData.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ResponseData(
      success: json['success'] ?? true,
      message: json['message'],
      data: fromJsonT == null ? null : fromJsonT(json['data'] ?? json),
      statusCode: json['statusCode'] ?? 200,
    );
  }
}

class PaginationResponse<T> {
  final List<T> items;
  final int pageNumber;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;

  PaginationResponse({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
  });

  factory PaginationResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginationResponse(
      items: (json['items'] as List).map((e) => fromJsonT(e)).toList(),
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      totalItems: json['totalItems'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasPrevious: json['hasPrevious'] ?? false,
      hasNext: json['hasNext'] ?? false,
    );
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String accountId;
  final String email;
  final String role;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accountId,
    required this.email,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['accessToken'] ?? json['AccessToken'] ?? '',
    refreshToken: json['refreshToken'] ?? json['RefreshToken'] ?? '',
    // `as num` used to bind tighter than `??`, so a missing 'accountId'
    // fell through to `null as num` and threw instead of trying
    // 'AccountId'. Parenthesized so both keys are checked before casting.
    accountId: (json['accountId'] ?? json['AccountId'])?.toString() ?? '',
    email: json['email'] ?? json['Email'] ?? '',
    role: json['role'] ?? json['Role'] ?? '',
  );
}

class AccountResponse {
  final String id;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final DateTime createdAt;

  AccountResponse({
    required this.id,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory AccountResponse.fromJson(Map<String, dynamic> json) =>
      AccountResponse(
        id: json['id']?.toString() ?? '',
        email: json['email'],
        phone: json['phone'],
        role: json['role'],
        status: json['status'],
        createdAt: _parseDate(json['createdAt']),
      );
}

class ProjectOwnerResponse {
  final String id;
  final String fullName;
  final String shopName;
  final String phone;

  ProjectOwnerResponse({
    required this.id,
    required this.fullName,
    required this.shopName,
    required this.phone,
  });

  factory ProjectOwnerResponse.fromJson(Map<String, dynamic> json) =>
      ProjectOwnerResponse(
        id: json['id']?.toString() ?? '',
        fullName: json['fullName'] ?? '',
        shopName: json['shopName'] ?? '',
        phone: json['phone'] ?? '',
      );
}

class OpenPostResponse {
  final String id;
  final String serviceKind;
  final String title;
  final String status;
  final DateTime? submissionDeadline;

  OpenPostResponse({
    required this.id,
    required this.serviceKind,
    required this.title,
    required this.status,
    this.submissionDeadline,
  });

  factory OpenPostResponse.fromJson(Map<String, dynamic> json) =>
      OpenPostResponse(
        id: json['id']?.toString() ?? '',
        serviceKind: json['serviceKind'] ?? '',
        title: json['title'] ?? '',
        status: json['status'] ?? '',
        submissionDeadline: json['submissionDeadline'] != null
            ? DateTime.parse(json['submissionDeadline'])
            : null,
      );
}

class ProjectResponse {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final double areaM2;
  final double budget;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProjectOwnerResponse? owner;
  final List<OpenPostResponse> openPosts;
  final List<String> openFor;
  final List<dynamic> providers;

  ProjectResponse({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.areaM2,
    required this.budget,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.owner,
    this.openPosts = const [],
    this.openFor = const [],
    this.providers = const [],
  });

  factory ProjectResponse.fromJson(Map<String, dynamic> json) =>
      ProjectResponse(
        id: json['id']?.toString() ?? '',
        ownerId: json['ownerId']?.toString() ?? '',
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        areaM2: json['areaM2'] is num ? (json['areaM2'] as num).toDouble() : 0,
        budget: json['budget'] is num ? (json['budget'] as num).toDouble() : 0,
        status: json['status'] ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        owner: json['owner'] != null
            ? ProjectOwnerResponse.fromJson(json['owner'])
            : null,
        openPosts:
            (json['openPosts'] as List?)
                ?.map((e) => OpenPostResponse.fromJson(e))
                .toList() ??
            [],
        openFor: (json['openFor'] as List?)?.whereType<String>().toList() ?? [],
        providers: json['providers'] is List
            ? json['providers'] as List
            : const [],
      );
}

class DesignBriefResponse {
  final String id;
  final String projectId;
  final String targetCustomer;
  final String style;
  final String mood;
  final int? seatCount;
  final String? timeline;
  final String? brandNote;
  final String? businessModel;
  final String? businessGoals;
  final String? operationNote;
  final DateTime createdAt;

  DesignBriefResponse({
    required this.id,
    required this.projectId,
    required this.targetCustomer,
    required this.style,
    required this.mood,
    this.seatCount,
    this.timeline,
    this.brandNote,
    this.businessModel,
    this.businessGoals,
    this.operationNote,
    required this.createdAt,
  });

  factory DesignBriefResponse.fromJson(Map<String, dynamic> json) =>
      DesignBriefResponse(
        id: json['id']?.toString() ?? '',
        projectId: (json['projectShopOwnerId'] ?? json['projectId'])?.toString() ?? '',
        targetCustomer: json['targetCustomer'] ?? '',
        style: json['style'] ?? '',
        mood: json['mood'] ?? '',
        seatCount: json['seatCount'],
        timeline: json['timeline'],
        brandNote: json['brandNote'],
        businessModel: json['businessModel'],
        businessGoals: json['businessGoals'],
        operationNote: json['operationNote'],
        createdAt: _parseDate(json['createdAt']),
      );
}

// ── AI Job Zone ─────────────────────────────────────────────────────────────

class AiLayoutZone {
  final String id;
  final String label;
  final String purpose;
  final double x;
  final double y;
  final double w;
  final double h;
  final bool isStaffOnly;

  AiLayoutZone({
    required this.id,
    required this.label,
    required this.purpose,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.isStaffOnly,
  });

  factory AiLayoutZone.fromJson(Map<String, dynamic> json) => AiLayoutZone(
    id: json['id'] ?? '',
    label: json['label'] ?? '',
    purpose: json['purpose'] ?? '',
    x: (json['x'] as num?)?.toDouble() ?? 0,
    y: (json['y'] as num?)?.toDouble() ?? 0,
    w: (json['w'] as num?)?.toDouble() ?? 1,
    h: (json['h'] as num?)?.toDouble() ?? 1,
    isStaffOnly: json['is_staff_only'] ?? false,
  );
}

class AiRecommendationItem {
  final String title;
  final String rationale;
  final int priority;

  AiRecommendationItem({
    required this.title,
    required this.rationale,
    required this.priority,
  });

  factory AiRecommendationItem.fromJson(Map<String, dynamic> json) =>
      AiRecommendationItem(
        title: json['title'] ?? '',
        rationale: json['rationale'] ?? '',
        priority: (json['priority'] as num?)?.toInt() ?? 0,
      );
}

class AiRiskNote {
  final String level;
  final String title;
  final String description;
  final String? mitigation;

  AiRiskNote({
    required this.level,
    required this.title,
    required this.description,
    this.mitigation,
  });

  factory AiRiskNote.fromJson(Map<String, dynamic> json) => AiRiskNote(
    level: json['level'] ?? 'low',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    mitigation: json['mitigation'],
  );
}

class AiCustomerFlowStage {
  final String stage;
  final String description;

  AiCustomerFlowStage({required this.stage, required this.description});

  factory AiCustomerFlowStage.fromJson(Map<String, dynamic> json) =>
      AiCustomerFlowStage(
        stage: json['stage'] ?? '',
        description: json['description'] ?? '',
      );
}

class AiRecommendationResponse {
  final String id;
  final String briefId;
  final String conceptSummary;
  final String payload;
  final double? estimatedDesignCost;
  final double? estimatedConstructionCost;
  final DateTime createdAt;
  // Job info
  final String? jobId;
  final String? state; // queued | processing | completed | failed
  final String? lastError;
  // Plan summary
  final String? planConceptName;
  final String? planSummary;
  // Layout
  final double? layoutWidth;
  final double? layoutHeight;
  final String? layoutUnit;
  final List<AiLayoutZone> layoutZones;
  // Costs (VND)
  final double? fitoutMinVnd;
  final double? fitoutMaxVnd;
  final double? equipmentMinVnd;
  final double? equipmentMaxVnd;
  final double? contingencyPercent;
  final String? costNotes;
  // Recommendations & risks
  final List<AiRecommendationItem> recommendations;
  final List<AiRiskNote> riskNotes;
  final List<AiCustomerFlowStage> customerFlow;
  // Image
  final String? imageView;
  final String? imageArtifactUrl;
  final int? seatCapacityRecommendation;

  AiRecommendationResponse({
    required this.id,
    required this.briefId,
    required this.conceptSummary,
    required this.payload,
    this.estimatedDesignCost,
    this.estimatedConstructionCost,
    required this.createdAt,
    this.jobId,
    this.state,
    this.lastError,
    this.planConceptName,
    this.planSummary,
    this.layoutWidth,
    this.layoutHeight,
    this.layoutUnit,
    this.layoutZones = const [],
    this.fitoutMinVnd,
    this.fitoutMaxVnd,
    this.equipmentMinVnd,
    this.equipmentMaxVnd,
    this.contingencyPercent,
    this.costNotes,
    this.recommendations = const [],
    this.riskNotes = const [],
    this.customerFlow = const [],
    this.imageView,
    this.imageArtifactUrl,
    this.seatCapacityRecommendation,
  });

  bool get isCompleted => state == 'completed';
  bool get isFailed => state == 'failed';
  bool get isPending => state == 'queued' || state == 'processing';

  factory AiRecommendationResponse.fromJson(Map<String, dynamic> json) =>
      AiRecommendationResponse(
        id: json['id']?.toString() ?? '',
        briefId: json['briefId']?.toString() ?? '',
        conceptSummary: json['conceptSummary'] ?? '',
        payload: json['payload'] ?? '',
        estimatedDesignCost: json['estimatedDesignCost'] != null
            ? (json['estimatedDesignCost'] as num).toDouble()
            : null,
        estimatedConstructionCost: json['estimatedConstructionCost'] != null
            ? (json['estimatedConstructionCost'] as num).toDouble()
            : null,
        createdAt: _parseDate(json['createdAt']),
        jobId: json['jobId']?.toString() ?? '',
        state: json['state'],
        lastError: json['lastError'],
        planConceptName: json['planConceptName'],
        planSummary: json['planSummary'],
        layoutWidth: (json['layoutWidth'] as num?)?.toDouble(),
        layoutHeight: (json['layoutHeight'] as num?)?.toDouble(),
        layoutUnit: json['layoutUnit'],
        layoutZones:
            (json['layoutZones'] as List?)
                ?.map((e) => AiLayoutZone.fromJson(e))
                .toList() ??
            [],
        fitoutMinVnd: (json['fitoutMinVnd'] as num?)?.toDouble(),
        fitoutMaxVnd: (json['fitoutMaxVnd'] as num?)?.toDouble(),
        equipmentMinVnd: (json['equipmentMinVnd'] as num?)?.toDouble(),
        equipmentMaxVnd: (json['equipmentMaxVnd'] as num?)?.toDouble(),
        contingencyPercent: (json['contingencyPercent'] as num?)?.toDouble(),
        costNotes: json['costNotes'],
        recommendations:
            (json['recommendations'] as List?)
                ?.map((e) => AiRecommendationItem.fromJson(e))
                .toList() ??
            [],
        riskNotes:
            (json['riskNotes'] as List?)
                ?.map((e) => AiRiskNote.fromJson(e))
                .toList() ??
            [],
        customerFlow:
            (json['customerFlow'] as List?)
                ?.map((e) => AiCustomerFlowStage.fromJson(e))
                .toList() ??
            [],
        imageView: json['imageView'],
        imageArtifactUrl: json['imageArtifactUrl'],
        seatCapacityRecommendation: (json['seatCapacityRecommendation'] as num?)
            ?.toInt(),
      );
}

class ServiceProviderResponse {
  final String id;
  final String accountId;
  final String displayName;
  final String providerType;
  final String capability;
  final String? bio;
  final String? companyTaxCode;
  final int? yearsExperience;
  final String? portfolioHeadline;
  final bool isVerified;
  final double avgRating;
  final DateTime createdAt;

  ServiceProviderResponse({
    required this.id,
    required this.accountId,
    required this.displayName,
    required this.providerType,
    required this.capability,
    this.bio,
    this.companyTaxCode,
    this.yearsExperience,
    this.portfolioHeadline,
    required this.isVerified,
    required this.avgRating,
    required this.createdAt,
  });

  factory ServiceProviderResponse.fromJson(Map<String, dynamic> json) =>
      ServiceProviderResponse(
        id: json['id']?.toString() ?? '',
        accountId: json['accountId']?.toString() ?? '',
        displayName: json['displayName'],
        providerType: json['providerType'],
        capability: json['capability'],
        bio: json['bio'],
        companyTaxCode: json['companyTaxCode'],
        yearsExperience: json['yearsExperience'],
        portfolioHeadline: json['portfolioHeadline'],
        isVerified: json['isVerified'] ?? false,
        avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
        createdAt: _parseDate(json['createdAt']),
      );
}

class ShopOwnerResponse {
  final String id;
  final String accountId;
  final String fullName;
  final String shopName;
  final String phone;
  final String address;
  final DateTime createdAt;

  ShopOwnerResponse({
    required this.id,
    required this.accountId,
    required this.fullName,
    required this.shopName,
    required this.phone,
    required this.address,
    required this.createdAt,
  });

  factory ShopOwnerResponse.fromJson(Map<String, dynamic> json) =>
      ShopOwnerResponse(
        id: json['id']?.toString() ?? '',
        accountId: json['accountId']?.toString() ?? '',
        fullName: json['fullName'] ?? '',
        shopName: json['shopName'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
        createdAt: _parseDate(json['createdAt']),
      );
}

class ApplyResponse {
  final String id;
  final String postId;
  final String postTitle;
  final String projectShopOwnerId;
  final String serviceProviderProfileId;
  final String providerDisplayName;
  final String proposal;

  /// `int?` server-side — the provider may leave it out. Coercing a missing
  /// value to 0 made "not stated" read as a firm estimate of zero days.
  final int? estimatedDurationDays;
  final String status;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// How many site surveys the applicant has attached to this application.
  final int surveyCount;

  /// Appointment on the most recent survey — set once the visit is booked.
  final DateTime? latestSurveyScheduledAt;

  /// When the applicant actually walked the site. Null means the visit is
  /// still only booked.
  final DateTime? latestSurveyedAt;

  /// Whether any attached survey has been carried out. On a post with a design
  /// phase the server refuses to accept the application until this is true, so
  /// the owner's Accept button keys off it.
  final bool hasCompletedSurvey;

  ApplyResponse({
    required this.id,
    required this.postId,
    required this.postTitle,
    required this.projectShopOwnerId,
    required this.serviceProviderProfileId,
    required this.providerDisplayName,
    required this.proposal,
    this.estimatedDurationDays,
    required this.status,
    this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
    this.surveyCount = 0,
    this.latestSurveyScheduledAt,
    this.latestSurveyedAt,
    this.hasCompletedSurvey = false,
  });

  factory ApplyResponse.fromJson(Map<String, dynamic> json) => ApplyResponse(
    id: json['id']?.toString() ?? '',
    postId: json['postId']?.toString() ?? '',
    postTitle: json['postTitle'] ?? '',
    projectShopOwnerId: json['projectShopOwnerId']?.toString() ?? '',
    serviceProviderProfileId: json['serviceProviderProfileId']?.toString() ?? '',
    providerDisplayName: json['providerDisplayName'] ?? '',
    proposal: json['proposal'] ?? '',
    estimatedDurationDays: json['estimatedDurationDays'] as int?,
    status: json['status'] ?? '',
    submittedAt: json['submittedAt'] != null
        ? DateTime.parse(json['submittedAt'])
        : null,
    createdAt: _parseDate(json['createdAt']),
    updatedAt: _parseDate(json['updatedAt']),
    surveyCount: (json['surveyCount'] as num?)?.toInt() ?? 0,
    latestSurveyScheduledAt: DateTime.tryParse(
      json['latestSurveyScheduledAt']?.toString() ?? '',
    ),
    latestSurveyedAt: DateTime.tryParse(
      json['latestSurveyedAt']?.toString() ?? '',
    ),
    hasCompletedSurvey: json['hasCompletedSurvey'] == true,
  );
}

class ProjectWorkingResponse {
  final String id;
  final String projectShopOwnerId;
  final String projectName;
  final String serviceProviderProfileId;
  final String providerDisplayName;
  final String? applyId;
  final String contractType;
  final String status;
  final String? requestMessage;
  final DateTime? startedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasConfirmedContract;
  final DateTime? completionRequestedAt;
  final String? completionRequestNote;
  final bool isAwaitingAcceptance;
  // Ending an engagement needs both sides to agree. A request parks here
  // until the other party responds; the engagement stays 'accepted'.
  final DateTime? terminationRequestedAt;

  /// 'owner' | 'provider' — which side asked to end it.
  final String? terminationRequestedBy;
  final String? terminationRequestNote;
  final DateTime? terminatedAt;

  /// Server-derived: a request is pending the other side's answer.
  final bool isAwaitingTerminationApproval;

  ProjectWorkingResponse({
    required this.id,
    required this.projectShopOwnerId,
    required this.projectName,
    required this.serviceProviderProfileId,
    required this.providerDisplayName,
    this.applyId,
    required this.contractType,
    required this.status,
    this.requestMessage,
    this.startedAt,
    required this.createdAt,
    required this.updatedAt,
    this.hasConfirmedContract = false,
    this.completionRequestedAt,
    this.completionRequestNote,
    this.isAwaitingAcceptance = false,
    this.terminationRequestedAt,
    this.terminationRequestedBy,
    this.terminationRequestNote,
    this.terminatedAt,
    this.isAwaitingTerminationApproval = false,
  });

  factory ProjectWorkingResponse.fromJson(Map<String, dynamic> json) =>
      ProjectWorkingResponse(
        id: json['id']?.toString() ?? '',
        projectShopOwnerId: json['projectShopOwnerId']?.toString() ?? '',
        projectName: json['projectName'] ?? '',
        serviceProviderProfileId: json['serviceProviderProfileId']?.toString() ?? '',
        providerDisplayName: json['providerDisplayName'] ?? '',
        applyId: json['applyId']?.toString() ?? '',
        contractType: json['contractType'] ?? '',
        status: json['status'] ?? '',
        requestMessage: json['requestMessage'],
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'])
            : null,
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
        hasConfirmedContract: json['hasConfirmedContract'] ?? false,
        completionRequestedAt: json['completionRequestedAt'] != null
            ? DateTime.parse(json['completionRequestedAt'])
            : null,
        completionRequestNote: json['completionRequestNote'],
        isAwaitingAcceptance: json['isAwaitingAcceptance'] ?? false,
        terminationRequestedAt: json['terminationRequestedAt'] != null
            ? DateTime.parse(json['terminationRequestedAt'])
            : null,
        terminationRequestedBy: json['terminationRequestedBy'],
        terminationRequestNote: json['terminationRequestNote'],
        terminatedAt: json['terminatedAt'] != null
            ? DateTime.parse(json['terminatedAt'])
            : null,
        isAwaitingTerminationApproval:
            json['isAwaitingTerminationApproval'] ?? false,
      );
}

class EngagementOverviewResponse {
  final String projectWorkingId;
  final String contractType;
  final String status;
  final ProjectResponse? projectShopOwner;
  final DesignBriefResponse? brief;
  final List<AiRecommendationResponse> aiRecommendations;
  final List<DesignResponse> approvedDesigns;

  EngagementOverviewResponse({
    required this.projectWorkingId,
    required this.contractType,
    required this.status,
    this.projectShopOwner,
    this.brief,
    this.aiRecommendations = const [],
    this.approvedDesigns = const [],
  });

  factory EngagementOverviewResponse.fromJson(Map<String, dynamic> json) =>
      EngagementOverviewResponse(
        projectWorkingId: json['projectWorkingId']?.toString() ?? '',
        contractType: json['contractType'] ?? '',
        status: json['status'] ?? '',
        projectShopOwner: json['projectShopOwner'] != null
            ? ProjectResponse.fromJson(json['projectShopOwner'])
            : null,
        brief: json['brief'] != null
            ? DesignBriefResponse.fromJson(json['brief'])
            : null,
        aiRecommendations:
            (json['aiRecommendations'] as List?)
                ?.map((e) => AiRecommendationResponse.fromJson(e))
                .toList() ??
            [],
        approvedDesigns:
            (json['approvedDesigns'] as List?)
                ?.map((e) => DesignResponse.fromJson(e))
                .toList() ??
            [],
      );
}

class SurveyResponse {
  final String id;

  /// Null when the survey hangs off an application rather than an engagement
  /// — a provider surveys the site while still bidding, so the owner can
  /// compare site visits before choosing anyone. See `ck_surveys_target`.
  final String? projectWorkingId;

  /// Null when the survey hangs off an engagement. Exactly one of the two is set.
  final String? applyId;

  /// The booked visit. Set on its own when the provider has only made an
  /// appointment and not yet been.
  final DateTime? scheduledAt;

  /// When the provider actually walked the site. Null means booked-only, and
  /// on a design-scope post the owner cannot accept them yet.
  final DateTime? surveyedAt;

  final String? conditionNote;

  /// Raw object name on the bucket — NOT openable. Kept because the backend
  /// still sends it and older rows may only have this.
  final String? reportUrl;

  /// Absolute public URL the backend resolves for us. Always prefer this when
  /// opening the report; `reportUrl` on its own 404s.
  final String? reportViewUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The link to hand to a browser, or null when no report was uploaded.
  String? get openableReportUrl => reportViewUrl ?? reportUrl;

  SurveyResponse({
    required this.id,
    this.projectWorkingId,
    this.applyId,
    this.scheduledAt,
    this.surveyedAt,
    this.conditionNote,
    this.reportUrl,
    this.reportViewUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SurveyResponse.fromJson(Map<String, dynamic> json) => SurveyResponse(
    id: json['id']?.toString() ?? '',
    projectWorkingId: json['projectWorkingId']?.toString(),
    applyId: json['applyId']?.toString(),
    scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? ''),
    surveyedAt: DateTime.tryParse(json['surveyedAt']?.toString() ?? ''),
    conditionNote: json['conditionNote'],
    reportUrl: json['reportUrl'],
    reportViewUrl: json['reportViewUrl'],
    createdBy: json['createdBy']?.toString() ?? '',
    createdAt: _parseDate(json['createdAt']),
    updatedAt: _parseDate(json['updatedAt']),
  );
}

class ContractResponse {
  final String id;
  final String projectWorkingId;
  final String title;
  final String? partyInfo;
  final String? terms;
  final double agreedValue;
  final String? documentUrl;
  final String? documentViewUrl;
  final DateTime? otpExpiresAt;
  final DateTime? confirmedAt;
  final String? confirmedBy;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContractResponse({
    required this.id,
    required this.projectWorkingId,
    required this.title,
    this.partyInfo,
    this.terms,
    required this.agreedValue,
    this.documentUrl,
    this.documentViewUrl,
    this.otpExpiresAt,
    this.confirmedAt,
    this.confirmedBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContractResponse.fromJson(Map<String, dynamic> json) =>
      ContractResponse(
        id: json['id']?.toString() ?? '',
        projectWorkingId: json['projectWorkingId']?.toString() ?? '',
        title: json['title'] ?? '',
        partyInfo: json['partyInfo'],
        terms: json['terms'],
        agreedValue: (json['agreedValue'] as num?)?.toDouble() ?? 0.0,
        documentUrl: json['documentUrl'],
        documentViewUrl: json['documentViewUrl'],
        otpExpiresAt: json['otpExpiresAt'] != null
            ? DateTime.parse(json['otpExpiresAt'])
            : null,
        confirmedAt: json['confirmedAt'] != null
            ? DateTime.parse(json['confirmedAt'])
            : null,
        confirmedBy: json['confirmedBy']?.toString(),
        status: json['status'] ?? '',
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );
}

class DesignResponse {
  final String id;
  final String projectWorkingId;
  final String title;
  final double version;
  final String type;
  final String? reason;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DesignImageResponse> images;

  DesignResponse({
    required this.id,
    required this.projectWorkingId,
    required this.title,
    required this.version,
    required this.type,
    this.reason,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
  });

  factory DesignResponse.fromJson(Map<String, dynamic> json) => DesignResponse(
    id: json['id']?.toString() ?? '',
    projectWorkingId: json['projectWorkingId']?.toString() ?? '',
    title: json['title'] ?? '',
    version: (json['version'] as num?)?.toDouble() ?? 0.0,
    type: json['type'] ?? '',
    reason: json['reason'],
    status: json['status'] ?? '',
    createdBy: json['createdBy']?.toString() ?? '',
    createdAt: _parseDate(json['createdAt']),
    updatedAt: _parseDate(json['updatedAt']),
    images:
        (json['images'] as List?)
            ?.map((e) => DesignImageResponse.fromJson(e))
            .toList() ??
        [],
  );
}

class DesignImageResponse {
  final String id;
  final String designId;
  final String imageUrl;
  final String viewUrl;
  final String? caption;
  final String uploadedBy;
  final DateTime createdAt;

  DesignImageResponse({
    required this.id,
    required this.designId,
    required this.imageUrl,
    required this.viewUrl,
    this.caption,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory DesignImageResponse.fromJson(Map<String, dynamic> json) =>
      DesignImageResponse(
        id: json['id']?.toString() ?? '',
        designId: json['designId']?.toString() ?? '',
        imageUrl: json['imageUrl'] ?? '',
        viewUrl: json['viewUrl'] ?? '',
        caption: json['caption'],
        uploadedBy: json['uploadedBy']?.toString() ?? '',
        createdAt: _parseDate(json['createdAt']),
      );
}

class ConstructionItemResponse {
  final String id;
  final String projectWorkingId;
  final String? parentId;
  final String name;
  final String? description;
  final String? category;
  final DateTime? estimateAt;
  final DateTime? actualAt;
  final String status;

  /// Whether a payment batch covering this milestone has been confirmed by the
  /// provider. Maintained server-side from `payment_batches`; read-only here.
  ///
  /// Defaults to false rather than being nullable: an older response that omits
  /// the field means "no confirmed payment", which is exactly false.
  final bool isPaid;

  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConstructionItemResponse({
    required this.id,
    required this.projectWorkingId,
    this.parentId,
    required this.name,
    this.description,
    this.category,
    this.estimateAt,
    this.actualAt,
    required this.status,
    this.isPaid = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConstructionItemResponse.fromJson(Map<String, dynamic> json) =>
      ConstructionItemResponse(
        id: json['id']?.toString() ?? '',
        projectWorkingId: json['projectWorkingId']?.toString() ?? '',
        parentId: json['parentId']?.toString() ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        category: json['category'],
        estimateAt: json['estimateAt'] != null
            ? DateTime.parse(json['estimateAt'])
            : null,
        actualAt: json['actualAt'] != null
            ? DateTime.parse(json['actualAt'])
            : null,
        status: json['status'] ?? '',
        isPaid: json['isPaid'] == true,
        createdBy: json['createdBy']?.toString() ?? '',
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );
}

class ConstructionTaskResponse {
  final String id;
  final String constructionItemId;
  final String name;
  final String? description;
  final String? imageUrl;
  final DateTime? estimateAt;
  final DateTime? actualAt;
  final String? reason;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConstructionTaskResponse({
    required this.id,
    required this.constructionItemId,
    required this.name,
    this.description,
    this.imageUrl,
    this.estimateAt,
    this.actualAt,
    this.reason,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConstructionTaskResponse.fromJson(Map<String, dynamic> json) =>
      ConstructionTaskResponse(
        id: json['id']?.toString() ?? '',
        constructionItemId: json['constructionItemId']?.toString() ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        imageUrl: json['imageUrl'],
        estimateAt: json['estimateAt'] != null
            ? DateTime.parse(json['estimateAt'])
            : null,
        actualAt: json['actualAt'] != null
            ? DateTime.parse(json['actualAt'])
            : null,
        reason: json['reason'],
        status: json['status'] ?? '',
        createdBy: json['createdBy']?.toString() ?? '',
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );
}

class ReviewResponse {
  final String id;
  final String projectWorkingId;
  final String projectShopOwnerId;
  final String serviceProviderProfileId;
  final double overallRating;
  final String? comment;
  final List<ReviewScore> scores;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewResponse({
    required this.id,
    required this.projectWorkingId,
    required this.projectShopOwnerId,
    required this.serviceProviderProfileId,
    required this.overallRating,
    this.comment,
    this.scores = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) => ReviewResponse(
    id: json['id']?.toString() ?? '',
    projectWorkingId: json['projectWorkingId']?.toString() ?? '',
    projectShopOwnerId: json['projectShopOwnerId']?.toString() ?? '',
    serviceProviderProfileId: json['serviceProviderProfileId']?.toString() ?? '',
    overallRating: (json['overallRating'] as num?)?.toDouble() ?? 0.0,
    comment: json['comment'],
    scores:
        (json['scores'] as List?)
            ?.map((e) => ReviewScore.fromJson(e))
            .toList() ??
        [],
    createdAt: _parseDate(json['createdAt']),
    updatedAt: _parseDate(json['updatedAt']),
  );
}

class ReviewScore {
  final String id;
  final String dimension;
  final double score;

  ReviewScore({required this.id, required this.dimension, required this.score});

  factory ReviewScore.fromJson(Map<String, dynamic> json) => ReviewScore(
    id: json['id']?.toString() ?? '',
    dimension: json['dimension'] ?? '',
    score: (json['score'] as num?)?.toDouble() ?? 0.0,
  );
}

class ProviderReviewSummary {
  final String serviceProviderProfileId;
  final int reviewCount;
  final double averageRating;
  final Map<String, double> dimensionAverages;

  ProviderReviewSummary({
    required this.serviceProviderProfileId,
    required this.reviewCount,
    required this.averageRating,
    this.dimensionAverages = const {},
  });

  factory ProviderReviewSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['dimensionAverages'];
    final dimensions = <String, double>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        dimensions[key.toString()] = (value as num).toDouble();
      });
    }
    return ProviderReviewSummary(
      serviceProviderProfileId: json['serviceProviderProfileId']?.toString() ?? '',
      reviewCount: json['reviewCount'] ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      dimensionAverages: dimensions,
    );
  }
}

class PostResponse {
  final String id;
  final String projectShopOwnerId;
  final String? projectName;
  final String? projectAddress;
  final double? projectBudget;
  final double? projectAreaM2;
  final String serviceKind;
  final String title;
  final String description;
  final String status;
  final DateTime? submissionDeadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Bridge getters for backward compatibility with UI components (like MarketplacePage)
  String get location => projectAddress ?? 'Remote';
  String get style => serviceKind;
  String get budgetTier =>
      projectBudget != null ? '${projectBudget!.toStringAsFixed(0)} VND' : 'TBD';
  String get expectedStart => submissionDeadline != null
      ? submissionDeadline!.toString().substring(0, 10)
      : '';
  List<String> get requirements => [serviceKind];

  PostResponse({
    required this.id,
    required this.projectShopOwnerId,
    this.projectName,
    this.projectAddress,
    this.projectBudget,
    this.projectAreaM2,
    required this.serviceKind,
    required this.title,
    required this.description,
    required this.status,
    this.submissionDeadline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostResponse.fromJson(Map<String, dynamic> json) => PostResponse(
    id: json['id']?.toString() ?? '',
    projectShopOwnerId: json['projectShopOwnerId']?.toString() ?? '',
    projectName: json['projectName'],
    projectAddress: json['projectAddress'],
    projectBudget: (json['projectBudget'] as num?)?.toDouble(),
    projectAreaM2: (json['projectAreaM2'] as num?)?.toDouble(),
    serviceKind: json['serviceKind'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    status: json['status'] ?? '',
    submissionDeadline: json['submissionDeadline'] != null
        ? DateTime.parse(json['submissionDeadline'])
        : null,
    createdAt: _parseDate(json['createdAt']),
    updatedAt: _parseDate(json['updatedAt']),
  );
}

class NotificationResponse {
  final String id;
  final String accountId;
  final String type;
  final String title;
  final String content;
  final String? referenceType;
  final String? referenceId;
  bool isRead;
  final DateTime? emailSentAt;
  final DateTime createdAt;

  NotificationResponse({
    required this.id,
    required this.accountId,
    required this.type,
    required this.title,
    required this.content,
    this.referenceType,
    this.referenceId,
    required this.isRead,
    this.emailSentAt,
    required this.createdAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      NotificationResponse(
        id: json['id']?.toString() ?? '',
        accountId: json['accountId']?.toString() ?? '',
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        referenceType: json['referenceType'],
        referenceId: json['referenceId']?.toString() ?? '',
        isRead: json['isRead'] ?? false,
        emailSentAt: json['emailSentAt'] != null
            ? DateTime.parse(json['emailSentAt'])
            : null,
        createdAt: _parseDate(json['createdAt']),
      );
}

// ── Comments ────────────────────────────────────────────────────────────────

/// A comment on a design deliverable or construction item. Both the project
/// owner and the engaged provider can post to the same thread.
class CommentResponse {
  final String id;
  final String targetType;
  final String targetId;
  final String body;
  final String? createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommentResponse({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.body,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) =>
      CommentResponse(
        id: json['id']?.toString() ?? '',
        targetType: json['targetType']?.toString() ?? '',
        targetId: json['targetId']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdBy: json['createdBy']?.toString(),
        createdByName: json['createdByName']?.toString(),
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
