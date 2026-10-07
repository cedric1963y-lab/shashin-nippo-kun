import 'package:flutter_test/flutter_test.dart';
import 'package:shashin_nippo/plan/limits.dart';
import 'package:shashin_nippo/services/purchase_gateway.dart';

void main() {
  test('subscription periods are one month and one year', () {
    final start = DateTime(2026, 10, 7, 9, 30);
    expect(
      PlanLimits.periodEnd(PlanLimits.monthlyProductId, start),
      DateTime(2026, 11, 7, 9, 30),
    );
    expect(
      PlanLimits.periodEnd(PlanLimits.yearlyProductId, start),
      DateTime(2027, 10, 7, 9, 30),
    );
  });

  test('active subscription is the latest expiry that has already started', () {
    final now = DateTime(2026, 10, 7, 12);
    final active = activeSubscription([
      StoreSubscription(
        productId: PlanLimits.monthlyProductId,
        purchasedAt: DateTime(2026, 9, 1),
        expiresAt: DateTime(2026, 10, 1),
      ),
      StoreSubscription(
        productId: PlanLimits.yearlyProductId,
        purchasedAt: DateTime(2026, 10, 7, 9),
        expiresAt: DateTime(2027, 10, 7),
      ),
    ], now);
    expect(active?.productId, PlanLimits.yearlyProductId);

    final notStarted = activeSubscription([
      StoreSubscription(
        productId: PlanLimits.yearlyProductId,
        purchasedAt: DateTime(2026, 11, 1),
        expiresAt: DateTime(2027, 11, 1),
      ),
    ], now);
    expect(notStarted, isNull);
  });
}
