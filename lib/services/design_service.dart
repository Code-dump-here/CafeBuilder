import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/responses/api_responses.dart';
import 'api_client.dart';


class DesignService {
  static Future<DesignResponse> createDesign({
    required int projectWorkingId,
    required String title,
    required String type,
  }) async {
    final response = await ApiClient.authPost('/designs', {
      'projectWorkingId': projectWorkingId,
      'title': title,
      'type': type,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignResponse.fromJson(body);
  }

  static Future<DesignResponse> updateDesign(
    int id, {
    String? title,
    String? type,
  }) async {
    final response = await ApiClient.authPut('/designs/$id', {
      if (title != null) 'title': title,
      if (type != null) 'type': type,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignResponse.fromJson(body);
  }

  static Future<DesignResponse> submitDesign(int id) async {
    final response = await ApiClient.authPost('/designs/$id/submit', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignResponse.fromJson(body);
  }

  static Future<DesignResponse> approveDesign(int id) async {
    final response = await ApiClient.authPost('/designs/$id/approve', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignResponse.fromJson(body);
  }

  static Future<DesignResponse> requestRevision(int id, {required String reason}) async {
    final response = await ApiClient.authPost('/designs/$id/request-revision', {
      'reason': reason,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignResponse.fromJson(body);
  }

  static Future<DesignResponse> startRevision(int id) async {
    final response = await ApiClient.authPost('/designs/$id/start-revision', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignResponse.fromJson(body);
  }

  /// Upload design deliverable file (multipart)
  static Future<DesignImageResponse> uploadDesignFile(
    int designId, {
    required File file,
    String? caption,
  }) async {
    final token = await ApiClient.getAccessToken();
    final uri = Uri.parse('${ApiClient.baseUrl}/designs/$designId/files');

    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final filename = file.path.split('/').last;

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      await file.readAsBytes(),
      filename: filename,
    );
    request.files.add(multipartFile);

    if (caption != null) {
      request.fields['caption'] = caption;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignImageResponse.fromJson(body);
  }

  static Future<void> deleteDesignFile(int designId, int fileId) async {
    final response = await ApiClient.authDelete('/designs/$designId/files/$fileId');
    ApiClient.throwIfError(response);
  }

  static Future<PaginationResponse<DesignResponse>> getDesigns({
    int pageNumber = 1,
    int pageSize = 10,
    int? projectWorkingId,
    String? status,
    String? type,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (projectWorkingId != null) 'projectWorkingId': projectWorkingId,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
    };
    final response = await ApiClient.authGet('/designs', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, DesignResponse.fromJson);
  }

  /// Whether a design is the provider's business only, or something the owner
  /// is meant to see.
  ///
  /// Designs are created at version 0.1 and gain +0.1 each time the provider
  /// starts a revision, so an 'in_progress' design still on its first version
  /// has never been submitted — it's a private draft. Past 0.1 it's rework the
  /// owner explicitly asked for, so it stays visible (read-only) instead of
  /// disappearing the moment they request changes.
  ///
  /// This lives here because every owner-facing screen that lists designs needs
  /// the same rule.
  static bool isVisibleToOwner(DesignResponse d) =>
      d.status != 'in_progress' || d.version > 0.1;

  /// [getDesigns] filtered to what the owner should actually see.
  static List<DesignResponse> ownerVisible(Iterable<DesignResponse> designs) =>
      designs.where(isVisibleToOwner).toList();

  static Future<DesignResponse> getDesign(int id) async {
    final response = await ApiClient.authGet('/designs/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignResponse.fromJson(body);
  }
}
