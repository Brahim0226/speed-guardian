import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Partner side of the alert: listens to Firestore for alerts addressed to this
/// user and shows a local notification.
///
/// This works without Cloud Functions (so without the Blaze plan), but only while
/// the app process is alive. Android may stop it in the background on some phones.
class AlertListenerService {
  AlertListenerService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'overspeed';

  /// Alerts older than this (e.g. created while the app was closed for hours)
  /// are ignored so the partner is not flooded with stale notifications.
  static const _maxAge = Duration(minutes: 15);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  final Set<String> _shown = {};
  int _nextId = 1;

  Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      'تنبيهات السرعة',
      description: 'تنبيه عندما يتجاوز الشريك السرعة المحددة',
      importance: Importance.max,
    ));
  }

  /// Start listening for alerts where `toUid == myUid`.
  void start(String myUid) {
    _sub?.cancel();
    _sub = _db
        .collection('alerts')
        .where('toUid', isEqualTo: myUid)
        .snapshots()
        .listen(_onSnapshot, onError: (_) {});
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    for (final change in snap.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      if (!_shown.add(change.doc.id)) continue;

      final data = change.doc.data();
      if (data == null) continue;

      final created = (data['createdAt'] as Timestamp?)?.toDate();
      if (created != null &&
          DateTime.now().difference(created) > _maxAge) {
        continue;
      }

      _show(
        speed: data['speedKmh'],
        limit: data['limitKmh'],
      );
    }
  }

  Future<void> _show({required Object? speed, required Object? limit}) {
    return _plugin.show(
      _nextId++,
      '⚠️ تنبيه سرعة',
      'شريكك يسوق بسرعة $speed كم/س والحد $limit كم/س',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'تنبيهات السرعة',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
