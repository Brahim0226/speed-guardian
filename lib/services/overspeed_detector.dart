/// Pure-Dart overspeed logic (no Flutter / platform dependencies) so it can be unit tested.
///
/// The detector is fed one reading at a time and decides when the driver should be
/// warned locally and when the partner should be alerted.
enum OverspeedEvent {
  /// Nothing to do.
  none,

  /// Driver is over the limit (+ tolerance) but not for long enough yet.
  /// Useful to play a local warning sound.
  warnDriver,

  /// Over the limit for the sustained duration: alert the partner.
  alertPartner,
}

class OverspeedDetector {
  OverspeedDetector({
    this.toleranceKmh = 10,
    this.sustained = const Duration(seconds: 10),
    this.cooldown = const Duration(minutes: 5),
  });

  /// Allowed margin above the posted limit before counting as overspeed.
  final double toleranceKmh;

  /// How long the driver must stay over the limit before the partner is alerted.
  final Duration sustained;

  /// Minimum time between two partner alerts.
  final Duration cooldown;

  DateTime? _overSince;
  DateTime? _lastAlert;

  /// Feed a new reading. [limitKmh] is null when the limit is unknown, in which
  /// case nothing is triggered (we never guess).
  OverspeedEvent update({
    required double speedKmh,
    required double? limitKmh,
    required DateTime now,
  }) {
    if (limitKmh == null || speedKmh <= limitKmh + toleranceKmh) {
      _overSince = null;
      return OverspeedEvent.none;
    }

    _overSince ??= now;
    final overFor = now.difference(_overSince!);

    if (overFor < sustained) {
      return OverspeedEvent.warnDriver;
    }

    final last = _lastAlert;
    if (last != null && now.difference(last) < cooldown) {
      // Still speeding, but the partner was alerted recently.
      return OverspeedEvent.warnDriver;
    }

    _lastAlert = now;
    return OverspeedEvent.alertPartner;
  }

  /// Call when the trip ends.
  void reset() {
    _overSince = null;
    _lastAlert = null;
  }
}
