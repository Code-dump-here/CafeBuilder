import '../models/responses/api_responses.dart';
import 'api_client.dart';

class ChatMessageResponse {
  final int id;
  final int conversationId;
  final int senderId;
  final String body;
  final List<String> fileUrls;
  final DateTime createdAt;

  ChatMessageResponse({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.fileUrls,
    required this.createdAt,
  });

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) {
    return ChatMessageResponse(
      id: json['id'] as int? ?? 0,
      conversationId: json['conversationId'] as int? ?? 0,
      senderId: json['senderId'] as int? ?? 0,
      body: json['body'] as String? ?? '',
      fileUrls: (json['fileUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class ChatService {
  static Future<PaginationResponse<ChatMessageResponse>> getMessages(
    int conversationId, {
    int pageNumber = 1,
    int pageSize = 100,
  }) async {
    final response = await ApiClient.authGet('/chat/messages/$conversationId', {
      'pageNumber': pageNumber,
      'limit': pageSize,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    
    // Check if the backend returns a flat list or a paginated format
    if (body.containsKey('items')) {
      return PaginationResponse.fromJson(body, ChatMessageResponse.fromJson);
    } else {
      // If it's a flat list wrapped in an object or just return a dummy pagination
      final list = (body['data'] as List?) ?? [];
      final messages = list.map((e) => ChatMessageResponse.fromJson(e)).toList();
      return PaginationResponse(
        items: messages,
        pageNumber: 1,
        pageSize: pageSize,
        totalItems: messages.length,
        totalPages: 1,
        hasPrevious: false,
        hasNext: false,
      );
    }
  }

  static Future<ChatMessageResponse> postMessage(
    int conversationId,
    String bodyText, {
    List<String>? filePaths,
  }) async {
    final response = await ApiClient.authMultipart(
      '/chat/messages/$conversationId',
      {'body': bodyText},
      filePaths: filePaths,
      fileField: 'files',
    );
    ApiClient.throwIfError(response);
    final responseBody = ApiClient.parseBody(response);
    return ChatMessageResponse.fromJson(responseBody['data'] ?? responseBody);
  }
}
