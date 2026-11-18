/// Where the speed limit currently in use comes from.
enum LimitSource { manual, map, unknown }

class ResolvedLimit {
  const ResolvedLimit(this.kmh, this.source);

  /// Limit in km/h, or null when unknown.
  final double? kmh;
  final LimitSource source;
}

/// A limit chosen by the user always wins over the map: OpenStreetMap data is
/// incomplete in many places, and the driver or passenger knows the posted sign.
/// With no manual choice, the map value is used; if neither exists the limit is
/// unknown and no alert is sent.
ResolvedLimit resolveLimit({double? manualKmh, double? mapKmh}) {
  if (manualKmh != null) return ResolvedLimit(manualKmh, LimitSource.manual);
  if (mapKmh != null) return ResolvedLimit(mapKmh, LimitSource.map);
  return const ResolvedLimit(null, LimitSource.unknown);
}
