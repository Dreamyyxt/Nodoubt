import '../../../core/models/app_listing.dart';
import 'create_listing_input.dart';

class EditListingArgs {
  const EditListingArgs({
    required this.listingId,
    required this.input,
  });

  final String listingId;
  final CreateListingInput input;

  factory EditListingArgs.fromListing(AppListing listing) {
    return EditListingArgs(
      listingId: listing.id,
      input: CreateListingInput(
        listingType: switch (listing.listingType) {
          'EXCHANGE' => PublishListingType.exchange,
          _ => PublishListingType.task,
        },
        title: listing.title,
        description: listing.description,
        serviceMode: switch (listing.serviceMode) {
          'ONLINE' => PublishServiceMode.online,
          'BOTH' => PublishServiceMode.both,
          _ => PublishServiceMode.offline,
        },
        cityCode: listing.cityCode ?? 'shanghai',
        budgetType: switch (listing.budgetType) {
          'NEGOTIABLE' => PublishBudgetType.negotiable,
          'FREE_EXCHANGE' => PublishBudgetType.freeExchange,
          _ => listing.listingType == 'EXCHANGE'
              ? PublishBudgetType.freeExchange
              : PublishBudgetType.fixed,
        },
        budgetAmount: listing.budgetAmount ?? _parseBudget(listing.budgetLabel),
        exchangeOfferText: listing.exchangeOfferText,
        exchangeWantText: listing.exchangeWantText,
        locationText: listing.locationText,
        isUrgent: listing.isUrgent,
      ),
    );
  }

  static double? _parseBudget(String? label) {
    if (label == null) {
      return null;
    }

    final digits = RegExp(r'(\d+(\.\d+)?)').firstMatch(label)?.group(1);
    return digits == null ? null : double.tryParse(digits);
  }
}
