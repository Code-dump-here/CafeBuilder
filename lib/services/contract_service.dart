import '../models/responses/api_responses.dart';
import 'api_client.dart';

class ContractService {
  static Future<ContractResponse> createContract({
    required String projectWorkingId,
    required String title,
    String? partyInfo,
    String? terms,
    required double agreedValue,
    String? documentUrl,
  }) async {
    final response = await ApiClient.authPost('/contracts', {
      'projectWorkingId': projectWorkingId,
      'title': title,
      if (partyInfo != null) 'partyInfo': partyInfo,
      if (terms != null) 'terms': terms,
      'agreedValue': agreedValue,
      if (documentUrl != null) 'documentUrl': documentUrl,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ContractResponse.fromJson(body);
  }

  static Future<ContractResponse> updateContract(
    String id, {
    String? title,
    String? partyInfo,
    String? terms,
    double? agreedValue,
    String? documentUrl,
  }) async {
    final response = await ApiClient.authPut('/contracts/$id', {
      if (title != null) 'title': title,
      if (partyInfo != null) 'partyInfo': partyInfo,
      if (terms != null) 'terms': terms,
      if (agreedValue != null) 'agreedValue': agreedValue,
      if (documentUrl != null) 'documentUrl': documentUrl,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ContractResponse.fromJson(body);
  }

  static Future<ContractResponse> sendOtp(String id) async {
    final response = await ApiClient.authPost('/contracts/$id/send-otp', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ContractResponse.fromJson(body);
  }

  static Future<ContractResponse> confirmOtp(
    String id, {
    required String otpCode,
  }) async {
    final response = await ApiClient.authPost('/contracts/$id/confirm-otp', {
      'otpCode': otpCode,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ContractResponse.fromJson(body);
  }

  static Future<ContractResponse> cancelContract(String id) async {
    final response = await ApiClient.authPost('/contracts/$id/cancel', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ContractResponse.fromJson(body);
  }

  static Future<PaginationResponse<ContractResponse>> getContracts({
    int pageNumber = 1,
    int pageSize = 10,
    String? projectWorkingId,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (projectWorkingId != null) 'projectWorkingId': projectWorkingId,
    };
    final response = await ApiClient.authGet('/contracts', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, ContractResponse.fromJson);
  }

  static Future<ContractResponse> getContract(String id) async {
    final response = await ApiClient.authGet('/contracts/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ContractResponse.fromJson(body);
  }

  /// A cancelled contract is dead — it can't be signed, it unlocks nothing and
  /// it can't return to any other status. Listing it beside live contracts only
  /// invites the owner to open something they can't act on, so every
  /// owner-facing list leaves it out. The rule lives here so those lists agree.
  static bool isVisibleToOwner(ContractResponse c) =>
      c.status.toLowerCase() != 'cancelled';

  /// [getContracts] filtered to what the owner should actually see.
  static List<ContractResponse> ownerVisible(Iterable<ContractResponse> contracts) =>
      contracts.where(isVisibleToOwner).toList();
}
