import 'package:cloud_firestore/cloud_firestore.dart';

import 'live_speed.dart';

/// Shares the driver's current speed (never the location) with the paired partner
/// through the Firestore document `live/{uid}`.
class LiveSpeedService {
  LiveSpeedService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Limit the number of writes (the free plan has a daily quota).
  static const _minInterval = Duration(seconds: 4);
  DateTime? _lastSent;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('live').doc(uid);

  /// Publish the current speed. Throttled unless [force] is true. Never throws:
  /// a failed update must not interrupt speed monitoring.
  Future<void> publish({
    required String uid,
    required double speedKmh,
    double? limitKmh,
    bool force = false,
  }) async {
    final now = DateTime.now();
    final last = _lastSent;
    if (!force && last != null && now.difference(last) < _minInterval) return;
    _lastSent = now;
    try {
      await _doc(uid).set({
        'speedKmh': speedKmh.round(),
        'limitKmh': limitKmh?.round(),
        'driving': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Mark the driver as not driving.
  Future<void> stop(String uid) async {
    _lastSent = null;
    try {
      await _doc(uid).set({
        'speedKmh': 0,
        'limitKmh': null,
        'driving': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Live status of [partnerUid]. Cached snapshots are ignored so an old value
  /// stored on the phone is never shown as if it were current.
  Stream<LiveSpeed?> watch(String partnerUid) {
    return _doc(partnerUid)
        .snapshots()
        .where((snap) => !snap.metadata.isFromCache)
        .map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return LiveSpeed.fromMap(
        data,
        receivedAt: DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );
    });
  }
}
