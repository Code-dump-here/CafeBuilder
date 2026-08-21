import '../models/responses/api_responses.dart';
import '../models/responses/provider_brand_responses.dart';
import 'api_client.dart';

/// A provider's public brand and past work.
///
/// Read-only here: the provider maintains all of it from their own app. The
/// owner reads it while comparing bids, which is the whole reason it is
/// readable by any signed-in account rather than gated behind an engagement.
class ProviderBrandService {
  static Future<ProviderBrandResponse> getBrand(
    String serviceProviderProfileId,
  ) async {
    final response =
        await ApiClient.authGet('/provider-brands/$serviceProviderProfileId');
    ApiClient.throwIfError(response);
    return ProviderBrandResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Sample projects, featured ones first.
  static Future<PaginationResponse<ProviderPortfolioResponse>> getPortfolios({
    required String serviceProviderProfileId,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final response = await ApiClient.authGet('/provider-portfolios', {
      'serviceProviderProfileId': serviceProviderProfileId,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });
    ApiClient.throwIfError(response);
    return PaginationResponse.fromJson(
      ApiClient.parseBody(response),
      ProviderPortfolioResponse.fromJson,
    );
  }
}
