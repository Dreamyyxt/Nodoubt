class AppOrder {
  const AppOrder({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingType,
    required this.orderType,
    required this.orderStatus,
    required this.amountTotal,
    required this.buyerId,
    required this.sellerId,
    this.buyerName,
    this.sellerName,
    this.createdAt,
    this.cityCode,
    this.locationText,
    this.longitude,
    this.latitude,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String listingType;
  final String orderType;
  final String orderStatus;
  final double amountTotal;
  final String buyerId;
  final String sellerId;
  final String? buyerName;
  final String? sellerName;
  final DateTime? createdAt;
  final String? cityCode;
  final String? locationText;
  final double? longitude;
  final double? latitude;

  factory AppOrder.fromJson(Map<String, dynamic> json) {
    final listing = (json['listing'] as Map<String, dynamic>?) ?? const {};
    final amountRaw = json['amountTotal'];

    return AppOrder(
      id: json['id']?.toString() ?? '',
      listingId: listing['id']?.toString() ?? json['listingId']?.toString() ?? '',
      listingTitle: listing['title']?.toString() ?? '未命名订单',
      listingType: listing['listingType']?.toString() ?? '',
      orderType: json['orderType']?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ?? '',
      amountTotal: amountRaw is num
          ? amountRaw.toDouble()
          : double.tryParse(amountRaw?.toString() ?? '') ?? 0,
      buyerId: json['buyerId']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      buyerName: (json['buyer'] as Map<String, dynamic>?)?['nickname']?.toString(),
      sellerName: (json['seller'] as Map<String, dynamic>?)?['nickname']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      cityCode: listing['cityCode']?.toString(),
      locationText: listing['locationText']?.toString(),
      longitude: (listing['longitude'] as num?)?.toDouble(),
      latitude: (listing['latitude'] as num?)?.toDouble(),
    );
  }
}
