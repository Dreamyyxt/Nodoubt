class AppApplication {
  const AppApplication({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingType,
    required this.listingStatus,
    required this.message,
    required this.status,
    this.publisherId,
    this.publisherName,
    this.cityCode,
    this.quotedPrice,
    this.createdAt,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String listingType;
  final String listingStatus;
  final String message;
  final String status;
  final String? publisherId;
  final String? publisherName;
  final String? cityCode;
  final double? quotedPrice;
  final DateTime? createdAt;

  factory AppApplication.fromJson(Map<String, dynamic> json) {
    final listing = (json['listing'] as Map<String, dynamic>?) ?? const {};
    final quotedPriceRaw = json['quotedPrice'];

    return AppApplication(
      id: json['id'].toString(),
      listingId: listing['id']?.toString() ?? '',
      listingTitle: listing['title']?.toString() ?? '未命名发布',
      listingType: listing['listingType']?.toString() ?? '',
      listingStatus: listing['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      publisherId: (listing['publisher'] as Map<String, dynamic>?)?['id']?.toString(),
      publisherName:
          (listing['publisher'] as Map<String, dynamic>?)?['nickname']?.toString(),
      cityCode: listing['cityCode']?.toString(),
      quotedPrice: quotedPriceRaw is num
          ? quotedPriceRaw.toDouble()
          : double.tryParse(quotedPriceRaw?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
