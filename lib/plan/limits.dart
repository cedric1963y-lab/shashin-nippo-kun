/// Free tier and the App Store subscription products.
/// Prices are set in App Store Connect. The labels are the Japan fallbacks.
abstract final class PlanLimits {
  static const freeReportLimit = 3;
  static const freePhotoLimit = 20;
  static const maxPhotosPerReport = 30;

  static const monthlyProductId = 'jp.shashinnippo.app.premium.monthly';
  static const yearlyProductId = 'jp.shashinnippo.app.premium.yearly';
  static const monthlyPriceYen = 100;
  static const yearlyPriceYen = 1200;
  static const monthlyPriceLabel = '¥100';
  static const yearlyPriceLabel = '¥1,200';
  static const bundleId = 'jp.shashinnippo.app';

  static const premiumProductIds = {monthlyProductId, yearlyProductId};

  static bool isPremiumProduct(String productId) {
    return premiumProductIds.contains(productId);
  }

  static String priceLabelFor(String productId) {
    if (productId == yearlyProductId) return yearlyPriceLabel;
    return monthlyPriceLabel;
  }

  static String planName(String? productId) {
    if (productId == yearlyProductId) return '年額';
    if (productId == monthlyProductId) return '月額';
    return 'プレミアム';
  }

  /// Used only when StoreKit does not send an expiration date.
  static DateTime periodEnd(String productId, DateTime purchasedAt) {
    final local = purchasedAt.toLocal();
    final months = productId == yearlyProductId ? 12 : 1;
    return DateTime(
      local.year,
      local.month + months,
      local.day,
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
      local.microsecond,
    );
  }

  static bool canAddPhoto({required bool premium, required int photoCount}) {
    return premium || photoCount < freePhotoLimit;
  }

  static bool canCreateReport({
    required bool premium,
    required int reportCount,
  }) {
    return premium || reportCount < freeReportLimit;
  }
}

abstract final class AppInfo {
  static const name = '写真日報くん';
  static const version = '1.0.0';
  static const tagline = '現場の写真を、その日の日報に。';
}
