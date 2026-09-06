import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/place_location.dart';
import '../services/device_location.dart';
import '../services/address_cache.dart';
import '../services/local_store.dart';
import '../services/places_service.dart';
import '../services/poi_cache.dart';
import '../services/poi_tiles.dart';
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
  ///
  /// The nearest few of everything [PoiCache] has ever seen, not the contents
  /// of the last reply — so they keep up with the pin over ground already
  /// covered instead of waiting on a round trip. See [_refreshPois].
  List<MapPoi> _pois = const [];

  /// The POI the pin has latched onto, if any.
  MapPoi? _latched;

  /// A fix is being taken for the "move the pin to where I am" button.
  bool _locating = false;

  /// A fix good only to this many metres is worth warning about.
  ///
  /// Anything from a real GPS lock is a few metres. Numbers like this come
  /// from a cell tower or a browser guessing from the network, which can be a
  /// suburb out — and the pin would sit there looking exactly as confident as
  /// a good one. The user is about to save it as their cafe's address.
  static const double _roughFixMetres = 200;

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
    final startLat = start?.latitude ?? PlacesService.defaultProximityLat;
    final startLng = start?.longitude ?? PlacesService.defaultProximityLng;

    // Seeded straight from the cache rather than through [_refreshPois],
    // because that path calls setState and this runs inside the first build.
    // Reopening the picker on a neighbourhood already looked at now starts
    // with its dots up instead of blank until a round trip lands.
    _poiAnchorLat = startLat;
    _poiAnchorLng = startLng;
    _pois = PoiCache.instance.around(
      startLat,
      startLng,
      limit: _poiDrawCount,
      withinMetres: _serveRadiusMetres,
    );
    _refreshPois(startLat, startLng);

    // Bring back what earlier sessions learned, then redraw with it. Both are
    // fire-and-forget and idempotent: the dots come from whatever is in hand
    // each time the map asks, so a cache landing a few milliseconds later just
    // shows up on the next ask. Doing it here rather than in main() keeps app
    // startup out of it entirely.
    unawaited(
      PoiCache.instance.restore(const SharedPreferencesStore()).then((_) {
        if (mounted) _drawPoisNear(_poiAnchorLat ?? startLat, _poiAnchorLng ?? startLng);
      }),
    );
    unawaited(AddressCache.instance.restore(const SharedPreferencesStore()));
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

  /// Jump the pin to where the device says it is.
  ///
  /// Treated as a hand-placed pin once it lands, because that is what it is:
  /// a point the user pointed at, not a search result whose text has to keep
  /// matching. The address is then filled in by exactly the lookup a drag
  /// uses — so a fix that lands on a shop latches onto it and takes its name,
  /// which is usually a better answer than the street the coordinates alone
  /// would resolve to.
  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);

    final result = await DeviceLocation.current();
    if (!mounted) return;
    setState(() => _locating = false);

    switch (result) {
      case DeviceLocationFailed(:final reason):
        _reportLocationFailure(reason);

      case DeviceLocationFound(
          :final latitude,
          :final longitude,
          :final accuracyMetres
        ):
        // Whatever was resolving belongs to the pin we are about to replace.
        _settle.cancel();
        FocusScope.of(context).unfocus();

        setState(() {
          _pinFromMap = true;
          // The map has to be live for the new pin to be adjustable, and a
          // fix is worth adjusting far more often than a searched address is.
          _adjusting = true;
          _suggestions = const [];
          _suppressLatchAt = null;
          // The old latch belonged to somewhere else entirely.
          _latched = null;
          _selected = PickedLocation(
            // Held until the lookup below replaces it, so the panel does not
            // flash empty — the same thing a drag does.
            address: _selected?.address ?? '',
            latitude: latitude,
            longitude: longitude,
          );
        });

        if (accuracyMetres > _roughFixMetres) {
          _say('Rough fix — good to about ${accuracyMetres.round()}m. Drag the '
              'map to put the pin exactly.');
        }

        await _reverseGeocodePin(latitude, longitude);
    }
  }

  /// Say what went wrong in terms of what to do about it.
  ///
  /// Every one of these ends by pointing back at the map, because none of them
  /// is a dead end: placing the pin by hand was the original way in and is
  /// still there. A location button that fails silently, or that fails and
  /// leaves the user with nothing, is worse than no button.
  void _reportLocationFailure(LocationFailure reason) {
    switch (reason) {
      case LocationFailure.serviceDisabled:
        _say('Location is switched off on this device. Turn it on, or drag the '
            'map to place the pin.');
      case LocationFailure.permissionDenied:
        _say('Without location permission the pin has to go on by hand. Tap the '
            'button again to be asked once more.');
      case LocationFailure.permissionDeniedForever:
        _say(
          'Location is blocked for this app. Drag the map to place the pin, or '
          'allow it in settings.',
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              DeviceLocation.openSettings();
            },
          ),
        );
      case LocationFailure.timedOut:
        _say('No fix yet — that usually means indoors. Try again, or drag the '
            'map to place the pin.');
      case LocationFailure.unavailable:
        _say('This device cannot report its location. Drag the map to place the '
            'pin.');
    }
  }

  void _say(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  /// Fires continuously while the map is dragged.
  ///
  /// The coordinates are committed immediately — they are what the user is
  /// looking at, and confirming mid-lookup should still save the right point.
  /// Only the address lookup waits for the drag to settle.
  void _onPinMoved(double latitude, double longitude) {
    _trackMotion(latitude, longitude);
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

    // The zoom the map is actually at, not the one it opened at. Projecting at
    // a fixed 17 while the user was looking at 13 made the radius sixteen times
    // too generous in ground terms — the pin would snap onto a shop most of a
    // kilometre away, and the address it saved would be that shop's.
    final centre = PlacesService.worldPixel(latitude, longitude, _mapZoom);

    MapPoi? best;
    var bestDistance = double.infinity;
    for (final poi in _pois) {
      final p = PlacesService.worldPixel(poi.latitude, poi.longitude, _mapZoom);
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
      // The name straight away — it is what the user aimed at, and it is
      // already known. The street address follows a moment later.
      _searchCtrl.text = poi.name;
    });
    unawaited(_resolveLatchedAddress(poi));
  }

  /// Fill in the street address of a place the pin has snapped to.
  ///
  /// The map tiles carry a place's name and its kind but not "123 Lê Lợi, Bến
  /// Nghé, Quận 1", so this is the one geocoding request the tile path still
  /// spends. It is spent at the moment the user has actually chosen something,
  /// rather than fourteen times a kilometre on the way there — and it goes
  /// through [AddressCache], so snapping back to the same shop is free.
  ///
  /// Failure leaves the name in place, which is still true and still useful.
  Future<void> _resolveLatchedAddress(MapPoi poi) async {
    var line =
        AddressCache.instance.lookup(poi.latitude, poi.longitude)?.address;

    if (line == null) {
      final resolved =
          await PlacesService.reverseGeocode(poi.latitude, poi.longitude);
      if (resolved == null) return;
      AddressCache.instance.record(
          poi.latitude, poi.longitude, resolved.address);
      line = resolved.address;
    }

    // The user may have latched onto something else while this was in flight.
    if (!mounted || _latched?.id != poi.id) return;

    // The geocoder's line usually already opens with the place itself; when it
    // does not, the name goes in front, because the name is what was aimed at.
    final full = line.startsWith(poi.name) ? line : '${poi.name}, $line';
    setState(() {
      _selected = PickedLocation(
        address: full,
        latitude: poi.latitude,
        longitude: poi.longitude,
        poiName: poi.name,
      );
      _searchCtrl.text = full;
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

  /// How many dots the map is given at once.
  ///
  /// Close to the ten a single reply used to carry, because the sizing and
  /// fading were tuned against a batch that size and twenty dots is a crowd,
  /// not a gradient. The difference is that these are the nearest twelve of
  /// everything seen so far rather than the ten one query happened to return.
  static const int _poiDrawCount = 12;

  /// The map's height, shared by the widget that draws it and the sums below
  /// that reason about how much ground it shows.
  static const double _mapHeight = 240;

  /// The zoom the map is at, reported by the picker.
  ///
  /// Starts at the zoom the picker opens on and is corrected before the first
  /// frame is interacted with, so nothing here is ever reasoning about a scale
  /// the user is not looking at.
  int _mapZoom = 17;

  /// How far out to look for places worth drawing.
  ///
  /// Three screens' worth, so the dots are already in hand when the map moves
  /// rather than arriving after it. As a fixed 2km this was far too tight below
  /// about zoom 13, where a single swipe crosses 3.4km: the pin left the served
  /// disc in one gesture, the map went bare, and the empty-box trigger then ran
  /// at the throttle's limit over ground nothing had been asked about.
  ///
  /// The floor matters at the other end — at zoom 19 three screens is barely a
  /// hundred metres, which is too few places to rank a gradient over.
  double get _serveRadiusMetres {
    final onScreen =
        _mapHeight * PlacesService.metresPerPixel(_mapZoom, _poiAnchorLat ?? 0);
    return math.max(500.0, onScreen * 3);
  }

  /// The point the dots were last drawn around — where the picker believes the
  /// pin is. A reply landing after the pin has moved on is redrawn against
  /// this rather than against where it was asked from.
  double? _poiAnchorLat;
  double? _poiAnchorLng;

  /// The one request allowed to be in the air at a time.
  ///
  /// **This is the rate limiter, not a tidiness measure.** Do not remove it to
  /// simplify something. It is worth several times more than any of the
  /// distance thresholds:
  ///
  ///   * It caps the request rate at one per round trip — three to five a
  ///     second — however fast the map asks. During a hard drag it, rather
  ///     than any distance rule, is the binding constraint.
  ///   * It *drops* rather than queues, and the reply already in the air
  ///     almost always ends up vouching for the points that were dropped, so
  ///     the drops cost no coverage.
  ///   * It serialises the [PoiCache.covers] decisions. Coverage is only
  ///     learned when a reply is filed, so parallel requests are blind to each
  ///     other: three in flight at once would record three overlapping discs
  ///     where one would have done. Without this slot the ask rate becomes the
  ///     request rate, roughly tripling sustained cost over new ground.
  ///
  /// It has a second job as a rendezvous for the settle — see the `wait`
  /// parameter on [_refreshPois]. The settle fires 500ms after the last
  /// movement and a refill was usually asked for under 100ms before the finger
  /// lifted, so that request is typically still in the air; waiting on it
  /// rather than starting another saves about one request per settle, which
  /// over a session is more than the entire refresh cadence is worth.
  Future<void>? _poiFetchInFlight;

  /// How long that one slot may be held.
  ///
  /// Only matters because the slot is exclusive: before, a wedged connection
  /// held up nothing, since the next point simply started its own request.
  /// Now it would hold up every one of them, and the dots would quietly stop
  /// learning anything new for the rest of the session.
  static const Duration _poiFetchTimeout = Duration(seconds: 8);

  /// Draw what is already known about a point, and go to the network only if
  /// that is nothing.
  ///
  /// The first half is synchronous and is the whole reason the cache exists:
  /// over ground the picker has already covered, the dots re-rank in the same
  /// frame the map moved, with nothing in flight.
  ///
  /// [wait] insists on an answer for this exact point, queueing behind
  /// anything already in the air. The settle passes it, because its reply
  /// decides what the pin latches onto; a mid-drag refill does not, because a
  /// dot arriving one refill late is invisible and a queued request is not
  /// free.
  Future<void> _refreshPois(
    double latitude,
    double longitude, {
    bool wait = false,
  }) async {
    _poiAnchorLat = latitude;
    _poiAnchorLng = longitude;
    _drawPoisNear(latitude, longitude);

    if (_poiFetchInFlight != null) {
      if (!wait) return;
      await _poiFetchInFlight;
      if (!mounted) return;
      // That reply may well have covered this point; if it did, there is
      // nothing left to ask.
      if (_poiFetchInFlight != null) return;
    }

    final wanted = _tilesWanted(latitude, longitude);
    if (wanted.isEmpty) return;

    // One at a time, nearest first; the next ask picks up the next one. That
    // serialisation is the rate limit — see [_poiFetchInFlight].
    final request = _fetchTile(wanted.first);
    _poiFetchInFlight = request;
    await request;
  }

  /// The tiles this pin wants that are not already held, nearest first.
  ///
  /// Usually none, because a tile is 2.4km across and placing one pin rarely
  /// leaves it. Occasionally two, when the pin sits near a boundary and the
  /// side the user is dragging towards would otherwise be bare.
  List<TileKey> _tilesWanted(double latitude, double longitude) {
    final cache = PoiCache.instance;
    final wanted = [
      for (final key
          in PoiTiles.tilesNear(latitude, longitude, _serveRadiusMetres))
        if (!cache.covers(key)) key,
    ];

    // Prefetch, at the end of the queue. This does not add a request — it aims
    // one. A tile the drag is heading into is a tile that will be asked for a
    // second later anyway; fetching it now is the difference between the dots
    // being there when the pin arrives and appearing after it.
    final ahead = _headingTowards();
    if (ahead != null) {
      final key = PoiTiles.tileFor(ahead.latitude, ahead.longitude);
      if (!cache.covers(key) && !wanted.contains(key)) wanted.add(key);
    }
    return wanted;
  }

  /// Fetch one tile and file it.
  ///
  /// The tile is filed against its own rectangle rather than against the pin,
  /// which is what retired the request-token bookkeeping this used to need: a
  /// slow reply arriving after a faster one cannot show places from somewhere
  /// the pin has left, because what gets drawn is always recomputed around the
  /// pin afterwards.
  Future<void> _fetchTile(TileKey key) async {
    try {
      final places = await PoiTiles.fetch(key).timeout(_poiFetchTimeout);
      // Null means the tile could not be had. Filing that as an empty tile
      // would claim a 2.4km rectangle nobody has seen — and now that the cache
      // survives restarts, it would keep claiming it tomorrow.
      if (places != null) PoiCache.instance.recordTile(key, places);
    } on TimeoutException {
      // Deliberately not recorded, for the same reason. Releasing the slot is
      // enough; the next ask tries again.
    } finally {
      // Cleared in the same turn the tile was filed, so anyone waiting on this
      // request wakes to a cache that already holds it and a slot that is
      // genuinely free.
      _poiFetchInFlight = null;
    }

    if (!mounted) return;
    final centre = PoiTiles.centreOf(key);
    _drawPoisNear(
      _poiAnchorLat ?? centre.latitude,
      _poiAnchorLng ?? centre.longitude,
    );
  }

  // ── Where the drag is going ─────────────────────────────────────────────

  double? _lastMoveLat;
  double? _lastMoveLng;
  DateTime? _lastMoveAt;

  /// Smoothed pin velocity, in degrees per second.
  double _velocityLat = 0;
  double _velocityLng = 0;

  /// How far ahead of the pin to look when choosing which tile to spend the
  /// next request on. About the length of a deliberate swipe.
  static const double _lookaheadSeconds = 1.5;

  /// Below this the drag is not going anywhere worth anticipating — and a tile
  /// is 2.4km across, so a short nudge cannot leave the one already held.
  static const double _minLookaheadMetres = 300;

  /// And above this a fling would project across the province.
  static const double _maxLookaheadMetres = 3000;

  /// A gap longer than this is a new gesture, not a continuation of one.
  static const double _motionGapSeconds = 0.25;

  void _trackMotion(double latitude, double longitude) {
    final at = DateTime.now();
    final previousLat = _lastMoveLat;
    final previousLng = _lastMoveLng;
    final previousAt = _lastMoveAt;

    if (previousLat != null && previousLng != null && previousAt != null) {
      final seconds = at.difference(previousAt).inMicroseconds / 1000000;
      if (seconds > 0 && seconds < _motionGapSeconds) {
        // Smoothed, because one frame's delta is noisy enough to point the
        // prefetch at the wrong neighbour.
        const smoothing = 0.35;
        _velocityLat = _velocityLat * (1 - smoothing) +
            ((latitude - previousLat) / seconds) * smoothing;
        _velocityLng = _velocityLng * (1 - smoothing) +
            ((longitude - previousLng) / seconds) * smoothing;
      } else {
        _stopTracking();
      }
    }

    _lastMoveLat = latitude;
    _lastMoveLng = longitude;
    _lastMoveAt = at;
  }

  void _stopTracking() {
    _velocityLat = 0;
    _velocityLng = 0;
  }

  /// Where the pin will be shortly, if it is going anywhere in particular.
  ({double latitude, double longitude})? _headingTowards() {
    if (_velocityLat == 0 && _velocityLng == 0) return null;
    final fromLat = _lastMoveLat;
    final fromLng = _lastMoveLng;
    if (fromLat == null || fromLng == null) return null;

    var toLat = fromLat + _velocityLat * _lookaheadSeconds;
    var toLng = fromLng + _velocityLng * _lookaheadSeconds;

    final metres =
        PlacesService.metresBetween(fromLat, fromLng, toLat, toLng);
    if (metres < _minLookaheadMetres) return null;
    if (metres > _maxLookaheadMetres) {
      final scale = _maxLookaheadMetres / metres;
      toLat = fromLat + (toLat - fromLat) * scale;
      toLng = fromLng + (toLng - fromLng) * scale;
    }
    return (latitude: toLat, longitude: toLng);
  }

  void _drawPoisNear(double latitude, double longitude) {
    final next = PoiCache.instance.around(
      latitude,
      longitude,
      limit: _poiDrawCount,
      withinMetres: _serveRadiusMetres,
    );
    // Membership only. The map re-ranks against the live pin on every frame,
    // so the same places in a different order is not a reason to rebuild the
    // page — and during a drag that order changes constantly.
    if (_samePlaces(next, _pois)) return;
    setState(() => _pois = next);
  }

  static bool _samePlaces(List<MapPoi> a, List<MapPoi> b) {
    if (a.length != b.length) return false;
    final ids = {for (final place in b) place.id};
    return a.every((place) => ids.contains(place.id));
  }

  Future<void> _reverseGeocodePin(double latitude, double longitude) async {
    // The finger is off the map; there is no direction to anticipate any more.
    _stopTracking();
    // Refresh the latch targets for wherever the map now sits, then check
    // whether the pin came to rest on one of them. This one waits: what it
    // finds decides what the pin snaps to, and latching against a half-filled
    // cache would miss the shop the user aimed at.
    await _refreshPois(latitude, longitude, wait: true);
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

    // Somewhere already asked about answers instantly and costs nothing. This
    // is the common case rather than an edge one: adjusting a pin means
    // nudging it and dragging it back, and every pause on the way is a settle
    // that used to spend its own request.
    final known = AddressCache.instance.lookup(latitude, longitude);
    if (known != null) {
      setState(() {
        _reversing = false;
        _selected = known;
        _searchCtrl.text = known.address;
      });
      return;
    }

    setState(() => _reversing = true);
    final resolved = await PlacesService.reverseGeocode(latitude, longitude);
    if (!mounted) return;

    // Only a real answer is filed. reverseGeocode returns null both when it
    // fails and when nothing matched, and neither is worth remembering.
    if (resolved != null) {
      AddressCache.instance.record(latitude, longitude, resolved.address);
    }

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
              height: _mapHeight,
              onChanged: _onPinMoved,
              // Everything this page measures in metres — the latch radius, how
              // far out to look for places — only means something against the
              // scale the map is actually drawn at.
              onZoomChanged: (zoom) {
                if (zoom == _mapZoom) return;
                setState(() => _mapZoom = zoom);
              },
              pois: _pois,
              latched: _latched,
              onPoiTapped: _latchOnto,
              // Refill while the drag is still going. Without this a drag of
              // more than a screen or so runs off the end of the batch and the
              // map goes bare until the finger comes up.
              onPoisNeeded: _refreshPois,
              onLocateMe: _useMyLocation,
              locating: _locating,
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
