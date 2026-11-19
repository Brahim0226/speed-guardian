/// The driver's live status as seen by the partner. Pure Dart (no Firebase) so it
/// can be unit tested.
class LiveSpeed {
  const LiveSpeed({
    required this.speedKmh,
    required this.limitKmh,
    required this.driving,
    required this.receivedAt,
    this.staleAtReceive = false,
  });

  final double speedKmh;
  final double? limitKmh;
  final bool driving;

  /// Local time when this update reached the partner's phone. Freshness is judged
  /// from this, not from the driver's clock, so wrong phone clocks do not matter.
  final DateTime receivedAt;

  /// True when the very first update we received was already old (for example the
  /// driver's app died while "driving" was still true).
  final bool staleAtReceive;

  /// The driver sends an update every few seconds; no update for this long means
  /// the data cannot be trusted any more.
  static const freshFor = Duration(seconds: 20);

  /// Older than this when received = leftover from a previous trip.
  static const maxAgeAtReceive = Duration(minutes: 2);

  bool isActive(DateTime now) =>
      driving && !staleAtReceive && now.difference(receivedAt) <= freshFor;

  bool get overLimit => limitKmh != null && speedKmh > limitKmh!;

  factory LiveSpeed.fromMap(
    Map<String, dynamic> map, {
    required DateTime receivedAt,
    DateTime? updatedAt,
  }) {
    return LiveSpeed(
      speedKmh: (map['speedKmh'] as num?)?.toDouble() ?? 0,
      limitKmh: (map['limitKmh'] as num?)?.toDouble(),
      driving: map['driving'] == true,
      receivedAt: receivedAt,
      staleAtReceive: updatedAt != null &&
          receivedAt.difference(updatedAt) > maxAgeAtReceive,
    );
  }
}
