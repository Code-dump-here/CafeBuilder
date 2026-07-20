import '../models/responses/api_responses.dart';
import 'api_client.dart';

class ContractService {
  static Future<ContractResponse> createContract({
    required int projectWorkingId,
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
    int id, {
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

  static Future<ContractResponse> sendOtp(int id) async {
    final response = await ApiClient.authPost('/contracts/$id/send-otp', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ContractResponse.fromJson(body);
  }

  static Future<ContractResponse> confirmOtp(
    int id, {
    required String otpCode,
    required int confirmedBy,
  }) async {
    final response = await ApiClient.authPost('/contracts/$id/confirm-otp', {
      'otpCode': otpCode,
      'confirmedBy': confirmedBy,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ContractResponse.fromJson(body);
  }

  static Future<ContractResponse> cancelContract(int id) async {
    final response = await ApiClient.authPost('/contracts/$id/cancel', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ContractResponse.fromJson(body);
  }

  static Future<PaginationResponse<ContractResponse>> getContracts({
    int pageNumber = 1,
    int pageSize = 10,
    int? projectWorkingId,
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

  static Future<ContractResponse> getContract(int id) async {
    final response = await ApiClient.authGet('/contracts/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ContractResponse.fromJson(body);
  }
}
