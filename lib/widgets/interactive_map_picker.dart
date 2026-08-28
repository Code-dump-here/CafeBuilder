import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/place_location.dart';
import '../services/places_service.dart';
import '../theme/app_colors.dart';

/// A draggable map for placing a pin by hand, for when search can't find the
/// address — a new build on an unnamed lane, a site OpenStreetMap hasn't
/// mapped yet. The owner knows where their cafe is even when the geocoder
/// doesn't.
///
/// **The pin never moves; the map moves under it.** The coordinate is always
/// whatever is at the centre of the box. This is the pattern Grab and Uber
/// use, and it is better than a draggable marker for two reasons: on a phone
/// your thumb would cover the very pin you are trying to place, and it removes
/// hit-testing entirely — there is no drag target, just a translation.
///
/// Zoom is by button rather than pinch. Tiles are raster images at integer
/// zoom levels, so a fractional zoom would mean scaling them and accepting a
/// blurry map; stepping between real levels keeps every pixel sharp.
class InteractiveMapPicker extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final double height;

  /// Fires continuously while dragging. The parent debounces before reverse
  /// geocoding — a request per frame would be pointless and rude.
  final void Function(double latitude, double longitude) onChanged;

  /// Named places to draw as latch targets. The parent supplies them; passing
  /// an empty list simply hides them.
  ///
  /// They are drawn as a gradient away from the pin — the nearest is full
  /// size and named, the rest shrink and fade with distance — so the map
  /// says which place the pin is closing in on before it snaps onto it.
  final List<MapPoi> pois;

  /// The POI the pin is currently latched onto, drawn larger and labelled.
  final MapPoi? latched;

  /// Tapping a dot latches straight onto it, so a visible target does not have
  /// to be dragged onto.
  final ValueChanged<MapPoi>? onPoiTapped;

  /// Asks the parent for a batch of places around a point, because the current
  /// one has been dragged off the screen.
  ///
  /// The widget raises this rather than the parent guessing a distance,
  /// because "have we run out of dots" is a question about the viewport: it
  /// depends on the zoom and on the size of the box, both of which live here.
  /// Fires during the drag, so a long drag refills as it goes instead of
  /// leaving a blank map until the finger comes up.
  final void Function(double latitude, double longitude)? onPoisNeeded;

  const InteractiveMapPicker({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.onChanged,
    this.height = 260,
    this.pois = const [],
    this.latched,
    this.onPoiTapped,
    this.onPoisNeeded,
  });

  @override
  State<InteractiveMapPicker> createState() => _InteractiveMapPickerState();
}

class _InteractiveMapPickerState extends State<InteractiveMapPicker> {
  late double _lat = widget.initialLatitude;
  late double _lng = widget.initialLongitude;
  int _zoom = 17;

  /// True while a finger or the mouse is down, used to lift the pin slightly
  /// so it reads as "in flight" rather than settled.
  bool _dragging = false;

  /// Box width from the last layout. Kept so the zoom buttons can reason
  /// about the viewport too, not just the drag handler.
  double _boxWidth = 0;

  /// Where and when the last batch was asked for, used to throttle refills.
  double? _askedLat;
  double? _askedLng;
  DateTime _askedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// True between asking for a batch and it arriving, so the arriving batch
  /// can be anchored at the point it was actually queried from rather than
  /// wherever the pin has since been dragged to.
  bool _askPending = false;

  /// The pin position the current batch was queried at. Everything about
  /// staleness is measured from here: how far the pin has since travelled,
  /// and how far the batch itself reaches.
  late double _batchLat = widget.initialLatitude;
  late double _batchLng = widget.initialLongitude;

  static const int _minZoom = 3;
  static const int _maxZoom = 19;

  /// How much of the batch's own reach the pin may cross before the batch is
  /// treated as stale.
  ///
  /// Refilling on ground distance rather than on how many dots are left on
  /// screen, because the dots leaving is a symptom and the travel is the
  /// cause — and because the distance that matters is not the same everywhere.
  /// Measured against the live geocoder: downtown the ten places it returns
  /// all sit within 30m of the query point, so 50m of walking leaves every one
  /// of them behind and there are certainly nearer places it has not been
  /// asked about. Out at Bình Chánh the same ten span 180-506m, and 50m barely
  /// changes which is closest. Scaling the threshold by the batch's own reach
  /// is what makes one rule fit both.
  static const double _coverageFraction = 0.8;

  /// Bounds on that threshold. The floor keeps a dense city block from asking
  /// every few metres; the ceiling keeps a sparse edge-of-town batch from
  /// being carried halfway across the province.
  static const double _minRefreshMetres = 40;
  static const double _maxRefreshMetres = 400;

  /// Used when the batch came back empty, so there is no reach to scale from.
  /// Deliberately long: nothing was found here, and asking again forty metres
  /// later is unlikely to change that.
  static const double _emptyBatchRefreshMetres = 200;

  /// Floor on the gap between refills. A fling across the city should cost a
  /// few requests, not one per frame.
  static const Duration _minRefillInterval = Duration(milliseconds: 600);

  /// Floor on the spread used to normalise distances. See [_rankPois].
  static const double _minSpanMetres = 60;

  /// How far the furthest dot shrinks and fades relative to the nearest.
  static const double _minDotScale = 0.62;
  static const double _minDotOpacity = 0.34;

  /// The dot at full prominence, and the fixed box each one is centred in.
  /// The box never changes size, so re-ranking animates as a transform rather
  /// than relaying out the map.
  static const double _dotSize = 24;
  static const double _dotBox = 40;
  static const double _latchedScale = 1.45;

  /// Two speeds. While the pin is moving the emphasis has to keep up with it,
  /// so it is short enough to read as tracking rather than lagging; once the
  /// pin stops, the softer one lets the final arrangement settle visibly.
  static const Duration _liveAnimation = Duration(milliseconds: 90);
  static const Duration _settleAnimation = Duration(milliseconds: 220);

  @override
  void didUpdateWidget(covariant InteractiveMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(widget.pois, oldWidget.pois)) {
      // A batch we asked for is anchored where we asked, not where the pin has
      // drifted to during the round trip. One the parent fetched on its own —
      // on open, or after a search — belongs to wherever the pin is now.
      final askedLat = _askedLat;
      final askedLng = _askedLng;
      if (_askPending && askedLat != null && askedLng != null) {
        _batchLat = askedLat;
        _batchLng = askedLng;
      } else {
        _batchLat = _lat;
        _batchLng = _lng;
      }
      _askPending = false;
    }

    // Only follow the parent when it genuinely moved the pin somewhere else —
    // e.g. the user picked a new search result. Without this check the widget
    // would fight the drag, because the parent echoes back what we just sent.
    if (widget.initialLatitude != oldWidget.initialLatitude ||
        widget.initialLongitude != oldWidget.initialLongitude) {
      final movedFar = (widget.initialLatitude - _lat).abs() > 1e-6 ||
          (widget.initialLongitude - _lng).abs() > 1e-6;
      if (movedFar && !_dragging) {
        setState(() {
          _lat = widget.initialLatitude;
          _lng = widget.initialLongitude;
        });
      }
    }
  }

  /// Rank the POIs by distance from the pin, giving each a prominence between
  /// 1 (nearest of the batch) and 0 (furthest).
  ///
  /// Recomputed every frame against the live centre, so a dot brightens and
  /// grows as the pin closes on it and dims again as the pin moves off. That
  /// is the point of the gradient — it has to answer the drag while the drag
  /// is happening, otherwise it is telling you where you already were.
  ///
  /// This is only the drawing. Which places are in the batch is the parent's
  /// business — see [InteractiveMapPicker.onPoisNeeded] for when a new one is
  /// asked for.
  ///
  /// Relative to the batch rather than fixed metre thresholds, because the
  /// scale of "near" is completely different from one neighbourhood to the
  /// next. Measured against the live geocoder: on Nguyễn Huệ every POI it
  /// returns sits 16–30m from the pin, while out at Bình Chánh the nearest is
  /// 180m and the furthest 506m. Fixed thresholds would light up all ten dots
  /// downtown and grey out all ten on the edge of the city — in both places
  /// drawing a gradient that says nothing.
  List<_RankedPoi> _rankPois(double latitude, double longitude) {
    final pois = widget.pois;
    if (pois.isEmpty) return const [];

    final distances = [
      for (final poi in pois)
        PlacesService.metresBetween(latitude, longitude, poi.latitude, poi.longitude),
    ];

    var nearest = double.infinity;
    var furthest = 0.0;
    for (final d in distances) {
      if (d < nearest) nearest = d;
      if (d > furthest) furthest = d;
    }

    // Floored so a tight cluster is not stretched across the whole range: a
    // 14m spread downtown is not the same story as a 326m spread out of town,
    // and normalising both to 0..1 would tell it as though it were. Under the
    // floor the dots stay bunched near full prominence, which is the truth —
    // they are all equally close.
    final span = math.max(furthest - nearest, _minSpanMetres);

    final ranked = [
      for (var i = 0; i < pois.length; i++)
        _RankedPoi(
          poi: pois[i],
          distanceMetres: distances[i],
          prominence: 1.0 - ((distances[i] - nearest) / span).clamp(0.0, 1.0),
        ),
    ];
    ranked.sort((a, b) => a.distanceMetres.compareTo(b.distanceMetres));
    return ranked;
  }

  void _panBy(Offset delta, double width) {
    // Dragging the map right must move the viewport left, so the delta is
    // subtracted from the centre's world position.
    final centre = PlacesService.worldPixel(_lat, _lng, _zoom);
    final moved = PlacesService.latLngFromWorldPixel(
      centre.x - delta.dx,
      centre.y - delta.dy,
      _zoom,
    );

    setState(() {
      _lat = moved.latitude;
      _lng = moved.longitude;
    });
    widget.onChanged(_lat, _lng);
    _maybeAskForPois();
  }

  void _stepZoom(int by) {
    final next = (_zoom + by).clamp(_minZoom, _maxZoom);
    if (next == _zoom) return;
    // Zooming keeps the centre fixed, so the coordinate is unchanged and the
    // parent needs no notification — only the tiles differ.
    setState(() => _zoom = next);
    // Zooming in can empty the box just as effectively as dragging out of it.
    _maybeAskForPois();
  }

  /// How far the pin has travelled, in metres, since the current batch was
  /// queried. Real ground distance, not pixels — the same drag means something
  /// completely different at zoom 5 and at zoom 19.
  double get _metresSinceBatch =>
      PlacesService.metresBetween(_batchLat, _batchLng, _lat, _lng);

  /// How far the pin may travel before the batch is worth replacing.
  ///
  /// Scaled by how far this particular batch actually reaches: the distance
  /// from where it was queried to the furthest place it came back with. See
  /// [_coverageFraction] for why one fixed number cannot serve both a city
  /// block and the edge of the province.
  double get _refreshDistanceMetres {
    if (widget.pois.isEmpty) return _emptyBatchRefreshMetres;

    var reach = 0.0;
    for (final poi in widget.pois) {
      final d = PlacesService.metresBetween(
          _batchLat, _batchLng, poi.latitude, poi.longitude);
      if (d > reach) reach = d;
    }
    return (reach * _coverageFraction).clamp(_minRefreshMetres, _maxRefreshMetres);
  }

  /// Dots currently inside the box.
  int get _visiblePoiCount {
    if (_boxWidth <= 0) return 0;
    final centre = PlacesService.worldPixel(_lat, _lng, _zoom);
    final originX = centre.x - _boxWidth / 2;
    final originY = centre.y - widget.height / 2;

    var visible = 0;
    for (final poi in widget.pois) {
      final p = PlacesService.worldPixel(poi.latitude, poi.longitude, _zoom);
      final dx = p.x - originX;
      final dy = p.y - originY;
      if (dx >= 0 && dy >= 0 && dx <= _boxWidth && dy <= widget.height) visible++;
    }
    return visible;
  }

  /// Ask for a fresh batch once the pin has travelled far enough from where
  /// the current one was queried.
  ///
  /// The empty box is a second trigger rather than the main one. It catches
  /// what travel cannot: zooming in moves the pin nowhere at all and can still
  /// leave the box without a single dot in it.
  ///
  /// Two brakes sit in front of both triggers. Nothing is asked twice inside
  /// [_minRefillInterval], so a fling costs a handful of requests rather than
  /// one per frame; and nothing is asked twice from within [_minRefreshMetres]
  /// of the last ask, so a genuinely empty neighbourhood — where no batch will
  /// ever fill the box — is not asked the same question from the same spot.
  void _maybeAskForPois() {
    final ask = widget.onPoisNeeded;
    if (ask == null || _boxWidth <= 0) return;

    if (_metresSinceBatch < _refreshDistanceMetres && _visiblePoiCount > 0) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_askedAt) < _minRefillInterval) return;

    final askedLat = _askedLat;
    final askedLng = _askedLng;
    if (askedLat != null &&
        askedLng != null &&
        PlacesService.metresBetween(askedLat, askedLng, _lat, _lng) <
            _minRefreshMetres) {
      return;
    }

    _askedLat = _lat;
    _askedLng = _lng;
    _askedAt = now;
    _askPending = true;
    ask(_lat, _lng);
  }

  @override
  Widget build(BuildContext context) {
    if (!PlacesService.isConfigured) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Not state that affects this build — just remembered so the refill
        // check can reason about the viewport outside of layout.
        _boxWidth = width;
        final tiles = PlacesService.tileGrid(
          latitude: _lat,
          longitude: _lng,
          zoom: _zoom,
          width: width,
          height: widget.height,
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: width,
            height: widget.height,
            child: GestureDetector(
              // Scale gestures rather than pan: onScaleUpdate reports
              // focalPointDelta for a single pointer too, and Flutter refuses
              // to arbitrate both recognisers on the same widget.
              onScaleStart: (_) => setState(() => _dragging = true),
              onScaleUpdate: (details) => _panBy(details.focalPointDelta, width),
              onScaleEnd: (_) => setState(() => _dragging = false),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.splashBackground),
                  for (final tile in tiles)
                    Positioned(
                      left: tile.left,
                      top: tile.top,
                      width: PlacesService.tileSize.toDouble(),
                      height: PlacesService.tileSize.toDouble(),
                      child: Image.network(
                        tile.url,
                        fit: BoxFit.fill,
                        // Keeps the previous frame's tile on screen while the
                        // next loads, so panning doesn't strobe white.
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) =>
                            Container(color: AppColors.splashBackground),
                      ),
                    ),
                  // Under the centre pin so the pin is never obscured by a
                  // dot it is sitting on top of.
                  ..._buildPoiDots(width),
                  _buildCentrePin(),
                  _buildZoomButtons(),
                  _buildHint(),
                  _buildAttribution(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Projects each POI onto the box and draws it as a tappable dot, sized and
  /// faded by how close it is to the settled pin.
  ///
  /// Both the positions and the emphasis come from the live centre, so the
  /// gradient answers the drag as it happens.
  ///
  /// Anything outside the visible box is skipped rather than positioned off
  /// screen — a `Positioned` at -400px still builds and still costs layout.
  List<Widget> _buildPoiDots(double width) {
    final ranked = _rankPois(_lat, _lng);
    if (ranked.isEmpty) return const [];

    final centre = PlacesService.worldPixel(_lat, _lng, _zoom);
    final originX = centre.x - width / 2;
    final originY = centre.y - widget.height / 2;

    final layers = <Widget>[];
    Widget? label;

    // Furthest first, so the nearest dot — the one the pin would latch onto —
    // is painted over its neighbours rather than under them.
    for (final entry in ranked.reversed) {
      final poi = entry.poi;
      final p = PlacesService.worldPixel(poi.latitude, poi.longitude, _zoom);
      final dx = p.x - originX;
      final dy = p.y - originY;
      if (dx < -_dotBox || dy < -_dotBox ||
          dx > width + _dotBox || dy > widget.height + _dotBox) {
        continue;
      }

      final isLatched = widget.latched?.id == poi.id;

      layers.add(Positioned(
        // The box is a constant size whatever the prominence, so re-ranking
        // scales the dot inside it instead of shifting where it sits.
        left: dx - _dotBox / 2,
        top: dy - _dotBox / 2,
        width: _dotBox,
        height: _dotBox,
        child: Center(child: _buildPoiDot(entry, isLatched: isLatched)),
      ));

      // Only the nearest is named. Downtown the geocoder returns ten places
      // inside 30m, and ten overlapping labels would bury the pin they are
      // supposed to be helping aim.
      if (!isLatched && identical(entry, ranked.first)) {
        label = _buildPoiLabel(entry, dx, dy, width);
      }
    }

    if (label != null) layers.add(label);
    return layers;
  }

  /// One dot. Size and opacity carry the distance; the latched place ignores
  /// both and stays fully prominent, because it is the pin's current answer
  /// however the rest of the batch ranks.
  Widget _buildPoiDot(_RankedPoi entry, {required bool isLatched}) {
    final scale = isLatched
        ? _latchedScale
        : _minDotScale + (1 - _minDotScale) * entry.prominence;
    final opacity = isLatched
        ? 1.0
        : _minDotOpacity + (1 - _minDotOpacity) * entry.prominence;
    final duration = _dragging ? _liveAnimation : _settleAnimation;

    return AnimatedOpacity(
      duration: duration,
      opacity: opacity,
      child: AnimatedScale(
        duration: duration,
        curve: Curves.easeOut,
        scale: scale,
        child: GestureDetector(
          // The map's own drag recogniser sits above this in the tree, so a
          // tap that never moves still reaches here while a drag does not.
          //
          // Scale is a transform, and Flutter hit-tests through it, so a
          // shrunken far-away dot gets a correspondingly smaller target — it
          // cannot quietly swallow taps meant for the map around it.
          onTap: widget.onPoiTapped == null ? null : () => widget.onPoiTapped!(entry.poi),
          child: Tooltip(
            message: '${entry.poi.name} · ${_formatDistance(entry.distanceMetres)}',
            child: Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                color: isLatched ? const Color(0xFF56642B) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLatched ? Colors.white : const Color(0xFF56642B),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(blurRadius: 3, color: Colors.black26),
                ],
              ),
              child: Icon(
                _iconForCategory(entry.poi.category),
                size: 13,
                color: isLatched ? Colors.white : const Color(0xFF56642B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Names the nearest place and says how far the pin is from it.
  ///
  /// The distance is spelled out because the sizing is relative to the batch:
  /// the brightest dot means "nearest of these", not "close". Out at the edge
  /// of the city the nearest thing is 180m away, and the label is what stops
  /// a prominent dot from implying otherwise.
  ///
  /// Stays up during the drag, and follows whichever place is nearest as the
  /// pin moves. That is the whole feedback loop: you drag, and the map tells
  /// you what you are closing in on while you can still act on it. Waiting
  /// for the finger to lift would answer a question already asked.
  Widget _buildPoiLabel(_RankedPoi entry, double dx, double dy, double width) {
    // Anchored from whichever side keeps it inside the box, so a long name
    // near an edge is pushed inward instead of clipped off.
    final flip = dx > width / 2;

    // The drag hint sits in the top-left, about 150px wide. Keep the label
    // clear of it rather than stacking two white chips in the same corner.
    final minTop = !flip && dx < 150 ? 34.0 : 2.0;

    // Cap by the room actually left on the side it is anchored to, not by a
    // share of the whole box. Anchoring at dx + 16 and then allowing 55% of
    // the width lets a long name run past the right edge, where the rounded
    // clip cuts it off mid-word instead of the ellipsis doing it cleanly.
    final room = (flip ? dx - 16 : width - dx - 16) - 6;
    final maxWidth = math.max(72.0, math.min(width * 0.55, room));

    return Positioned(
      // Floored so a dot sitting right on the edge — or just outside it, still
      // within the cull margin — pushes its label inward rather than hanging
      // it off the side where the rounded clip would eat it.
      left: flip ? null : math.max(4.0, dx + 16),
      right: flip ? math.max(4.0, width - dx + 16) : null,
      top: (dy - 10).clamp(minTop, widget.height - 22),
      child: IgnorePointer(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(blurRadius: 3, color: Colors.black26),
              ],
            ),
            child: Text(
              '${entry.poi.name} · ${_formatDistance(entry.distanceMetres)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF56642B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Rounded to whole metres up to a kilometre, then to one decimal. Nobody
  /// pinning a shopfront needs '183.7 m'.
  static String _formatDistance(double metres) => metres < 950
      ? '${metres.round()} m'
      : '${(metres / 1000).toStringAsFixed(1)} km';

  /// A rough icon per OpenStreetMap category. Only the handful that actually
  /// show up around a cafe site are worth distinguishing; everything else gets
  /// a neutral dot rather than a wrong picture.
  static IconData _iconForCategory(String? category) {
    switch (category) {
      case 'cafe':
      case 'coffee shop':
        return Icons.local_cafe;
      case 'restaurant':
      case 'fast_food':
        return Icons.restaurant;
      case 'bar':
      case 'pub':
        return Icons.local_bar;
      case 'hotel':
      case 'hostel':
        return Icons.hotel;
      case 'building':
        return Icons.apartment;
      case 'shop':
      case 'clothes':
      case 'shoes':
      case 'supermarket':
        return Icons.storefront;
      case 'bank':
        return Icons.account_balance;
      case 'parking':
        return Icons.local_parking;
      default:
        return Icons.circle;
    }
  }

  Widget _buildCentrePin() {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lifted while dragging, with the shadow left behind on the ground
            // below — that gap is what makes the pin read as hovering over a
            // moving map rather than being dragged across it.
            AnimatedSlide(
              offset: Offset(0, _dragging ? -0.22 : 0),
              duration: const Duration(milliseconds: 120),
              child: const Icon(
                Icons.location_on,
                size: 40,
                color: Color(0xFFD64545),
                shadows: [Shadow(blurRadius: 5, color: Colors.black45)],
              ),
            ),
            // Sits at the exact centre — the icon above is drawn so its point
            // ends here, which is the coordinate being chosen.
            Transform.translate(
              offset: const Offset(0, -6),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomButtons() {
    return Positioned(
      right: 8,
      top: 8,
      child: Column(
        children: [
          _zoomButton(Icons.add, 'Zoom in', () => _stepZoom(1), _zoom < _maxZoom),
          const SizedBox(height: 6),
          _zoomButton(Icons.remove, 'Zoom out', () => _stepZoom(-1), _zoom > _minZoom),
        ],
      ),
    );
  }

  Widget _zoomButton(IconData icon, String tooltip, VoidCallback onTap, bool enabled) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              size: 18,
              color: enabled ? AppColors.espresso : AppColors.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// Says what the gesture does. A map that looks like a picture gets treated
  /// like one — without this, most people never discover it moves.
  Widget _buildHint() {
    return Positioned(
      left: 8,
      top: 8,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _dragging ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Drag the map to move the pin',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  /// Attribution is a licence condition of the OpenStreetMap data.
  Widget _buildAttribution() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          color: Colors.white70,
          child: const Text(
            '© MapTiler © OpenStreetMap',
            style: TextStyle(fontSize: 8, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

/// A POI with how it should be drawn, measured from the pin the last time it
/// stopped moving.
class _RankedPoi {
  final MapPoi poi;

  /// Ground distance from the settled pin. Shown on the nearest dot's label —
  /// the styling is relative to the batch, so this is where the absolute
  /// truth gets told.
  final double distanceMetres;

  /// 1 for the nearest of the batch, 0 for the furthest. Drives size and
  /// opacity together, so the dots read as a gradient away from the pin.
  final double prominence;

  const _RankedPoi({
    required this.poi,
    required this.distanceMetres,
    required this.prominence,
  });
}

/// Delays a callback until the user stops moving.
///
/// Reverse geocoding on every frame of a drag would fire hundreds of requests
/// and show an address that flickers through every street it passes over.
class MapSettleDebouncer {
  final Duration delay;
  Timer? _timer;

  MapSettleDebouncer({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();
}
