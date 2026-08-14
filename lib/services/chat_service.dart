import 'dart:convert';
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
    final attachments = (json['attachments'] as List<dynamic>?) ?? [];
    return ChatMessageResponse(
      id: json['id'] as int? ?? 0,
      conversationId: json['conversationId'] as int? ?? 0,
      senderId: json['senderId'] as int? ?? 0,
      body: json['body'] as String? ?? '',
      // BE returns Attachments[].viewUrl (public URL) — fall back to the
      // raw objectName (url) if a view URL wasn't resolved.
      fileUrls: attachments
          .map((a) => (a['viewUrl'] ?? a['url'])?.toString())
          .whereType<String>()
          .toList(),
      // BE field is "sentAt", not "createdAt".
      createdAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
    );
  }
}

class ConversationResponse {
  final int id;
  final int projectWorkingId;
  ConversationResponse({required this.id, required this.projectWorkingId});

  factory ConversationResponse.fromJson(Map<String, dynamic> json) =>
      ConversationResponse(
        id: json['id'] as int,
        projectWorkingId: json['projectWorkingId'] as int,
      );
}

class ChatService {
  /// Conversations are their own entity, separate from the engagement
  /// (projectWorkingId). Finds the existing thread for this engagement, or
  /// creates one if none exists yet. Always resolve this before opening a
  /// chat thread — the engagement id is NOT a valid conversationId.
  static Future<int> getOrCreateConversation(int projectWorkingId) async {
    final listResponse = await ApiClient.authGet('/chat/conversations', {
      'projectWorkingId': projectWorkingId,
      'pageSize': 1,
    });
    ApiClient.throwIfError(listResponse);
    final listBody = ApiClient.parseBody(listResponse);
    final existing = PaginationResponse.fromJson(
      listBody,
      ConversationResponse.fromJson,
    );
    if (existing.items.isNotEmpty) return existing.items.first.id;

    final createResponse = await ApiClient.authPost('/chat/conversations', {
      'projectWorkingId': projectWorkingId,
    });
    ApiClient.throwIfError(createResponse);
    final created = ConversationResponse.fromJson(
      ApiClient.parseBody(createResponse),
    );
    return created.id;
  }

  /// Polls for messages in a thread. BE takes conversationId as a query
  /// param and returns a bare JSON array (not the usual paginated wrapper).
  static Future<PaginationResponse<ChatMessageResponse>> getMessages(
    int conversationId, {
    int? sinceId,
    int pageSize = 100,
  }) async {
    final response = await ApiClient.authGet('/chat/messages', {
      'conversationId': conversationId,
      if (sinceId != null) 'sinceId': sinceId,
      'limit': pageSize,
    });
    ApiClient.throwIfError(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    final messages = list
        .map((e) => ChatMessageResponse.fromJson(e as Map<String, dynamic>))
        .toList();
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

  static Future<ChatMessageResponse> postMessage(
    int conversationId,
    String bodyText, {
    List<UploadFile>? files,
  }) async {
    final response = await ApiClient.authMultipart(
      '/chat/messages/$conversationId',
      {'body': bodyText},
      files: files,
      fileField: 'files',
    );
    ApiClient.throwIfError(response);
    final responseBody = ApiClient.parseBody(response);
    return ChatMessageResponse.fromJson(responseBody['data'] ?? responseBody);
  }
}
