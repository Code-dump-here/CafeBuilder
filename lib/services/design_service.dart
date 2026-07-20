import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/responses/api_responses.dart';
import 'api_client.dart';


class DesignService {
  static Future<DesignResponse> createDesign({
    required int projectWorkingId,
    required String title,
    required String type,
    required int createdBy,
  }) async {
    final response = await ApiClient.authPost('/designs', {
      'projectWorkingId': projectWorkingId,
      'title': title,
      'type': type,
      'createdBy': createdBy,
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
    required int uploadedBy,
  }) async {
    final token = await ApiClient.getAccessToken();
    final uri = Uri.parse('${ApiClient.baseUrl}/designs/$designId/files');

    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final stream = http.ByteStream(file.openRead());
    final length = await file.length();
    final filename = file.path.split('/').last;

    // Detect media/file type
    final fileExtension = filename.split('.').last.toLowerCase();
    String mimeType;
    if (fileExtension == 'pdf') {
      mimeType = 'application/pdf';
    } else if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
      mimeType = 'image/jpeg';
    } else if (fileExtension == 'png') {
      mimeType = 'image/png';
    } else {
      mimeType = 'application/octet-stream';
    }

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      await file.readAsBytes(),
      filename: filename,
    );
    request.files.add(multipartFile);

    if (caption != null) {
      request.fields['caption'] = caption;
    }
    request.fields['uploadedBy'] = uploadedBy.toString();

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

  static Future<DesignResponse> getDesign(int id) async {
    final response = await ApiClient.authGet('/designs/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignResponse.fromJson(body);
  }
}
