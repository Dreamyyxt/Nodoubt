class PricingBreakdown {
  const PricingBreakdown({
    required this.baseAmount,
    required this.serviceFeeRate,
    required this.serviceFee,
    required this.urgentBoostFee,
    required this.clientTotal,
    required this.hunterPayout,
  });

  final double baseAmount;
  final double serviceFeeRate;
  final double serviceFee;
  final double urgentBoostFee;
  final double clientTotal;
  final double hunterPayout;
}

class PricingHelper {
  static const double seedServiceFeeRate = 0.05;
  static const double standardServiceFeeRate = 0.08;
  static const double urgentBoostFee = 9.9;

  static PricingBreakdown estimate({
    required double baseAmount,
    bool isUrgent = false,
    bool useSeedRate = true,
  }) {
    final safeBase = baseAmount < 0 ? 0 : baseAmount;
    final normalizedBase = safeBase.toDouble();
    final rate = useSeedRate ? seedServiceFeeRate : standardServiceFeeRate;
    final serviceFee = normalizedBase * rate;
    final double boostFee = isUrgent ? urgentBoostFee : 0;

    return PricingBreakdown(
      baseAmount: normalizedBase,
      serviceFeeRate: rate,
      serviceFee: serviceFee,
      urgentBoostFee: boostFee,
      clientTotal: normalizedBase + serviceFee + boostFee,
      hunterPayout: normalizedBase - serviceFee,
    );
  }
}
