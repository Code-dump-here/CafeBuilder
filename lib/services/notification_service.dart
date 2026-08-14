import '../models/responses/api_responses.dart';
import 'api_client.dart';

class NotificationService {
  // accountId used to be passed by the client, which meant anyone could
  // read someone else's mailbox by changing the query param. The backend
  // now always derives it from the JWT and ignores/ no longer accepts a
  // client-supplied value — these calls no longer take one.
  static Future<PaginationResponse<NotificationResponse>> getNotifications({
    int pageNumber = 1,
    int pageSize = 20,
    bool? isRead,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (isRead != null) {
      params['isRead'] = isRead;
    }
    final response = await ApiClient.authGet('/notifications', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, NotificationResponse.fromJson);
  }

  static Future<int> getUnreadCount() async {
    final response = await ApiClient.authGet('/notifications/unread-count');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    // Backend may return { "count": X } or { "unreadCount": X }
    if (body.containsKey('count')) return (body['count'] as num).toInt();
    if (body.containsKey('unreadCount')) return (body['unreadCount'] as num).toInt();
    return 0;
  }

  static Future<void> markAsRead(int notificationId) async {
    final response = await ApiClient.authPatch('/notifications/$notificationId/read', {});
    ApiClient.throwIfError(response);
  }

  static Future<void> markAllAsRead() async {
    final response = await ApiClient.authPost('/notifications/mark-all-read', {});
    ApiClient.throwIfError(response);
  }
}
