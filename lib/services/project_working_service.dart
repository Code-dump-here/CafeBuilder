import '../models/responses/api_responses.dart';
import 'api_client.dart';

class ProjectWorkingService {
  // ── Project slot rules ───────────────────────────────────────────────────
  // Mirrors ProjectSlotRules on the backend, which is what actually enforces
  // this. Keep the two in step: when they drifted, the app offered to recruit
  // for a slot the server then refused with a 409.

  /// Engagement statuses that hold a slot. A pending invite ('requested')
  /// counts, because the provider may still accept and we must not
  /// double-book. 'completed', 'rejected' and 'terminated' release the slot.
  static const engagedStatuses = {'requested', 'accepted'};

  /// Whether two scopes of work collide. 'both' collides with everything.
  static bool kindsOverlap(String a, String b) =>
      a == 'both' || b == 'both' || a == b;

  /// Whether [role] ('design' or 'construction') is already held on a project.
  static bool roleTaken(
    Iterable<ProjectWorkingResponse> workings,
    String role,
  ) =>
      workings.any((w) =>
          engagedStatuses.contains(w.status.toLowerCase()) &&
          kindsOverlap(w.contractType.toLowerCase(), role));

  /// Why [wantedKind] can't be taken on, or null when the slot is free.
  /// Phrased for display to the owner.
  static String? slotConflict(
    Iterable<ProjectWorkingResponse> workings,
    String wantedKind,
  ) {
    final kind = wantedKind.toLowerCase();
    final designTaken = roleTaken(workings, 'design');
    final constructionTaken = roleTaken(workings, 'construction');

    final blocked = switch (kind) {
      'design' => designTaken,
      'construction' => constructionTaken,
      'both' => designTaken || constructionTaken,
      _ => false,
    };
    if (!blocked) return null;

    if (designTaken && constructionTaken) {
      return 'This project already has a designer and a constructor.';
    }
    return designTaken
        ? 'This project already has a designer.'
        : 'This project already has a constructor.';
  }

  static Future<PaginationResponse<ProjectWorkingResponse>> getProjectWorkings({
    int pageNumber = 1,
    int pageSize = 10,
    int? projectShopOwnerId,
    int? serviceProviderProfileId,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (projectShopOwnerId != null) 'projectShopOwnerId': projectShopOwnerId,
      if (serviceProviderProfileId != null) 'serviceProviderProfileId': serviceProviderProfileId,
      if (status != null) 'status': status,
    };
    final response = await ApiClient.authGet('/project-workings', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, ProjectWorkingResponse.fromJson);
  }

  static Future<ProjectWorkingResponse> getProjectWorking(int id) async {
    final response = await ApiClient.authGet('/project-workings/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }

  static Future<DesignBriefResponse> getProjectWorkingBrief(int id) async {
    final response = await ApiClient.authGet('/project-workings/$id/brief');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignBriefResponse.fromJson(body);
  }

  static Future<EngagementOverviewResponse> getProjectWorkingOverview(int id) async {
    final response = await ApiClient.authGet('/project-workings/$id/overview');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return EngagementOverviewResponse.fromJson(body);
  }

  static Future<ProjectWorkingResponse> updateProjectWorkingStatus(
    int id,
    String status,
  ) async {
    final response = await ApiClient.authPut('/project-workings/$id/status', {
      'status': status,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }

  // --- Direct Hires Path B ---

  static Future<ProjectWorkingResponse> directRequest({
    required int projectShopOwnerId,
    required int serviceProviderProfileId,
    required String contractType,
    required String requestMessage,
  }) async {
    final response = await ApiClient.authPost('/project-workings/direct-request', {
      'projectShopOwnerId': projectShopOwnerId,
      'serviceProviderProfileId': serviceProviderProfileId,
      'contractType': contractType,
      'requestMessage': requestMessage,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }

  static Future<ProjectWorkingResponse> acceptDirectRequest(int id) async {
    final response = await ApiClient.authPost('/project-workings/$id/accept', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }

  static Future<ProjectWorkingResponse> rejectDirectRequest(int id) async {
    final response = await ApiClient.authPost('/project-workings/$id/reject', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }

  static Future<void> completeEngagement(int id) async {
    final response = await ApiClient.authPost('/project-workings/$id/complete', {});
    ApiClient.throwIfError(response);
  }

  // ── Ending an engagement early ───────────────────────────────────────────
  // Ending a running engagement takes both sides. One party requests, the
  // other approves; until then the engagement stays 'accepted'. The old
  // one-shot `/terminate` still exists but no longer terminates on its own —
  // it files a request, or approves the other side's — so these explicit
  // endpoints are used instead to keep the app honest about what happened.

  /// Asks the provider to end the engagement. Returns the updated engagement,
  /// which stays 'accepted' with [isAwaitingTerminationApproval] set.
  static Future<ProjectWorkingResponse> requestTermination(
    int id, {
    String? reason,
  }) async {
    final response = await ApiClient.authPost(
      '/project-workings/$id/termination-request',
      {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
    ApiClient.throwIfError(response);
    return ProjectWorkingResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Answers the provider's request. [approve] true ends the engagement;
  /// false clears the request and the work continues.
  static Future<ProjectWorkingResponse> respondToTermination(
    int id, {
    required bool approve,
    String? note,
  }) async {
    final response = await ApiClient.authPost(
      '/project-workings/$id/termination-response',
      {
        'approve': approve,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    ApiClient.throwIfError(response);
    return ProjectWorkingResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Withdraws our own pending request, while the provider hasn't answered.
  static Future<ProjectWorkingResponse> cancelTerminationRequest(int id) async {
    final response = await ApiClient.authDelete(
      '/project-workings/$id/termination-request',
    );
    ApiClient.throwIfError(response);
    return ProjectWorkingResponse.fromJson(ApiClient.parseBody(response));
  }

  static Future<ProjectWorkingResponse> requestCompletion(int id, {String? note}) async {
    final response = await ApiClient.authPost('/project-workings/$id/request-completion', {
      if (note != null && note.isNotEmpty) 'note': note,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }
}
