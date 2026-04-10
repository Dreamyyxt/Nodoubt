enum PublishListingType { task, exchange }

enum PublishTaskCategory {
  companionship,
  together,
  lifestyle,
  kindness,
  skill,
}

enum PublishServiceMode { online, offline, both }

enum PublishBudgetType { fixed, negotiable, freeExchange }

class CreateListingInput {
  const CreateListingInput({
    required this.listingType,
    required this.title,
    required this.description,
    required this.serviceMode,
    required this.cityCode,
    this.longitude,
    this.latitude,
    this.categoryCode,
    this.taskCategory,
    this.tagIds = const [],
    this.budgetType,
    this.budgetAmount,
    this.exchangeOfferText,
    this.exchangeWantText,
    this.locationText,
    this.startTime,
    this.endTime,
    this.images = const [],
    this.isUrgent = false,
  });

  final PublishListingType listingType;
  final String title;
  final String description;
  final PublishServiceMode serviceMode;
  final String cityCode;
  final double? longitude;
  final double? latitude;
  final String? categoryCode;
  final PublishTaskCategory? taskCategory;
  final List<String> tagIds;
  final PublishBudgetType? budgetType;
  final double? budgetAmount;
  final String? exchangeOfferText;
  final String? exchangeWantText;
  final String? locationText;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String> images;
  final bool isUrgent;
}
