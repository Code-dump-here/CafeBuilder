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
  /// first use, and caches the id in prefs.
  static Future<int> ensureShopOwnerId() async {
    final cached = await ApiClient.getShopOwnerId();
    if (cached != null) return cached;

    final accountId = await ApiClient.getAccountId();
    if (accountId == null) {
      throw ApiException(statusCode: 401, message: 'Not logged in');
    }

    // No accountId filter on GET /shop-owners — page through and match.
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
          await ApiClient.saveShopOwnerId(owner.id);
          return owner.id;
        }
      }
      if (!result.hasNext) break;
      page++;
    }

    // First login without a profile — create a minimal one (TODO: proper profile setup page).
    final prefs = await ApiClient.getEmail();
    final created = await createShopOwner(CreateShopOwnerRequest(
      accountId: accountId,
      fullName: prefs?.split('@').first ?? 'Shop Owner',
      shopName: 'My Coffee Shop',
      phone: '0000000000',
      address: 'Not set',
    ));
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
