import '../models/responses/api_responses.dart';
import 'api_client.dart';

class NotificationService {
  static Future<PaginationResponse<NotificationResponse>> getNotifications(
    int accountId, {
    int pageNumber = 1,
    int pageSize = 20,
    bool? isRead,
  }) async {
    final params = <String, dynamic>{
      'accountId': accountId,
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

  static Future<int> getUnreadCount(int accountId) async {
    final response = await ApiClient.authGet('/notifications/unread-count', {'accountId': accountId});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    // Backend may return { "count": X } or { "unreadCount": X }
    if (body.containsKey('count')) return (body['count'] as num).toInt();
    if (body.containsKey('unreadCount')) return (body['unreadCount'] as num).toInt();
    return 0;
  }

  static Future<void> markAsRead(int notificationId) async {
    final response = await ApiClient.authPost('/notifications/$notificationId/read', {});
    ApiClient.throwIfError(response);
  }

  static Future<void> markAllAsRead(int accountId) async {
    final response = await ApiClient.authPost('/notifications/mark-all-read', {'accountId': accountId});
    ApiClient.throwIfError(response);
  }
}
