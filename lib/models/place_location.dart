/// A location the user actually picked: the address they see, plus the
/// coordinates the backend stores.
///
/// The two travel together on purpose. Storing only the string means every
/// screen that wants a map has to geocode again — that costs a billed request
/// per render and can resolve to a different building than the one the owner
/// pinned. Storing only coordinates means the UI has nothing readable to show.
class PickedLocation {
  /// Human-readable address, as Google formatted it (or as the user typed it,
  /// when they skipped the map).
  final String address;

  /// Null when the user typed an address without pinning it. Always paired
  /// with [longitude] — the backend rejects one without the other.
  final double? latitude;
  final double? longitude;

  /// Set when the pin latched onto a named place rather than a bare point.
  ///
  /// Not persisted separately: [address] already begins with the name, which
  /// is how MapTiler formats a POI line. This is kept only so the picker can
  /// show "latched onto X" while the user is deciding.
  final String? poiName;

  const PickedLocation({
    required this.address,
    this.latitude,
    this.longitude,
    this.poiName,
  });

  /// Address only, no pin. What the plain text field produces.
  const PickedLocation.textOnly(this.address)
      : latitude = null,
        longitude = null,
        poiName = null;

  /// True when this can be drawn on a map.
  bool get hasCoordinates => latitude != null && longitude != null;

  bool get isEmpty => address.trim().isEmpty;

  PickedLocation copyWith({String? address, double? latitude, double? longitude}) =>
      PickedLocation(
        address: address ?? this.address,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        poiName: poiName,
      );

  @override
  String toString() => hasCoordinates
      ? '$address ($latitude, $longitude)'
      : address;
}

/// A named place near the map centre — a cafe, a hotel, a shop — that the pin
/// can latch onto.
///
/// Exists so an owner can say "my site is *that* building" instead of nudging
/// pixels until the coordinates look about right. Latching also produces a far
/// better address than reverse geocoding a bare point: the POI carries its own
/// name and street number, where a raw coordinate usually resolves to whatever
/// road segment happens to be nearest.
class MapPoi {
  /// OpenStreetMap reference, e.g. `osm:n5116719014`. Stable enough to tell
  /// two POIs apart between refreshes.
  final String id;

  /// Display name — "Cà Phê Calibre", "Khách sạn Palace Saigon".
  final String name;

  /// Full line as MapTiler formats it, already "name, street, ward, city".
  final String address;

  /// First category, used only to pick an icon. Null when untagged.
  final String? category;

  final double latitude;
  final double longitude;

  const MapPoi({
    required this.id,
    required this.name,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
  });

  PickedLocation toLocation() => PickedLocation(
        address: address,
        latitude: latitude,
        longitude: longitude,
        poiName: name,
      );
}

/// One row in the autocomplete dropdown.
///
/// Carries its own coordinates. MapTiler returns them inline with each
/// suggestion, so tapping a row needs no second request — which removed the
/// round trip, the billing session tokens and the "chosen but unresolvable"
/// state the earlier Google implementation had to carry.
class PlaceSuggestion {
  /// The whole line, e.g. "Đại lộ Nguyễn Huệ, Khu phố 5, Phường Sài Gòn, …".
  final String fullText;

  /// The name part, e.g. "Đại lộ Nguyễn Huệ".
  final String mainText;

  /// The context part, e.g. "Khu phố 5, Phường Sài Gòn, …".
  final String secondaryText;

  final double latitude;
  final double longitude;

  const PlaceSuggestion({
    required this.fullText,
    required this.mainText,
    required this.secondaryText,
    required this.latitude,
    required this.longitude,
  });

  PickedLocation toLocation() => PickedLocation(
        address: fullText,
        latitude: latitude,
        longitude: longitude,
      );
}
