import 'package:http/http.dart' as http;

import '../models/responses/api_responses.dart';
import '../models/responses/quotation_payment_responses.dart';
import 'api_client.dart';

/// Instalment payments owner → provider (review 3).
///
/// The platform holds no money. The owner transfers directly and records it
/// here; the provider checks their own account and confirms or rejects. That
/// reconciliation is the only thing that closes an instalment — and it is the
/// direct answer to the review board's *"có thể không giữ tiền nhưng phải có
/// phần upload minh chứng giao dịch theo từng giai đoạn"*.
///
/// Entirely separate from `PaymentService` (payOS), where real money for
/// platform fees does move through the system.
///
/// There is no create call: instalments are generated from the approved
/// quotation's payment schedule the moment the contract is signed, so nobody
/// can invent one outside what both sides agreed.
class PaymentBatchService {
  /// Instalments of one engagement or one contract.
  ///
  /// Page size is 50 rather than the API default of 10: the header totals are
  /// computed from this list, and a second page would silently understate what
  /// the owner still owes.
  static Future<PaginationResponse<PaymentBatchResponse>> getBatches({
    String? projectWorkingId,
    String? contractId,
    String? status,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (projectWorkingId != null) 'projectWorkingId': projectWorkingId,
      if (contractId != null) 'contractId': contractId,
      if (status != null) 'status': status,
    };
    final response = await ApiClient.authGet('/payment-batches', params);
    ApiClient.throwIfError(response);
    return PaginationResponse.fromJson(
      ApiClient.parseBody(response),
      PaymentBatchResponse.fromJson,
    );
  }

  static Future<PaymentBatchResponse> getById(String id) async {
    final response = await ApiClient.authGet('/payment-batches/$id');
    ApiClient.throwIfError(response);
    return PaymentBatchResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Record a transfer the owner has already made.
  ///
  /// Every field is optional on purpose. With no bank integration the honest
  /// minimum is "I paid this" — demanding a receipt would block a legitimate
  /// payment rather than verify it. Callable more than once: for an instalment
  /// paid in parts, or after the provider rejected the previous proof.
  ///
  /// [imageUrl] is the `objectName` returned by [uploadProofImage], not a
  /// local file path.
  static Future<PaymentBatchResponse> submitProof(
    String id, {
    String? imageUrl,
    double? amount,
    DateTime? transferredAt,
    String? note,
  }) async {
    final response = await ApiClient.authPost('/payment-batches/$id/proofs', {
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (amount != null) 'amount': amount,
      if (transferredAt != null)
        'transferredAt': transferredAt.toUtc().toIso8601String(),
      if (note != null && note.isNotEmpty) 'note': note,
    });
    ApiClient.throwIfError(response);
    return PaymentBatchResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Upload a receipt image and return its storage `objectName`.
  ///
  /// Two steps rather than one multipart call to `/proofs`, because that is
  /// what the API expects: files go through `api/files` and other records
  /// store the key they get back.
  ///
  /// Takes bytes rather than a `File` so the same call works on web, where
  /// browsers expose no filesystem path — the same reason `chat_thread_page`
  /// picks files with `withData: true`.
  static Future<String> uploadProofImage({
    required List<int> bytes,
    required String filename,
  }) async {
    final token = await ApiClient.getAccessToken();
    final uri = Uri.parse('${ApiClient.baseUrl}/files/images');

    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final response = await http.Response.fromStream(await request.send());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return body['objectName']?.toString() ?? body['url']?.toString() ?? '';
  }
}
