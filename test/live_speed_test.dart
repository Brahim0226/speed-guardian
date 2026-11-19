import 'package:flutter_test/flutter_test.dart';
import 'package:speed_guardian/services/live_speed.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 12);

  group('LiveSpeed.fromMap', () {
    test('parses numbers, limit and driving flag', () {
      final s = LiveSpeed.fromMap(
        {'speedKmh': 72, 'limitKmh': 50, 'driving': true},
        receivedAt: t0,
      );
      expect(s.speedKmh, 72);
      expect(s.limitKmh, 50);
      expect(s.driving, isTrue);
    });

    test('missing values fall back to safe defaults', () {
      final s = LiveSpeed.fromMap({}, receivedAt: t0);
      expect(s.speedKmh, 0);
      expect(s.limitKmh, isNull);
      expect(s.driving, isFalse);
    });

    test('an old first update is flagged as stale', () {
      final s = LiveSpeed.fromMap(
        {'speedKmh': 80, 'driving': true},
        receivedAt: t0,
        updatedAt: t0.subtract(const Duration(minutes: 5)),
      );
      expect(s.staleAtReceive, isTrue);
      expect(s.isActive(t0), isFalse);
    });

    test('a recent update is not stale', () {
      final s = LiveSpeed.fromMap(
        {'speedKmh': 80, 'driving': true},
        receivedAt: t0,
        updatedAt: t0.subtract(const Duration(seconds: 3)),
      );
      expect(s.staleAtReceive, isFalse);
      expect(s.isActive(t0), isTrue);
    });
  });

  group('LiveSpeed.isActive', () {
    LiveSpeed driving() => LiveSpeed(
          speedKmh: 60,
          limitKmh: 50,
          driving: true,
          receivedAt: t0,
        );

    test('active right after an update', () {
      expect(driving().isActive(t0.add(const Duration(seconds: 5))), isTrue);
    });

    test('inactive when no update arrived for too long', () {
      expect(driving().isActive(t0.add(const Duration(seconds: 25))), isFalse);
    });

    test('inactive when the driver is not driving', () {
      final s = LiveSpeed(
        speedKmh: 0,
        limitKmh: null,
        driving: false,
        receivedAt: t0,
      );
      expect(s.isActive(t0), isFalse);
    });
  });

  group('LiveSpeed.overLimit', () {
    test('true above a known limit', () {
      final s = LiveSpeed(
          speedKmh: 61, limitKmh: 60, driving: true, receivedAt: t0);
      expect(s.overLimit, isTrue);
    });

    test('false at or under the limit', () {
      final s = LiveSpeed(
          speedKmh: 60, limitKmh: 60, driving: true, receivedAt: t0);
      expect(s.overLimit, isFalse);
    });

    test('false when the limit is unknown', () {
      final s = LiveSpeed(
          speedKmh: 150, limitKmh: null, driving: true, receivedAt: t0);
      expect(s.overLimit, isFalse);
    });
  });
}
