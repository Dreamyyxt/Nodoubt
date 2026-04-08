import '../../../core/network/api_client.dart';
import '../models/create_listing_input.dart';

class PublishRepository {
  const PublishRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> createListing({
    required String userId,
    required CreateListingInput input,
  }) {
    return _apiClient.createListing(userId: userId, input: input);
  }
}
