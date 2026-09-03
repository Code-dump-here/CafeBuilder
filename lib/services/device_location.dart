import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Why the device could not say where it is.
///
/// Separate cases rather than one failure, because each needs a different
/// thing from the user: turn the radio on, answer the prompt, go to settings,
/// or just try again. A single "couldn't get your location" leaves them with
/// no idea which.
enum LocationFailure {
  /// Location services are switched off on the device itself.
  serviceDisabled,

  /// The prompt was shown and declined. Asking again later is allowed.
  permissionDenied,

  /// Declined in a way the OS will not prompt about again — only a trip to
  /// system settings changes it.
  permissionDeniedForever,

  /// Allowed, but no fix arrived in time. Usually indoors.
  timedOut,

  /// Anything else: no hardware, a platform error, an unsupported browser.
  unavailable,
}

sealed class DeviceLocationResult {
  const DeviceLocationResult();
}

final class DeviceLocationFound extends DeviceLocationResult {
  final double latitude;
  final double longitude;

  /// The radius the platform believes the fix is good to, in metres.
  ///
  /// Worth surfacing rather than hiding: a 2km cell-tower fix and a 5m GPS fix
  /// look identical on the map, and the user is about to save one of them as
  /// their cafe's address.
  final double accuracyMetres;

  const DeviceLocationFound({
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
  });
}

final class DeviceLocationFailed extends DeviceLocationResult {
  final LocationFailure reason;

  const DeviceLocationFailed(this.reason);
}

/// Where the device is, for the "use my location" button on the map picker.
///
/// Never throws. Every way this can go wrong is a [LocationFailure] the caller
/// can explain, because all of them are ordinary — the radio is off, the
/// prompt was declined, the user is indoors — and none of them should cost
/// them the pin they were placing by hand.
///
/// Wording of the messages lives with the caller, not here. This layer reports
/// what happened; the screen decides how to say it.
class DeviceLocation {
  /// How long to wait for a fix.
  ///
  /// Generous, because a cold start with no recent fix genuinely takes this
  /// long on a phone that has just been switched on — and short enough that a
  /// user standing indoors gets told so rather than watching a spinner.
  static const Duration _fixTimeout = Duration(seconds: 12);

  /// How long a platform call that needs no human answer may take.
  ///
  /// A plugin that cannot say whether the radio is on within five seconds is
  /// wedged, and without this the button spins for as long as the picker stays
  /// open — the fix itself was the only step with a time limit, and it is the
  /// last one. Observed: under a Flutter test binding these channels never
  /// answer at all.
  ///
  /// Deliberately not applied to the permission prompt. A person is reading
  /// that one, and five seconds is not long enough to decide whether to let an
  /// app track you.
  static const Duration _platformTimeout = Duration(seconds: 5);

  static Future<DeviceLocationResult> current() async {
    try {
      // Checked first because the permission prompt is pointless while the
      // radio is off: the user grants it and then still gets nothing.
      if (!await _bounded(Geolocator.isLocationServiceEnabled())) {
        return const DeviceLocationFailed(LocationFailure.serviceDisabled);
      }

      var permission = await _bounded(Geolocator.checkPermission());
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const DeviceLocationFailed(
          LocationFailure.permissionDeniedForever,
        );
      }
      if (permission == LocationPermission.denied) {
        return const DeviceLocationFailed(LocationFailure.permissionDenied);
      }

      final position = await Geolocator.getCurrentPosition(
        // High rather than best: the difference is a few metres and several
        // seconds, and this is picking a street address, not navigating.
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _fixTimeout,
        ),
      );

      return DeviceLocationFound(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMetres: position.accuracy,
      );
    } on _PlatformNotAnswering {
      // Distinct from the case below on purpose. A fix that times out means
      // the sky is blocked and trying again outdoors will work; a platform
      // that never answers means the feature is not there at all, and telling
      // someone to step outside would be a lie.
      return const DeviceLocationFailed(LocationFailure.unavailable);
    } on LocationServiceDisabledException {
      return const DeviceLocationFailed(LocationFailure.serviceDisabled);
    } on PermissionDeniedException {
      return const DeviceLocationFailed(LocationFailure.permissionDenied);
    } on TimeoutException {
      return const DeviceLocationFailed(LocationFailure.timedOut);
    } catch (_) {
      // Deliberately broad. The platform channels raise their own types on
      // every OS, a browser can refuse for reasons of its own, and none of it
      // is worth an unhandled exception in the middle of placing a pin.
      return const DeviceLocationFailed(LocationFailure.unavailable);
    }
  }

  /// Opens the OS location settings, for when permission is denied for good
  /// and the button alone can no longer fix it.
  static Future<void> openSettings() => Geolocator.openAppSettings();

  static Future<T> _bounded<T>(Future<T> call) => call.timeout(
        _platformTimeout,
        onTimeout: () => throw const _PlatformNotAnswering(),
      );
}

/// A platform call that should have been instant never came back.
class _PlatformNotAnswering implements Exception {
  const _PlatformNotAnswering();
}
