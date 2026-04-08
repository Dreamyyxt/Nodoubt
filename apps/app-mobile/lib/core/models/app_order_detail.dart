import 'app_order.dart';

class AppOrderDetail extends AppOrder {
  const AppOrderDetail({
    required super.id,
    required super.listingId,
    required super.listingTitle,
    required super.listingType,
    required super.orderType,
    required super.orderStatus,
    required super.amountTotal,
    required super.buyerId,
    required super.sellerId,
    super.buyerName,
    super.sellerName,
    super.createdAt,
    super.cityCode,
    super.locationText,
    super.longitude,
    super.latitude,
    required this.events,
  });

  final List<AppOrderEvent> events;

  factory AppOrderDetail.fromJson(Map<String, dynamic> json) {
    final base = AppOrder.fromJson(json);
    final eventsJson = json['events'] as List<dynamic>? ?? const [];

    return AppOrderDetail(
      id: base.id,
      listingId: base.listingId,
      listingTitle: base.listingTitle,
      listingType: base.listingType,
      orderType: base.orderType,
      orderStatus: base.orderStatus,
      amountTotal: base.amountTotal,
      buyerId: base.buyerId,
      sellerId: base.sellerId,
      buyerName: base.buyerName,
      sellerName: base.sellerName,
      createdAt: base.createdAt,
      cityCode: base.cityCode,
      locationText: base.locationText,
      longitude: base.longitude,
      latitude: base.latitude,
      events: eventsJson
          .map((item) => AppOrderEvent.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class AppOrderEvent {
  const AppOrderEvent({
    required this.id,
    required this.eventType,
    this.operatorRole,
    this.createdAt,
  });

  final String id;
  final String eventType;
  final String? operatorRole;
  final DateTime? createdAt;

  factory AppOrderEvent.fromJson(Map<String, dynamic> json) {
    return AppOrderEvent(
      id: json['id']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      operatorRole: json['operatorRole']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
