class CreateDesignBriefRequest {
  final int projectId;
  final String targetCustomer;
  final String style;
  final String mood;
  final int? seatCount;
  final String? timeline;
  final String? brandNote;
  final String? businessModel;
  final String? businessGoals;
  final String? operationNote;

  CreateDesignBriefRequest({
    required this.projectId,
    required this.targetCustomer,
    required this.style,
    required this.mood,
    this.seatCount,
    this.timeline,
    this.brandNote,
    this.businessModel,
    this.businessGoals,
    this.operationNote,
  });

  Map<String, dynamic> toJson() => {
        'projectShopOwnerId': projectId,
        'targetCustomer': targetCustomer,
        'style': style,
        'mood': mood,
        if (seatCount != null) 'seatCount': seatCount,
        if (timeline != null) 'timeline': timeline,
        if (brandNote != null) 'brandNote': brandNote,
        if (businessModel != null) 'businessModel': businessModel,
        if (businessGoals != null) 'businessGoals': businessGoals,
        if (operationNote != null) 'operationNote': operationNote,
      };
}

class UpdateDesignBriefRequest {
  final String? targetCustomer;
  final String? style;
  final String? mood;
  final int? seatCount;
  final String? timeline;
  final String? brandNote;
  final String? businessModel;
  final String? businessGoals;
  final String? operationNote;

  UpdateDesignBriefRequest({
    this.targetCustomer,
    this.style,
    this.mood,
    this.seatCount,
    this.timeline,
    this.brandNote,
    this.businessModel,
    this.businessGoals,
    this.operationNote,
  });

  Map<String, dynamic> toJson() => {
        if (targetCustomer != null) 'targetCustomer': targetCustomer,
        if (style != null) 'style': style,
        if (mood != null) 'mood': mood,
        if (seatCount != null) 'seatCount': seatCount,
        if (timeline != null) 'timeline': timeline,
        if (brandNote != null) 'brandNote': brandNote,
        if (businessModel != null) 'businessModel': businessModel,
        if (businessGoals != null) 'businessGoals': businessGoals,
        if (operationNote != null) 'operationNote': operationNote,
      };
}
