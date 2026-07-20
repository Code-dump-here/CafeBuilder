import 'dart:developer' as dev;
import '../models/requests/service_provider_requests.dart';
import '../models/responses/api_responses.dart';
import 'api_client.dart';

class ServiceProviderService {
  static const _placeholderImages = [
    'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600',
    'https://images.unsplash.com/photo-1498804103079-a6351b050096?auto=format&fit=crop&q=80&w=600',
    'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&q=80&w=600',
    'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&q=80&w=600',
    'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&q=80&w=600',
  ];

  static String imageFor(int providerId, int index) =>
      _placeholderImages[(providerId + index) % _placeholderImages.length];

  static String typeLabel(ServiceProviderResponse provider) {
    if (provider.capability == 'both') return 'DESIGN & BUILD';
    if (provider.providerType == 'company') {
      return provider.capability == 'constructor' ? 'CONSTRUCTION FIRM' : 'DESIGN STUDIO';
    }
    return provider.capability == 'constructor' ? 'CONTRACTOR' : 'INDIVIDUAL DESIGNER';
  }

  static String tierLabel(ServiceProviderResponse provider) {
    if (provider.isVerified) return 'VERIFIED';
    if (provider.avgRating >= 4.5) return 'PREMIUM';
    return 'PARTNER';
  }

  static Future<PaginationResponse<ServiceProviderResponse>> getProviders({
    int pageNumber = 1,
    int pageSize = 10,
    String? capability,
    bool? isVerified,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (capability != null) 'capability': capability,
      if (isVerified != null) 'isVerified': isVerified,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final response = await ApiClient.authGet('/service-provider-profiles', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    if (body['items'] is List) {
      return PaginationResponse.fromJson(body, ServiceProviderResponse.fromJson);
    }
    return ResponseData.fromJson(
      body,
      (d) => PaginationResponse.fromJson(d, ServiceProviderResponse.fromJson),
    ).data!;
  }

  static Future<ServiceProviderResponse> getProvider(int id) async {
    final response = await ApiClient.authGet('/service-provider-profiles/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    if (body['id'] != null) {
      return ServiceProviderResponse.fromJson(body);
    }
    return ResponseData.fromJson(body, (d) => ServiceProviderResponse.fromJson(d)).data!;
  }

  static Future<ServiceProviderResponse> createProvider(
      CreateServiceProviderRequest request) async {
    final response = await ApiClient.authPost('/service-provider-profiles', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => ServiceProviderResponse.fromJson(d)).data!;
  }

  static Future<ServiceProviderResponse> updateProvider(
      int id, UpdateServiceProviderRequest request) async {
    final response = await ApiClient.authPut('/service-provider-profiles/$id', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => ServiceProviderResponse.fromJson(d)).data!;
  }

  static Future<void> deleteProvider(int id) async {
    final response = await ApiClient.authDelete('/service-provider-profiles/$id');
    ApiClient.throwIfError(response);
  }
}

class ShopOwnerService {
  /// Projects require the shop_owner PROFILE id (not accountId).
  /// Finds the profile for the logged-in account, creating a minimal one on
  /// first use, and caches the id in SharedPreferences.
  static Future<int> ensureShopOwnerId() async {
    // 1. Return from cache if available
    final cached = await ApiClient.getShopOwnerId();
    if (cached != null) {
      dev.log('[ShopOwner] Using cached shopOwnerId=$cached', name: 'ShopOwner');
      return cached;
    }

    final accountId = await ApiClient.getAccountId();
    if (accountId == null) {
      throw ApiException(statusCode: 401, message: 'Not logged in');
    }

    dev.log('[ShopOwner] Searching for shopOwner with accountId=$accountId', name: 'ShopOwner');

    // 2. Page through /shop-owners to find by accountId
    var page = 1;
    while (true) {
      final response = await ApiClient.authGet('/shop-owners', {
        'pageNumber': page,
        'pageSize': 100,
      });
      ApiClient.throwIfError(response);
      final result = ResponseData.fromJson(
        ApiClient.parseBody(response),
        (d) => PaginationResponse.fromJson(d, ShopOwnerResponse.fromJson),
      ).data!;
      for (final owner in result.items) {
        if (owner.accountId == accountId) {
          dev.log('[ShopOwner] Found existing shopOwnerId=${owner.id}', name: 'ShopOwner');
          await ApiClient.saveShopOwnerId(owner.id);
          return owner.id;
        }
      }
      if (!result.hasNext) break;
      page++;
    }

    // 3. No profile found — create one automatically
    final email = await ApiClient.getEmail();
    final fullName = email?.split('@').first ?? 'Shop Owner';
    final createReq = CreateShopOwnerRequest(
      accountId: accountId,
      fullName: fullName,
      shopName: 'My Coffee Shop',
      phone: '0901000000', // valid 10-digit VN number
      address: 'Vietnam',
    );
    dev.log('[ShopOwner] Creating new shopOwner: ${createReq.toJson()}', name: 'ShopOwner');
    final created = await createShopOwner(createReq);
    dev.log('[ShopOwner] Created shopOwnerId=${created.id}', name: 'ShopOwner');
    await ApiClient.saveShopOwnerId(created.id);
    return created.id;
  }

  /// Returns the shop-owner profile for the currently logged-in account.
  static ShopOwnerResponse? _cachedCurrentProfile;

  static Future<ShopOwnerResponse> getCurrentShopOwner({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCurrentProfile != null) return _cachedCurrentProfile!;
    final id = await ensureShopOwnerId();
    _cachedCurrentProfile = await getShopOwner(id);
    return _cachedCurrentProfile!;
  }

  static void clearCache() {
    _cachedCurrentProfile = null;
  }

  static String firstNameFrom(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Owner';
    return trimmed.split(RegExp(r'\s+')).last;
  }

  static Future<String> getCurrentOwnerFirstName() async {
    final owner = await getCurrentShopOwner();
    return firstNameFrom(owner.fullName);
  }

  static Future<ShopOwnerResponse> getShopOwner(int id) async {
    final response = await ApiClient.authGet('/shop-owners/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => ShopOwnerResponse.fromJson(d)).data!;
  }

  static Future<ShopOwnerResponse> createShopOwner(CreateShopOwnerRequest request) async {
    final response = await ApiClient.authPost('/shop-owners', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => ShopOwnerResponse.fromJson(d)).data!;
  }

  static Future<ShopOwnerResponse> updateShopOwner(
      int id, UpdateShopOwnerRequest request) async {
    final response = await ApiClient.authPut('/shop-owners/$id', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => ShopOwnerResponse.fromJson(d)).data!;
  }
}
