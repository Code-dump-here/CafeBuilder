class CreateProjectRequest {
  final int ownerId;
  final String name;
  final String address;
  final double areaM2;
  final double budget;

  CreateProjectRequest({
    required this.ownerId,
    required this.name,
    required this.address,
    required this.areaM2,
    required this.budget,
  });

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'name': name,
        'address': address,
        'areaM2': areaM2,
        'budget': budget,
      };
}

class UpdateProjectRequest {
  final String? name;
  final String? address;
  final double? areaM2;
  final double? budget;
  final String? status;

  UpdateProjectRequest({this.name, this.address, this.areaM2, this.budget, this.status});

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (areaM2 != null) 'areaM2': areaM2,
        if (budget != null) 'budget': budget,
        if (status != null) 'status': status,
      };
}
