import 'dart:convert';
import '../models/responses/api_responses.dart';
import 'api_client.dart';

class ChatMessageResponse {
  final String id;
  final String conversationId;
  final String senderId;
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
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
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
  final String id;
  final String projectWorkingId;
  ConversationResponse({required this.id, required this.projectWorkingId});

  factory ConversationResponse.fromJson(Map<String, dynamic> json) =>
      ConversationResponse(
        id: json['id']?.toString() ?? '',
        projectWorkingId: json['projectWorkingId']?.toString() ?? '',
      );
}

class ChatService {
  /// Conversations are their own entity, separate from the engagement
  /// (projectWorkingId). Finds the existing thread for this engagement, or
  /// creates one if none exists yet. Always resolve this before opening a
  /// chat thread — the engagement id is NOT a valid conversationId.
  ///
  /// The server uses `projectWorkingId` only to locate the project and check
  /// membership: the list it returns holds the threads of *every* engagement
  /// on that project, most recently active first. Taking the first row would
  /// therefore open whichever thread was last touched — quite possibly the
  /// other provider's. The engagement has to be matched here, on the way back.
  static Future<String> getOrCreateConversation(String projectWorkingId) async {
    final listResponse = await ApiClient.authGet('/chat/conversations', {
      'projectWorkingId': projectWorkingId,
      // Page size is the server's maximum: this project's other engagements
      // share the page, so a small one could push our thread off it.
      'pageSize': 100,
    });
    ApiClient.throwIfError(listResponse);
    final listBody = ApiClient.parseBody(listResponse);
    final existing = PaginationResponse.fromJson(
      listBody,
      ConversationResponse.fromJson,
    );
    for (final conversation in existing.items) {
      if (conversation.projectWorkingId == projectWorkingId) {
        return conversation.id;
      }
    }

    final createResponse = await ApiClient.authPost('/chat/conversations', {
      'projectWorkingId': projectWorkingId,
    });
    ApiClient.throwIfError(createResponse);
    // Creation now happens once per engagement rather than once per project,
    // so this path is hit routinely — handle both the flat payload and the
    // { data: { ... } } wrapper, as postMessage already does.
    final createdBody = ApiClient.parseBody(createResponse);
    final created = ConversationResponse.fromJson(
      (createdBody['data'] as Map<String, dynamic>?) ?? createdBody,
    );
    return created.id;
  }

  /// Polls for messages in a thread. BE takes conversationId as a query
  /// param and returns a bare JSON array (not the usual paginated wrapper).
  static Future<PaginationResponse<ChatMessageResponse>> getMessages(
    String conversationId, {
    String? sinceId,
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
    String conversationId,
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
