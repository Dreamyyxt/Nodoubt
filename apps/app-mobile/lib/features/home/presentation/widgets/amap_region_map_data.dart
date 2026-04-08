class AmapRegionMarkerData {
  const AmapRegionMarkerData({
    required this.id,
    required this.cityCode,
    required this.label,
    required this.longitude,
    required this.latitude,
    required this.locationText,
    required this.listingType,
    required this.totalCount,
    required this.taskCount,
    required this.exchangeCount,
  });

  final String id;
  final String cityCode;
  final String label;
  final double longitude;
  final double latitude;
  final String locationText;
  final String listingType;
  final int totalCount;
  final int taskCount;
  final int exchangeCount;

  Map<String, Object> toJson() {
    return {
      'id': id,
      'cityCode': cityCode,
      'label': label,
      'longitude': longitude,
      'latitude': latitude,
      'locationText': locationText,
      'listingType': listingType,
      'totalCount': totalCount,
      'taskCount': taskCount,
      'exchangeCount': exchangeCount,
    };
  }
}
