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
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
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
  });

  factory ProjectResponse.fromJson(Map<String, dynamic> json) => ProjectResponse(
        id: json['id'],
        ownerId: json['ownerId'],
        name: json['name'],
        address: json['address'],
        areaM2: (json['areaM2'] as num).toDouble(),
        budget: (json['budget'] as num).toDouble(),
        status: json['status'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
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
        projectId: json['projectId'],
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

class AiRecommendationResponse {
  final int id;
  final int briefId;
  final String conceptSummary;
  final String payload;
  final double? estimatedDesignCost;
  final double? estimatedConstructionCost;
  final DateTime createdAt;

  AiRecommendationResponse({
    required this.id,
    required this.briefId,
    required this.conceptSummary,
    required this.payload,
    this.estimatedDesignCost,
    this.estimatedConstructionCost,
    required this.createdAt,
  });

  factory AiRecommendationResponse.fromJson(Map<String, dynamic> json) =>
      AiRecommendationResponse(
        id: json['id'],
        briefId: json['briefId'],
        conceptSummary: json['conceptSummary'],
        payload: json['payload'],
        estimatedDesignCost: json['estimatedDesignCost'] != null
            ? (json['estimatedDesignCost'] as num).toDouble()
            : null,
        estimatedConstructionCost: json['estimatedConstructionCost'] != null
            ? (json['estimatedConstructionCost'] as num).toDouble()
            : null,
        createdAt: DateTime.parse(json['createdAt']),
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
