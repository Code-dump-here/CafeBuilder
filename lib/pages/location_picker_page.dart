import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/place_location.dart';
import '../services/places_service.dart';
import '../theme/app_colors.dart';
import '../widgets/interactive_map_picker.dart';
import '../widgets/map_tile_preview.dart';

/// Full-screen address picker: search, pick a suggestion, see it on a map,
/// confirm.
///
/// Pops a [PickedLocation] on confirm, or null if the user backs out. The
/// result carries coordinates when a suggestion was chosen, and is text-only
/// when the user typed something Google didn't recognise — that fallback is
/// deliberate. A cafe under construction on a road that isn't in Google's index
/// yet is a completely normal case here, and refusing to accept the address
/// would block the owner from creating their project at all.
class LocationPickerPage extends StatefulWidget {
  /// Seeds the search box, so reopening the picker on an existing project
  /// starts from what's already saved rather than a blank field.
  final PickedLocation? initial;

  /// Shown under the app bar title.
  final String subtitle;

  const LocationPickerPage({
    super.key,
    this.initial,
    this.subtitle = 'Search an address, or drag the map to place the pin',
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late final TextEditingController _searchCtrl =
      TextEditingController(text: widget.initial?.address ?? '');

  /// Restarted on every keystroke. Without it each character fires its own
  /// request, and out-of-order responses make the list flicker between results
  /// for "Nguy" and "Nguyen".
  Timer? _debounce;
  static const Duration _debounceDelay = Duration(milliseconds: 350);

  List<PlaceSuggestion> _suggestions = const [];
  bool _searching = false;

  /// What confirm would return right now.
  PickedLocation? _selected;

  /// Set when the initial address had no pin and we geocoded it on open.
  bool _resolvingInitial = false;

  /// Whether the map is in drag-to-move mode. Off by default: most people find
  /// their address by searching, and a map that moves under an accidental
  /// swipe would quietly relocate a pin they were happy with.
  bool _adjusting = false;

  /// A reverse-geocode is in flight for a hand-placed pin.
  bool _reversing = false;

  /// Named places near the current map centre, drawn as latch targets.
  List<MapPoi> _pois = const [];

  /// The POI the pin has latched onto, if any.
  MapPoi? _latched;

  /// Where the user last pressed Undo. Latching is skipped while the pin is
  /// still at that exact point, so it cannot snap straight back onto the POI
  /// they just rejected. Moving the map at all clears it.
  PickedLocation? _suppressLatchAt;

  /// The current pin was dragged into place rather than chosen from search.
  ///
  /// Confirm treats the two differently: a searched pin is only kept while the
  /// text still matches it, but a hand-placed one is the whole point of the
  /// gesture and survives whatever the address field says.
  bool _pinFromMap = false;

  /// Waits for the drag to stop before looking up the address. Reverse
  /// geocoding every frame would fire hundreds of requests and make the
  /// address flicker through every street the map passed over.
  final _settle = MapSettleDebouncer();

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _resolveInitialPin();

    // Load latch targets for wherever the map opens, so the dots are there
    // before the first drag rather than appearing a beat afterwards.
    final start = widget.initial;
    _refreshPois(
      start?.latitude ?? PlacesService.defaultProximityLat,
      start?.longitude ?? PlacesService.defaultProximityLng,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _settle.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// A project saved before this feature existed has an address but no
  /// coordinates. Geocode it once on open so the map isn't blank while the
  /// user is looking at an address that is already correct.
  Future<void> _resolveInitialPin() async {
    final initial = widget.initial;
    if (initial == null || initial.hasCoordinates || initial.isEmpty) return;
    if (!PlacesService.isConfigured) return;

    setState(() => _resolvingInitial = true);
    final resolved = await PlacesService.geocode(initial.address);
    if (!mounted) return;
    setState(() {
      _resolvingInitial = false;
      // Keep the address the owner wrote; take only the coordinates. Google's
      // formatted version is often a different wording of the same place, and
      // silently rewriting what they typed is not this screen's job.
      if (resolved != null) {
        _selected = initial.copyWith(
          latitude: resolved.latitude,
          longitude: resolved.longitude,
        );
      }
    });
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => _search(value));
  }

  Future<void> _search(String value) async {
    if (value.trim().length < 2) {
      if (mounted) setState(() => _suggestions = const []);
      return;
    }

    setState(() => _searching = true);
    final results = await PlacesService.autocomplete(value);
    if (!mounted) return;

    // The field may have moved on while the request was in flight — dropping
    // the stale response stops an old query's results from replacing a newer
    // query's.
    if (_searchCtrl.text.trim() != value.trim()) return;

    setState(() {
      _suggestions = results;
      _searching = false;
    });
  }

  /// Instant — MapTiler returns coordinates inline with every suggestion, so
  /// there is no second request to make and no failure state to handle. The
  /// Google implementation this replaced needed a billed Place Details call
  /// here, and had to cope with it failing after the user had already chosen.
  void _choose(PlaceSuggestion suggestion) {
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = const [];
      _searchCtrl.text = suggestion.fullText;
      _selected = suggestion.toLocation();
      // Back to a searched pin, so confirm goes back to matching on text.
      _pinFromMap = false;
      // The old latch belonged to the previous location.
      _latched = null;
    });
    _refreshPois(suggestion.latitude, suggestion.longitude);
  }

  /// Fires continuously while the map is dragged.
  ///
  /// The coordinates are committed immediately — they are what the user is
  /// looking at, and confirming mid-lookup should still save the right point.
  /// Only the address lookup waits for the drag to settle.
  void _onPinMoved(double latitude, double longitude) {
    setState(() {
      _pinFromMap = true;
      // Any real movement re-enables latching.
      _suppressLatchAt = null;
      // Dragging the no-pin map is itself a request to keep dragging. Without
      // this the pin appears, `hasPin` flips true and the map would freeze
      // into a still image after a single nudge.
      _adjusting = true;
      _selected = PickedLocation(
        // The previous address is kept while dragging so the panel doesn't
        // flash empty. It is stale for as long as the drag lasts — the lookup
        // below replaces it the moment the map settles.
        address: _selected?.address ?? '',
        latitude: latitude,
        longitude: longitude,
      );
    });

    _settle.run(() => _reverseGeocodePin(latitude, longitude));
  }

  /// How close the pin has to come to a POI, in screen pixels, before it
  /// latches on.
  ///
  /// Pixels rather than metres on purpose: the threshold has to feel the same
  /// whatever the zoom. 26px is roughly a fingertip, so latching happens when
  /// the user has visibly aimed at the dot — small enough that a pin placed
  /// deliberately between two shops stays where it was put.
  static const double _latchRadiusPx = 26;

  /// The nearest POI within [_latchRadiusPx] of a point, or null.
  MapPoi? _latchTarget(double latitude, double longitude) {
    if (_pois.isEmpty) return null;

    const zoom = 17; // The zoom the picker opens at; the radius is tuned to it.
    final centre = PlacesService.worldPixel(latitude, longitude, zoom);

    MapPoi? best;
    var bestDistance = double.infinity;
    for (final poi in _pois) {
      final p = PlacesService.worldPixel(poi.latitude, poi.longitude, zoom);
      final dx = p.x - centre.x;
      final dy = p.y - centre.y;
      final distance = math.sqrt(dx * dx + dy * dy);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = poi;
      }
    }

    return bestDistance <= _latchRadiusPx ? best : null;
  }

  /// Snap onto a named place, taking its coordinates, name and address.
  ///
  /// Better than reverse geocoding the bare point: a POI carries its own name
  /// and street number, where a loose coordinate usually resolves to whatever
  /// road segment happens to be nearest.
  void _latchOnto(MapPoi poi) {
    _settle.cancel();
    setState(() {
      _pinFromMap = true;
      _adjusting = true;
      _latched = poi;
      _reversing = false;
      _selected = poi.toLocation();
      _searchCtrl.text = poi.address;
    });
  }

  /// Release a latch and fall back to the plain coordinates the pin sits on.
  ///
  /// Suppresses the next latch check for this spot, because re-running it
  /// would immediately snap back onto the POI the user just rejected.
  void _unlatch() {
    final current = _selected;
    if (current == null || !current.hasCoordinates) return;

    setState(() {
      _latched = null;
      _suppressLatchAt = current;
    });
    _settle.run(
      () => _reverseGeocodePin(current.latitude!, current.longitude!),
    );
  }

  /// Counts every batch asked for, so a slow reply cannot overwrite a fast one
  /// that was asked for later.
  ///
  /// This matters now that the map refills during a drag: several requests can
  /// be in flight at once, they do not necessarily come back in order, and the
  /// map showing places from a point the pin has long since left is worse than
  /// showing none.
  int _poiRequests = 0;

  /// The point the most recent batch was asked for, and that request while it
  /// is still in the air.
  double? _poiFetchLat;
  double? _poiFetchLng;
  Future<void>? _poiFetchInFlight;

  /// Close enough to count as the same query. The map moves in fractions of a
  /// metre per frame, and the geocoder cannot tell two points this close apart.
  static const double _poiFetchSameSpotMetres = 5;

  Future<void> _refreshPois(double latitude, double longitude) async {
    final lastLat = _poiFetchLat;
    final lastLng = _poiFetchLng;
    if (lastLat != null &&
        lastLng != null &&
        PlacesService.metresBetween(lastLat, lastLng, latitude, longitude) <
            _poiFetchSameSpotMetres) {
      // This spot has already been asked about. Wait on that answer instead of
      // paying for the same one twice: the settle always lands on the point the
      // drag's last refill just covered, so this is every drag, not an edge
      // case. Awaiting rather than returning matters — the caller reads _pois
      // straight afterwards to decide what to latch onto.
      await _poiFetchInFlight;
      return;
    }

    _poiFetchLat = latitude;
    _poiFetchLng = longitude;

    final token = ++_poiRequests;
    final request = PlacesService.nearbyPois(latitude, longitude);
    _poiFetchInFlight = request;
    final found = await request;
    if (!mounted || token != _poiRequests) return;
    setState(() => _pois = found);
  }

  Future<void> _reverseGeocodePin(double latitude, double longitude) async {
    // Refresh the latch targets for wherever the map now sits, then check
    // whether the pin came to rest on one of them.
    await _refreshPois(latitude, longitude);
    if (!mounted) return;

    final suppressed = _suppressLatchAt;
    final atSuppressedPoint = suppressed != null &&
        suppressed.latitude == latitude &&
        suppressed.longitude == longitude;

    final target = atSuppressedPoint ? null : _latchTarget(latitude, longitude);
    if (target != null) {
      _latchOnto(target);
      return;
    }

    setState(() => _latched = null);

    setState(() => _reversing = true);
    final resolved = await PlacesService.reverseGeocode(latitude, longitude);
    if (!mounted) return;

    // Another drag started while this was in flight — its own lookup will
    // land, and applying this one would overwrite a newer pin's address.
    final current = _selected;
    if (current == null ||
        current.latitude != latitude ||
        current.longitude != longitude) {
      setState(() => _reversing = false);
      return;
    }

    setState(() {
      _reversing = false;

      // On failure, label the pin with its own coordinates rather than leaving
      // the street name it was dragged away from. Both branches also write the
      // search field, because `_confirm` keeps the pin only when the text and
      // the address agree — leaving them out of step would silently discard a
      // pin the user placed by hand.
      final next = resolved ??
          PickedLocation(
            address: '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
            latitude: latitude,
            longitude: longitude,
          );

      _selected = next;
      _searchCtrl.text = next.address;
    });
  }

  Widget _buildAdjustToggle() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => setState(() => _adjusting = !_adjusting),
        icon: Icon(
          _adjusting ? Icons.check_circle_outline : Icons.edit_location_alt_outlined,
          size: 16,
        ),
        label: Text(
          _adjusting ? 'Done adjusting' : 'Pin is in the wrong spot? Adjust it',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.espresso,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  void _confirm() {
    final typed = _searchCtrl.text.trim();
    final selected = _selected;

    // A pin placed by hand stands on its own. The address may still be
    // resolving, or may never resolve at all for a lane OpenStreetMap has not
    // mapped — neither is a reason to throw away a location the user pointed
    // at deliberately. Its own coordinates are the label of last resort.
    if (_pinFromMap && selected != null && selected.hasCoordinates) {
      final label = typed.isNotEmpty
          ? typed
          : selected.address.trim().isNotEmpty
              ? selected.address.trim()
              : '${selected.latitude!.toStringAsFixed(6)}, '
                  '${selected.longitude!.toStringAsFixed(6)}';

      Navigator.pop(
        context,
        PickedLocation(
          address: label,
          latitude: selected.latitude,
          longitude: selected.longitude,
        ),
      );
      return;
    }

    if (typed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drag the map to place a pin, or type an address.'),
        ),
      );
      return;
    }

    // Typed something and never picked a suggestion (or edited the text after
    // picking one): save the words, drop the pin. Keeping a pin that no longer
    // matches the visible address is the one outcome worse than having none.
    final result = selected != null && selected.address.trim() == typed
        ? selected
        : PickedLocation.textOnly(typed);

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.espresso),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose location',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            Text(
              widget.subtitle,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: _buildSearchField(),
          ),
          if (!PlacesService.isConfigured) _buildUnconfiguredNotice(),
          Expanded(
            child: _suggestions.isNotEmpty
                ? _buildSuggestionList()
                : _buildPreview(),
          ),
          _buildConfirmBar(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      // Deliberately not autofocused. The map is usable straight away, and
      // popping the keyboard over it on open would hide the very thing the
      // user can now drag.
      autofocus: false,
      onChanged: _onQueryChanged,
      style: GoogleFonts.inter(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'e.g., 123 Nguyễn Huệ, Quận 1',
        hintStyle: GoogleFonts.inter(color: AppColors.placeholder, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.placeholder, size: 20),
        suffixIcon: _searching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : (_searchCtrl.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.placeholder),
                    tooltip: 'Clear',
                    onPressed: () {
                      _debounce?.cancel();
                      setState(() {
                        _searchCtrl.clear();
                        _suggestions = const [];
                        _selected = null;
                      });
                    },
                  )),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.espresso, width: 1.5),
        ),
      ),
    );
  }

  /// Shown when no API key was compiled in. Says plainly that search is off and
  /// that typing still works, rather than leaving the user tapping a search box
  /// that silently returns nothing.
  Widget _buildUnconfiguredNotice() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0D9B5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF8A6D3B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Address search is off in this build — no Google Maps key was provided. '
              'You can still type the address by hand.',
              style: GoogleFonts.inter(fontSize: 11, height: 1.5, color: const Color(0xFF8A6D3B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.outlineVariant),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: const Icon(Icons.place_outlined, size: 20, color: AppColors.placeholder),
          title: Text(
            suggestion.mainText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: suggestion.secondaryText.isEmpty
              ? null
              : Text(
                  suggestion.secondaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
          onTap: () => _choose(suggestion),
        );
      },
    );
  }

  Widget _buildPreview() {
    if (_resolvingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!PlacesService.isConfigured) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Type the address above — map search is off in this build.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final selected = _selected;
    final hasPin = selected != null && selected.hasCoordinates;

    // The map is live when there is no pin to protect, or when the user has
    // asked to move one. Once a pin is settled it becomes a still image —
    // otherwise a stray swipe would relocate a pin they were happy with.
    final live = !hasPin || _adjusting;

    // With no pin, open over Ho Chi Minh City, where the projects are. Nobody
    // has to type anything to get started: searching is one way to find a
    // place, pointing at it is the other, and a site with no address on record
    // — a new build down an unnamed lane — can only be given a location this way.
    final lat = hasPin ? selected.latitude! : PlacesService.defaultProximityLat;
    final lng = hasPin ? selected.longitude! : PlacesService.defaultProximityLng;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (live)
            // One instance, deliberately unkeyed. The first drag on the
            // no-pin map makes `hasPin` true, and a key derived from the
            // coordinates would rebuild the widget on every frame of that
            // drag — resetting its zoom and killing the gesture. Re-centring
            // on a new search result is handled inside the widget's
            // didUpdateWidget instead, which knows not to fight a live drag.
            InteractiveMapPicker(
              initialLatitude: lat,
              initialLongitude: lng,
              height: 240,
              onChanged: _onPinMoved,
              pois: _pois,
              latched: _latched,
              onPoiTapped: _latchOnto,
              // Refill while the drag is still going. Without this a drag of
              // more than a screen or so runs off the end of the batch and the
              // map goes bare until the finger comes up.
              onPoisNeeded: _refreshPois,
            )
          else
            // Width comes from the layout rather than a guess: the tile grid is
            // laid out in pixels, so it needs a real number, and passing a wrong
            // one would offset the centre pin from the actual coordinate.
            LayoutBuilder(
              builder: (context, constraints) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MapTilePreview(
                  latitude: selected.latitude!,
                  longitude: selected.longitude!,
                  width: constraints.maxWidth,
                  height: 240,
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (hasPin)
            _buildAdjustToggle()
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.touch_app_outlined, size: 15, color: AppColors.placeholder),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag the map until the pin sits on your site, or search '
                    'for the address above.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          if (hasPin) ...[
            // Names the place the pin snapped to. Without this the pin just
            // jumps and the address changes, and it looks like a glitch rather
            // than the map doing something useful.
            if (_latched != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EAA3).withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin, size: 14, color: Color(0xFF56642B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Snapped to ${_latched!.name}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF56642B),
                        ),
                      ),
                    ),
                    // Latching is a guess about intent, so it has to be
                    // undoable — otherwise a pin deliberately placed next door
                    // to a shop can never be kept there.
                    TextButton(
                      onPressed: _unlatch,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: const Color(0xFF56642B),
                      ),
                      child: Text(
                        'Undo',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (_reversing)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(
                  child: Text(
                    selected.address.trim().isEmpty
                        ? 'Looking up this address…'
                        : selected.address,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.my_location, size: 13, color: AppColors.placeholder),
                const SizedBox(width: 6),
                Text(
                  '${selected.latitude!.toStringAsFixed(6)}, ${selected.longitude!.toStringAsFixed(6)}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConfirmBar() {
    final selected = _selected;
    final pinned = selected != null &&
        selected.hasCoordinates &&
        selected.address.trim() == _searchCtrl.text.trim();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Says which of the two outcomes confirm will produce, before the
            // user commits to it.
            Row(
              children: [
                Icon(
                  pinned ? Icons.check_circle : Icons.edit_location_alt_outlined,
                  size: 14,
                  color: pinned ? const Color(0xFF56642B) : AppColors.placeholder,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pinned
                        ? 'Saved with a map pin'
                        : 'Saved as text only — no map pin',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: pinned ? const Color(0xFF56642B) : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Use this location',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
