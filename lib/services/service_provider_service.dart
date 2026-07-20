import 'dart:developer' as dev;
import '../models/requests/service_provider_requests.dart';
import '../models/responses/api_responses.dart';
import 'api_client.dart';

class ServiceProviderService {
  static Future<PaginationResponse<ServiceProviderResponse>> getProviders({
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final response = await ApiClient.authGet('/service-provider-profiles', {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(
      body,
      (d) => PaginationResponse.fromJson(d, ServiceProviderResponse.fromJson),
    ).data!;
  }

  static Future<ServiceProviderResponse> getProvider(int id) async {
    final response = await ApiClient.authGet('/service-provider-profiles/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
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
