import 'package:flutter_test/flutter_test.dart';
import 'package:speed_guardian/services/overspeed_detector.dart';
import 'package:speed_guardian/services/speed_limit_service.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 12);

  group('OverspeedDetector', () {
    test('does nothing under limit + tolerance', () {
      final d = OverspeedDetector();
      final e = d.update(speedKmh: 59, limitKmh: 50, now: t0);
      expect(e, OverspeedEvent.none);
    });

    test('does nothing when the limit is unknown', () {
      final d = OverspeedDetector();
      final e = d.update(speedKmh: 150, limitKmh: null, now: t0);
      expect(e, OverspeedEvent.none);
    });

    test('warns the driver first, then alerts after the sustained duration', () {
      final d = OverspeedDetector();
      expect(d.update(speedKmh: 80, limitKmh: 50, now: t0),
          OverspeedEvent.warnDriver);
      expect(
          d.update(
              speedKmh: 80,
              limitKmh: 50,
              now: t0.add(const Duration(seconds: 5))),
          OverspeedEvent.warnDriver);
      expect(
          d.update(
              speedKmh: 80,
              limitKmh: 50,
              now: t0.add(const Duration(seconds: 10))),
          OverspeedEvent.alertPartner);
    });

    test('slowing down resets the timer', () {
      final d = OverspeedDetector();
      d.update(speedKmh: 80, limitKmh: 50, now: t0);
      d.update(
          speedKmh: 45,
          limitKmh: 50,
          now: t0.add(const Duration(seconds: 6)));
      final e = d.update(
          speedKmh: 80,
          limitKmh: 50,
          now: t0.add(const Duration(seconds: 12)));
      expect(e, OverspeedEvent.warnDriver);
    });

    test('respects the cooldown between alerts', () {
      final d = OverspeedDetector();
      d.update(speedKmh: 80, limitKmh: 50, now: t0);
      final first = d.update(
          speedKmh: 80,
          limitKmh: 50,
          now: t0.add(const Duration(seconds: 10)));
      expect(first, OverspeedEvent.alertPartner);

      final second = d.update(
          speedKmh: 80,
          limitKmh: 50,
          now: t0.add(const Duration(minutes: 2)));
      expect(second, OverspeedEvent.warnDriver);

      final third = d.update(
          speedKmh: 80,
          limitKmh: 50,
          now: t0.add(const Duration(minutes: 6)));
      expect(third, OverspeedEvent.alertPartner);
    });
  });

  group('SpeedLimitService.parseMaxspeed', () {
    test('plain number', () => expect(SpeedLimitService.parseMaxspeed('50'), 50));
    test('with unit',
        () => expect(SpeedLimitService.parseMaxspeed('80 km/h'), 80));
    test('mph converted', () {
      expect(SpeedLimitService.parseMaxspeed('30 mph'), closeTo(48.28, 0.01));
    });
    test('unusable values', () {
      expect(SpeedLimitService.parseMaxspeed('none'), isNull);
      expect(SpeedLimitService.parseMaxspeed('signals'), isNull);
      expect(SpeedLimitService.parseMaxspeed(null), isNull);
    });
  });
}
