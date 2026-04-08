class AppListing {
  const AppListing({
    required this.id,
    required this.title,
    required this.description,
    required this.listingType,
    required this.publisherId,
    required this.publisherName,
    required this.tags,
    required this.status,
    this.cityCode,
    this.locationText,
    this.longitude,
    this.latitude,
    this.serviceMode,
    this.budgetType,
    this.budgetAmount,
    this.exchangeOfferText,
    this.exchangeWantText,
    this.isUrgent = false,
    this.isFeatured = false,
    this.featuredPriority = 0,
    this.featuredUntil,
    this.opsNote,
    this.applicationCount = 0,
    this.orderCount = 0,
    this.budgetLabel,
    this.auditReason,
    this.publisherCreditScore,
    this.publisherRatingAvg,
    this.publisherRatingCount,
    this.publisherCompletedTaskCount,
    this.publisherCompletedExchangeCount,
  });

  final String id;
  final String title;
  final String description;
  final String listingType;
  final String publisherId;
  final String publisherName;
  final List<String> tags;
  final String status;
  final String? cityCode;
  final String? locationText;
  final double? longitude;
  final double? latitude;
  final String? serviceMode;
  final String? budgetType;
  final double? budgetAmount;
  final String? exchangeOfferText;
  final String? exchangeWantText;
  final bool isUrgent;
  final bool isFeatured;
  final int featuredPriority;
  final DateTime? featuredUntil;
  final String? opsNote;
  final int applicationCount;
  final int orderCount;
  final String? budgetLabel;
  final String? auditReason;
  final int? publisherCreditScore;
  final double? publisherRatingAvg;
  final int? publisherRatingCount;
  final int? publisherCompletedTaskCount;
  final int? publisherCompletedExchangeCount;

  factory AppListing.fromJson(Map<String, dynamic> json) {
    final tagsJson = json['tagsJson'];
    final tags = tagsJson is List
        ? tagsJson.map((item) => item.toString()).toList()
        : <String>[];
    final budgetAmount = json['budgetAmount'];
    final listingType = (json['listingType'] ?? '').toString();

    String? budgetLabel;
    if (listingType == 'EXCHANGE') {
      budgetLabel = '技能交换';
    } else if (budgetAmount != null) {
      budgetLabel = '预算 ${budgetAmount.toString()}';
    }

    return AppListing(
      id: json['id'].toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      listingType: listingType,
      publisherId:
          ((json['publisher'] as Map<String, dynamic>?)?['id'] ??
                  json['publisherId'] ??
                  '')
              .toString(),
      publisherName:
          ((json['publisher'] as Map<String, dynamic>?)?['nickname'] ?? '未知用户')
              .toString(),
      tags: tags,
      status: (json['status'] ?? '').toString(),
      cityCode: json['cityCode']?.toString(),
      locationText: json['locationText']?.toString(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      serviceMode: json['serviceMode']?.toString(),
      budgetType: json['budgetType']?.toString(),
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble(),
      exchangeOfferText: json['exchangeOfferText']?.toString(),
      exchangeWantText: json['exchangeWantText']?.toString(),
      isUrgent: json['isUrgent'] == true,
      isFeatured: json['isFeatured'] == true,
      featuredPriority: (json['featuredPriority'] as num?)?.toInt() ?? 0,
      featuredUntil: json['featuredUntil'] == null
          ? null
          : DateTime.tryParse(json['featuredUntil'].toString()),
      opsNote: json['opsNote']?.toString(),
      applicationCount:
          (((json['_count'] as Map<String, dynamic>?)?['applications']) as num?)
              ?.toInt() ??
          0,
      orderCount:
          (((json['_count'] as Map<String, dynamic>?)?['orders']) as num?)
              ?.toInt() ??
          0,
      budgetLabel: budgetLabel,
      auditReason: json['auditReason']?.toString(),
      publisherCreditScore:
          ((json['publisher'] as Map<String, dynamic>?)?['creditScore'] as num?)
              ?.toInt(),
      publisherRatingAvg:
          ((json['publisher'] as Map<String, dynamic>?)?['ratingAvg'] as num?)
              ?.toDouble(),
      publisherRatingCount:
          ((json['publisher'] as Map<String, dynamic>?)?['ratingCount'] as num?)
              ?.toInt(),
      publisherCompletedTaskCount:
          ((json['publisher'] as Map<String, dynamic>?)?['completedTaskCount']
                  as num?)
              ?.toInt(),
      publisherCompletedExchangeCount:
          ((json['publisher'] as Map<String, dynamic>?)?['completedExchangeCount']
                  as num?)
              ?.toInt(),
    );
  }
}
