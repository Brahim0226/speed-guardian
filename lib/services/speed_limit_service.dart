import 'dart:convert';

import 'package:http/http.dart' as http;

/// Looks up the posted speed limit of the road near a coordinate using
/// OpenStreetMap's Overpass API (the `maxspeed` tag).
///
/// Coverage varies by country (it is incomplete in many areas of Algeria), so
/// this returns null when unknown and the caller must not trigger alerts then.
class SpeedLimitService {
  SpeedLimitService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  // Avoid hammering the API: reuse the last answer while the car stays close.
  double? _lastLat;
  double? _lastLon;
  double? _lastLimit;
  DateTime? _lastFetch;

  /// Returns the speed limit in km/h, or null if unknown.
  Future<double?> limitAt(double lat, double lon) async {
    final now = DateTime.now();
    if (_lastFetch != null &&
        now.difference(_lastFetch!) < const Duration(seconds: 20) &&
        _lastLat != null &&
        (lat - _lastLat!).abs() < 0.0003 &&
        (lon - _lastLon!).abs() < 0.0003) {
      return _lastLimit;
    }

    final query = '[out:json][timeout:8];'
        'way(around:25,$lat,$lon)["highway"]["maxspeed"];'
        'out tags 1;';

    try {
      final res = await _client
          .post(Uri.parse(_endpoint), body: {'data': query})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return _lastLimit;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final elements = (data['elements'] as List?) ?? const [];
      double? limit;
      if (elements.isNotEmpty) {
        final tags = (elements.first as Map)['tags'] as Map?;
        limit = parseMaxspeed(tags?['maxspeed'] as String?);
      }

      _lastLat = lat;
      _lastLon = lon;
      _lastLimit = limit;
      _lastFetch = now;
      return limit;
    } catch (_) {
      // Network error: keep the last known value rather than guessing.
      return _lastLimit;
    }
  }

  /// Parses OSM `maxspeed` values such as "50", "50 km/h" or "30 mph".
  /// Returns km/h, or null for values we cannot use ("none", "signals", ...).
  static double? parseMaxspeed(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'^\s*(\d+(?:\.\d+)?)\s*(mph|km/h)?\s*$')
        .firstMatch(raw.toLowerCase());
    if (match == null) return null;
    final value = double.parse(match.group(1)!);
    return match.group(2) == 'mph' ? value * 1.609344 : value;
  }
}
