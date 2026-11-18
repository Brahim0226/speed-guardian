import 'package:flutter_test/flutter_test.dart';
import 'package:speed_guardian/services/limit_resolver.dart';

void main() {
  group('resolveLimit', () {
    test('manual limit wins over the map', () {
      final r = resolveLimit(manualKmh: 80, mapKmh: 50);
      expect(r.kmh, 80);
      expect(r.source, LimitSource.manual);
    });

    test('manual limit is used when the map has nothing', () {
      final r = resolveLimit(manualKmh: 100);
      expect(r.kmh, 100);
      expect(r.source, LimitSource.manual);
    });

    test('map limit is used without a manual choice', () {
      final r = resolveLimit(mapKmh: 50);
      expect(r.kmh, 50);
      expect(r.source, LimitSource.map);
    });

    test('unknown when neither is available', () {
      final r = resolveLimit();
      expect(r.kmh, isNull);
      expect(r.source, LimitSource.unknown);
    });
  });
}
