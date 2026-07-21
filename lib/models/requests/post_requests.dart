class CreatePostRequest {
  final int projectShopOwnerId;
  final String serviceKind; // design | construction | both
  final String title;
  final String description;
  final DateTime? submissionDeadline;

  CreatePostRequest({
    required this.projectShopOwnerId,
    required this.serviceKind,
    required this.title,
    required this.description,
    this.submissionDeadline,
  });

  Map<String, dynamic> toJson() => {
        'projectShopOwnerId': projectShopOwnerId,
        'serviceKind': serviceKind,
        'title': title,
        'description': description,
        if (submissionDeadline != null) 'submissionDeadline': submissionDeadline!.toIso8601String(),
      };
}

class UpdatePostRequest {
  final String? title;
  final String? description;
  final String? serviceKind;
  final String? status;
  final DateTime? submissionDeadline;

  UpdatePostRequest({
    this.title,
    this.description,
    this.serviceKind,
    this.status,
    this.submissionDeadline,
  });

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (serviceKind != null) 'serviceKind': serviceKind,
        if (status != null) 'status': status,
        if (submissionDeadline != null) 'submissionDeadline': submissionDeadline!.toIso8601String(),
      };
}
