class CreateServiceProviderRequest {
  final int accountId;
  final String displayName;
  final String providerType;
  final String capability;
  final String? bio;
  final String? companyTaxCode;
  final int? yearsExperience;
  final String? portfolioHeadline;

  CreateServiceProviderRequest({
    required this.accountId,
    required this.displayName,
    required this.providerType,
    required this.capability,
    this.bio,
    this.companyTaxCode,
    this.yearsExperience,
    this.portfolioHeadline,
  });

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'displayName': displayName,
        'providerType': providerType,
        'capability': capability,
        if (bio != null) 'bio': bio,
        if (companyTaxCode != null) 'companyTaxCode': companyTaxCode,
        if (yearsExperience != null) 'yearsExperience': yearsExperience,
        if (portfolioHeadline != null) 'portfolioHeadline': portfolioHeadline,
      };
}

class UpdateServiceProviderRequest {
  final String? displayName;
  final String? providerType;
  final String? capability;
  final String? bio;
  final String? companyTaxCode;
  final int? yearsExperience;
  final String? portfolioHeadline;
  final bool? isVerified;

  UpdateServiceProviderRequest({
    this.displayName,
    this.providerType,
    this.capability,
    this.bio,
    this.companyTaxCode,
    this.yearsExperience,
    this.portfolioHeadline,
    this.isVerified,
  });

  Map<String, dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName,
        if (providerType != null) 'providerType': providerType,
        if (capability != null) 'capability': capability,
        if (bio != null) 'bio': bio,
        if (companyTaxCode != null) 'companyTaxCode': companyTaxCode,
        if (yearsExperience != null) 'yearsExperience': yearsExperience,
        if (portfolioHeadline != null) 'portfolioHeadline': portfolioHeadline,
        if (isVerified != null) 'isVerified': isVerified,
      };
}

class CreateShopOwnerRequest {
  final int accountId;
  final String fullName;
  final String shopName;
  final String phone;
  final String address;

  CreateShopOwnerRequest({
    required this.accountId,
    required this.fullName,
    required this.shopName,
    required this.phone,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'fullName': fullName,
        'shopName': shopName,
        'phone': phone,
        'address': address,
      };
}

class UpdateShopOwnerRequest {
  final String? fullName;
  final String? shopName;
  final String? phone;
  final String? address;

  UpdateShopOwnerRequest({this.fullName, this.shopName, this.phone, this.address});

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'fullName': fullName,
        if (shopName != null) 'shopName': shopName,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      };
}
