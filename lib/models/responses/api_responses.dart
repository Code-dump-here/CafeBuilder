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
      data: fromJsonT == null
          ? null
          : fromJsonT(json['data'] ?? json),
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
  final int accountId;
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
        accessToken: json['accessToken'] ?? json['AccessToken'],
        refreshToken: json['refreshToken'] ?? json['RefreshToken'],
        accountId: (json['accountId'] ?? json['AccountId'] as num).toInt(),
        email: json['email'] ?? json['Email'],
        role: json['role'] ?? json['Role'],
      );
}

class AccountResponse {
  final int id;
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

  factory AccountResponse.fromJson(Map<String, dynamic> json) => AccountResponse(
        id: json['id'],
        email: json['email'],
        phone: json['phone'],
        role: json['role'],
        status: json['status'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class ProjectOwnerResponse {
  final int id;
  final String fullName;
  final String shopName;
  final String phone;

  ProjectOwnerResponse({
    required this.id,
    required this.fullName,
    required this.shopName,
    required this.phone,
  });

  factory ProjectOwnerResponse.fromJson(Map<String, dynamic> json) => ProjectOwnerResponse(
        id: json['id'],
        fullName: json['fullName'] ?? '',
        shopName: json['shopName'] ?? '',
        phone: json['phone'] ?? '',
      );
}

class OpenPostResponse {
  final int id;
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

  factory OpenPostResponse.fromJson(Map<String, dynamic> json) => OpenPostResponse(
        id: json['id'],
        serviceKind: json['serviceKind'] ?? '',
        title: json['title'] ?? '',
        status: json['status'] ?? '',
        submissionDeadline: json['submissionDeadline'] != null ? DateTime.parse(json['submissionDeadline']) : null,
      );
}

class ProjectResponse {
  final int id;
  final int ownerId;
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

  factory ProjectResponse.fromJson(Map<String, dynamic> json) => ProjectResponse(
        id: json['id'],
        ownerId: json['ownerId'],
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        areaM2: (json['areaM2'] as num).toDouble(),
        budget: (json['budget'] as num).toDouble(),
        status: json['status'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        owner: json['owner'] != null ? ProjectOwnerResponse.fromJson(json['owner']) : null,
        openPosts: (json['openPosts'] as List?)?.map((e) => OpenPostResponse.fromJson(e)).toList() ?? [],
        openFor: (json['openFor'] as List?)?.map((e) => e as String).toList() ?? [],
        providers: json['providers'] ?? [],
      );
}

class DesignBriefResponse {
  final int id;
  final int projectId;
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

  factory DesignBriefResponse.fromJson(Map<String, dynamic> json) => DesignBriefResponse(
        id: json['id'],
        projectId: (json['projectShopOwnerId'] ?? json['projectId']) as int,
        targetCustomer: json['targetCustomer'],
        style: json['style'],
        mood: json['mood'],
        seatCount: json['seatCount'],
        timeline: json['timeline'],
        brandNote: json['brandNote'],
        businessModel: json['businessModel'],
        businessGoals: json['businessGoals'],
        operationNote: json['operationNote'],
        createdAt: DateTime.parse(json['createdAt']),
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
  final int id;
  final int briefId;
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
        id: json['id'],
        briefId: json['briefId'] ?? 0,
        conceptSummary: json['conceptSummary'] ?? '',
        payload: json['payload'] ?? '',
        estimatedDesignCost: json['estimatedDesignCost'] != null
            ? (json['estimatedDesignCost'] as num).toDouble()
            : null,
        estimatedConstructionCost: json['estimatedConstructionCost'] != null
            ? (json['estimatedConstructionCost'] as num).toDouble()
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        jobId: json['jobId'],
        state: json['state'],
        lastError: json['lastError'],
        planConceptName: json['planConceptName'],
        planSummary: json['planSummary'],
        layoutWidth: (json['layoutWidth'] as num?)?.toDouble(),
        layoutHeight: (json['layoutHeight'] as num?)?.toDouble(),
        layoutUnit: json['layoutUnit'],
        layoutZones: (json['layoutZones'] as List?)
                ?.map((e) => AiLayoutZone.fromJson(e))
                .toList() ??
            [],
        fitoutMinVnd: (json['fitoutMinVnd'] as num?)?.toDouble(),
        fitoutMaxVnd: (json['fitoutMaxVnd'] as num?)?.toDouble(),
        equipmentMinVnd: (json['equipmentMinVnd'] as num?)?.toDouble(),
        equipmentMaxVnd: (json['equipmentMaxVnd'] as num?)?.toDouble(),
        contingencyPercent: (json['contingencyPercent'] as num?)?.toDouble(),
        costNotes: json['costNotes'],
        recommendations: (json['recommendations'] as List?)
                ?.map((e) => AiRecommendationItem.fromJson(e))
                .toList() ??
            [],
        riskNotes: (json['riskNotes'] as List?)
                ?.map((e) => AiRiskNote.fromJson(e))
                .toList() ??
            [],
        customerFlow: (json['customerFlow'] as List?)
                ?.map((e) => AiCustomerFlowStage.fromJson(e))
                .toList() ??
            [],
        imageView: json['imageView'],
        imageArtifactUrl: json['imageArtifactUrl'],
        seatCapacityRecommendation: (json['seatCapacityRecommendation'] as num?)?.toInt(),
      );
}

class ServiceProviderResponse {
  final int id;
  final int accountId;
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
        id: json['id'],
        accountId: json['accountId'],
        displayName: json['displayName'],
        providerType: json['providerType'],
        capability: json['capability'],
        bio: json['bio'],
        companyTaxCode: json['companyTaxCode'],
        yearsExperience: json['yearsExperience'],
        portfolioHeadline: json['portfolioHeadline'],
        isVerified: json['isVerified'] ?? false,
        avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class ShopOwnerResponse {
  final int id;
  final int accountId;
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

  factory ShopOwnerResponse.fromJson(Map<String, dynamic> json) => ShopOwnerResponse(
        id: json['id'],
        accountId: json['accountId'],
        fullName: json['fullName'],
        shopName: json['shopName'],
        phone: json['phone'],
        address: json['address'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class ApplyResponse {
  final int id;
  final int postId;
  final String postTitle;
  final int projectShopOwnerId;
  final int serviceProviderProfileId;
  final String providerDisplayName;
  final String proposal;
  final int estimatedDurationDays;
  final String status;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApplyResponse({
    required this.id,
    required this.postId,
    required this.postTitle,
    required this.projectShopOwnerId,
    required this.serviceProviderProfileId,
    required this.providerDisplayName,
    required this.proposal,
    required this.estimatedDurationDays,
    required this.status,
    this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApplyResponse.fromJson(Map<String, dynamic> json) => ApplyResponse(
        id: json['id'],
        postId: json['postId'],
        postTitle: json['postTitle'] ?? '',
        projectShopOwnerId: json['projectShopOwnerId'],
        serviceProviderProfileId: json['serviceProviderProfileId'],
        providerDisplayName: json['providerDisplayName'] ?? '',
        proposal: json['proposal'] ?? '',
        estimatedDurationDays: json['estimatedDurationDays'] ?? 0,
        status: json['status'] ?? '',
        submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

class ProjectWorkingResponse {
  final int id;
  final int projectShopOwnerId;
  final String projectName;
  final int serviceProviderProfileId;
  final String providerDisplayName;
  final int? applyId;
  final String contractType;
  final String status;
  final String? requestMessage;
  final DateTime? startedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

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
  });

  factory ProjectWorkingResponse.fromJson(Map<String, dynamic> json) => ProjectWorkingResponse(
        id: json['id'],
        projectShopOwnerId: json['projectShopOwnerId'],
        projectName: json['projectName'] ?? '',
        serviceProviderProfileId: json['serviceProviderProfileId'],
        providerDisplayName: json['providerDisplayName'] ?? '',
        applyId: json['applyId'],
        contractType: json['contractType'] ?? '',
        status: json['status'] ?? '',
        requestMessage: json['requestMessage'],
        startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

class EngagementOverviewResponse {
  final int projectWorkingId;
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

  factory EngagementOverviewResponse.fromJson(Map<String, dynamic> json) => EngagementOverviewResponse(
        projectWorkingId: json['projectWorkingId'] ?? 0,
        contractType: json['contractType'] ?? '',
        status: json['status'] ?? '',
        projectShopOwner: json['projectShopOwner'] != null
            ? ProjectResponse.fromJson(json['projectShopOwner'])
            : null,
        brief: json['brief'] != null ? DesignBriefResponse.fromJson(json['brief']) : null,
        aiRecommendations: (json['aiRecommendations'] as List?)
                ?.map((e) => AiRecommendationResponse.fromJson(e))
                .toList() ??
            [],
        approvedDesigns: (json['approvedDesigns'] as List?)
                ?.map((e) => DesignResponse.fromJson(e))
                .toList() ??
            [],
      );
}

class SurveyResponse {
  final int id;
  final int projectWorkingId;
  final double version;
  final String? conditionNote;
  final String? reportUrl;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  SurveyResponse({
    required this.id,
    required this.projectWorkingId,
    required this.version,
    this.conditionNote,
    this.reportUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SurveyResponse.fromJson(Map<String, dynamic> json) => SurveyResponse(
        id: json['id'],
        projectWorkingId: json['projectWorkingId'],
        version: (json['version'] as num?)?.toDouble() ?? 0.0,
        conditionNote: json['conditionNote'],
        reportUrl: json['reportUrl'],
        createdBy: json['createdBy'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

class ContractResponse {
  final int id;
  final int projectWorkingId;
  final String title;
  final String? partyInfo;
  final String? terms;
  final double agreedValue;
  final String? documentUrl;
  final DateTime? otpExpiresAt;
  final DateTime? confirmedAt;
  final int? confirmedBy;
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
    this.otpExpiresAt,
    this.confirmedAt,
    this.confirmedBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContractResponse.fromJson(Map<String, dynamic> json) => ContractResponse(
        id: json['id'],
        projectWorkingId: json['projectWorkingId'],
        title: json['title'] ?? '',
        partyInfo: json['partyInfo'],
        terms: json['terms'],
        agreedValue: (json['agreedValue'] as num?)?.toDouble() ?? 0.0,
        documentUrl: json['documentUrl'],
        otpExpiresAt: json['otpExpiresAt'] != null ? DateTime.parse(json['otpExpiresAt']) : null,
        confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt']) : null,
        confirmedBy: json['confirmedBy'],
        status: json['status'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

class DesignResponse {
  final int id;
  final int projectWorkingId;
  final String title;
  final double version;
  final String type;
  final String? reason;
  final String status;
  final int createdBy;
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
        id: json['id'],
        projectWorkingId: json['projectWorkingId'],
        title: json['title'] ?? '',
        version: (json['version'] as num?)?.toDouble() ?? 0.0,
        type: json['type'] ?? '',
        reason: json['reason'],
        status: json['status'] ?? '',
        createdBy: json['createdBy'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        images: (json['images'] as List?)
                ?.map((e) => DesignImageResponse.fromJson(e))
                .toList() ??
            [],
      );
}

class DesignImageResponse {
  final int id;
  final int designId;
  final String imageUrl;
  final String viewUrl;
  final String? caption;
  final int uploadedBy;
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

  factory DesignImageResponse.fromJson(Map<String, dynamic> json) => DesignImageResponse(
        id: json['id'],
        designId: json['designId'],
        imageUrl: json['imageUrl'] ?? '',
        viewUrl: json['viewUrl'] ?? '',
        caption: json['caption'],
        uploadedBy: json['uploadedBy'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class ConstructionItemResponse {
  final int id;
  final int projectWorkingId;
  final int? parentId;
  final String name;
  final String? description;
  final String? category;
  final DateTime? estimateAt;
  final DateTime? actualAt;
  final String status;
  final int createdBy;
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
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConstructionItemResponse.fromJson(Map<String, dynamic> json) => ConstructionItemResponse(
        id: json['id'],
        projectWorkingId: json['projectWorkingId'],
        parentId: json['parentId'],
        name: json['name'] ?? '',
        description: json['description'],
        category: json['category'],
        estimateAt: json['estimateAt'] != null ? DateTime.parse(json['estimateAt']) : null,
        actualAt: json['actualAt'] != null ? DateTime.parse(json['actualAt']) : null,
        status: json['status'] ?? '',
        createdBy: json['createdBy'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

class ConstructionTaskResponse {
  final int id;
  final int constructionItemId;
  final String name;
  final String? description;
  final String? imageUrl;
  final DateTime? estimateAt;
  final DateTime? actualAt;
  final String? reason;
  final String status;
  final int createdBy;
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

  factory ConstructionTaskResponse.fromJson(Map<String, dynamic> json) => ConstructionTaskResponse(
        id: json['id'],
        constructionItemId: json['constructionItemId'],
        name: json['name'] ?? '',
        description: json['description'],
        imageUrl: json['imageUrl'],
        estimateAt: json['estimateAt'] != null ? DateTime.parse(json['estimateAt']) : null,
        actualAt: json['actualAt'] != null ? DateTime.parse(json['actualAt']) : null,
        reason: json['reason'],
        status: json['status'] ?? '',
        createdBy: json['createdBy'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

class ReviewResponse {
  final int id;
  final int projectWorkingId;
  final int projectShopOwnerId;
  final int serviceProviderProfileId;
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
        id: json['id'],
        projectWorkingId: json['projectWorkingId'],
        projectShopOwnerId: json['projectShopOwnerId'],
        serviceProviderProfileId: json['serviceProviderProfileId'],
        overallRating: (json['overallRating'] as num?)?.toDouble() ?? 0.0,
        comment: json['comment'],
        scores: (json['scores'] as List?)
                ?.map((e) => ReviewScore.fromJson(e))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

class ReviewScore {
  final int id;
  final String dimension;
  final double score;

  ReviewScore({
    required this.id,
    required this.dimension,
    required this.score,
  });

  factory ReviewScore.fromJson(Map<String, dynamic> json) => ReviewScore(
        id: json['id'],
        dimension: json['dimension'] ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
      );
}

class ProviderReviewSummary {
  final int serviceProviderProfileId;
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
      serviceProviderProfileId: json['serviceProviderProfileId'],
      reviewCount: json['reviewCount'] ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      dimensionAverages: dimensions,
    );
  }
}

class PostResponse {
  final int id;
  final int projectShopOwnerId;
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
  String get budgetTier => projectBudget != null ? '\$${projectBudget!.toStringAsFixed(0)}' : '\$TBD';
  String get expectedStart => submissionDeadline != null ? submissionDeadline!.toString().substring(0, 10) : '';
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
        id: json['id'],
        projectShopOwnerId: json['projectShopOwnerId'],
        projectName: json['projectName'],
        projectAddress: json['projectAddress'],
        projectBudget: (json['projectBudget'] as num?)?.toDouble(),
        projectAreaM2: (json['projectAreaM2'] as num?)?.toDouble(),
        serviceKind: json['serviceKind'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        status: json['status'] ?? '',
        submissionDeadline: json['submissionDeadline'] != null ? DateTime.parse(json['submissionDeadline']) : null,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}
