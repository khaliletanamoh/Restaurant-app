import 'package:addis_delight/core/utils/formatters.dart';
import 'package:addis_delight/features/orders/order_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeEthiopianPhone', () {
    test('accepts common formats', () {
      expect(normalizeEthiopianPhone('0911234567'), '+251911234567');
      expect(normalizeEthiopianPhone('911 234 567'), '+251911234567');
      expect(normalizeEthiopianPhone('+251-711-234-567'), '+251711234567');
      expect(normalizeEthiopianPhone('251911234567'), '+251911234567');
    });

    test('rejects invalid numbers', () {
      expect(normalizeEthiopianPhone('12345'), isNull);
      expect(normalizeEthiopianPhone('0811234567'), isNull);
    });
  });

  group('OrderStatus.next', () {
    test('takeaway skips outForDelivery', () {
      expect(OrderStatus.ready.next(OrderType.takeaway), OrderStatus.completed);
    });

    test('delivery goes through outForDelivery', () {
      expect(OrderStatus.ready.next(OrderType.delivery), OrderStatus.outForDelivery);
      expect(OrderStatus.outForDelivery.next(OrderType.delivery), OrderStatus.completed);
    });

    test('finished orders have no next status', () {
      expect(OrderStatus.completed.next(OrderType.dineIn), isNull);
      expect(OrderStatus.cancelled.next(OrderType.dineIn), isNull);
    });
  });

  test('addisDateKey uses UTC+3', () {
    expect(addisDateKey(DateTime.utc(2026, 1, 1, 22, 30)), '2026-01-02');
  });
}
