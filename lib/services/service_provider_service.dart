import '../models/requests/service_provider_requests.dart';
import '../models/responses/api_responses.dart';
import 'api_client.dart';

class ServiceProviderService {
  static Future<PaginationResponse<ServiceProviderResponse>> getProviders({
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final response = await ApiClient.authGet('/service-providers', {
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
    final response = await ApiClient.authGet('/service-providers/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => ServiceProviderResponse.fromJson(d)).data!;
  }

  static Future<ServiceProviderResponse> createProvider(
      CreateServiceProviderRequest request) async {
    final response = await ApiClient.authPost('/service-providers', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => ServiceProviderResponse.fromJson(d)).data!;
  }

  static Future<ServiceProviderResponse> updateProvider(
      int id, UpdateServiceProviderRequest request) async {
    final response = await ApiClient.authPut('/service-providers/$id', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => ServiceProviderResponse.fromJson(d)).data!;
  }

  static Future<void> deleteProvider(int id) async {
    final response = await ApiClient.authDelete('/service-providers/$id');
    ApiClient.throwIfError(response);
  }
}

class ShopOwnerService {
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
