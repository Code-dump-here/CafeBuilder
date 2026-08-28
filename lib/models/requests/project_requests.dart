class CreateProjectRequest {
  final String ownerId;
  final String name;
  final String address;

  /// Map pin for [address]. Both or neither — the backend answers 400 for a
  /// lone latitude, since one coordinate doesn't point anywhere.
  final double? latitude;
  final double? longitude;

  final double areaM2;
  final double budget;

  CreateProjectRequest({
    required this.ownerId,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    required this.areaM2,
    required this.budget,
  });

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'name': name,
        'address': address,
        // Omitted rather than sent as null when there's no pin: the update
        // endpoint reads null as "leave alone", and keeping both payloads
        // shaped the same way avoids one of them meaning something different.
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'areaM2': areaM2,
        'budget': budget,
      };
}

class UpdateProjectRequest {
  final String? name;
  final String? address;

  /// New map pin. Null means "don't touch the saved one" — to remove a pin,
  /// use [clearCoordinates] instead.
  final double? latitude;
  final double? longitude;

  /// Drops the saved pin, leaving the address as text.
  ///
  /// Needs its own flag because null already means "skip this field" in a
  /// partial update; there is otherwise no way to express "erase it".
  final bool clearCoordinates;

  final double? areaM2;
  final double? budget;
  final String? status;

  UpdateProjectRequest({
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.clearCoordinates = false,
    this.areaM2,
    this.budget,
    this.status,
  });

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (clearCoordinates) 'clearCoordinates': true,
        if (areaM2 != null) 'areaM2': areaM2,
        if (budget != null) 'budget': budget,
        if (status != null) 'status': status,
      };
}
