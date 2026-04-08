import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_application.dart';
import '../models/app_order_detail.dart';
import '../models/app_listing.dart';
import '../models/app_order.dart';
import '../models/app_review.dart';
import '../models/received_application.dart';
import '../models/app_user.dart';
import '../../features/applications/models/create_application_input.dart';
import '../../features/publish/models/create_listing_input.dart';

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<String> loginWithDevCode({
    required String phone,
    required String code,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'phone': phone, 'code': code}),
    );

    final body = _readBody(response);
    final headers =
        ((body['data'] as Map<String, dynamic>?)?['debugHeaders']
            as Map<String, dynamic>?) ??
        {};
    final userId = headers['x-user-id']?.toString();

    if (userId == null || userId.isEmpty) {
      throw Exception('Missing x-user-id in development login response');
    }

    return userId;
  }

  Future<AppUser> getMe(String userId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/me'),
      headers: _userHeaders(userId),
    );

    final body = _readBody(response);
    return AppUser.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<AppListing>> getListings({String? userId, bool includeMine = false}) async {
    final uri = Uri.parse('$baseUrl/listings').replace(
      queryParameters: {
        'pageSize': '100',
        if (includeMine) 'includeMine': 'true',
      },
    );
    final response = await _httpClient.get(
      uri,
      headers: userId == null ? _jsonHeaders : _userHeaders(userId),
    );

    final body = _readBody(response);
    final items =
        ((body['data'] as Map<String, dynamic>)['items'] as List<dynamic>? ??
        <dynamic>[]);

    return items
        .map((item) => AppListing.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<AppListing>> getMyListings(String userId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/me/listings'),
      headers: _userHeaders(userId),
    );

    final body = _readBody(response);
    final items = body['data'] as List<dynamic>? ?? <dynamic>[];

    return items
        .map((item) => AppListing.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<AppApplication>> getMyApplications(String userId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/me/applications'),
      headers: _userHeaders(userId),
    );

    final body = _readBody(response);
    final items = body['data'] as List<dynamic>? ?? <dynamic>[];

    return items
        .map((item) => AppApplication.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<AppOrder>> getMyOrders(String userId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/orders/me'),
      headers: _userHeaders(userId),
    );

    final body = _readBody(response);
    final items = body['data'] as List<dynamic>? ?? <dynamic>[];

    return items
        .map((item) => AppOrder.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<AppOrderDetail> getOrderDetail({
    required String userId,
    required String orderId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: _userHeaders(userId),
    );

    final body = _readBody(response);
    return AppOrderDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<ReceivedApplication>> getListingApplications({
    required String userId,
    required String listingId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/listings/$listingId/applications'),
      headers: _userHeaders(userId),
    );

    final body = _readBody(response);
    final items = body['data'] as List<dynamic>? ?? <dynamic>[];

    return items
        .map((item) => ReceivedApplication.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> createListing({
    required String userId,
    required CreateListingInput input,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/listings'),
      headers: _userHeaders(userId),
      body: jsonEncode({
        'listingType': _mapListingType(input.listingType),
        'title': input.title,
        'description': input.description,
        'categoryCode': input.categoryCode,
        'tagIds': input.tagIds,
        'cityCode': input.cityCode,
        'longitude': input.longitude,
        'latitude': input.latitude,
        'serviceMode': _mapServiceMode(input.serviceMode),
        'budgetType': _mapBudgetType(input.budgetType),
        'budgetAmount': input.budgetAmount,
        'exchangeOfferText': input.exchangeOfferText,
        'exchangeWantText': input.exchangeWantText,
        'locationText': input.locationText,
        'startTime': input.startTime?.toIso8601String(),
        'endTime': input.endTime?.toIso8601String(),
        'images': input.images,
        'isUrgent': input.isUrgent,
        'visibility': 'PUBLIC',
      }),
    );

    _readBody(response);
  }

  Future<void> createApplication({
    required String userId,
    required String listingId,
    required CreateApplicationInput input,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/listings/$listingId/applications'),
      headers: _userHeaders(userId),
      body: jsonEncode({
        'message': input.message,
        'quotedPrice': input.quotedPrice,
      }),
    );

    _readBody(response);
  }

  Future<void> withdrawApplication({
    required String userId,
    required String applicationId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/applications/$applicationId/withdraw'),
      headers: _userHeaders(userId),
    );

    _readBody(response);
  }

  Future<void> acceptApplication({
    required String userId,
    required String applicationId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/applications/$applicationId/accept'),
      headers: _userHeaders(userId),
    );

    _readBody(response);
  }

  Future<void> rejectApplication({
    required String userId,
    required String applicationId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/applications/$applicationId/reject'),
      headers: _userHeaders(userId),
    );

    _readBody(response);
  }

  Future<void> createOrder({
    required String userId,
    required String listingId,
    required String applicationId,
    required double amountTotal,
    String? remark,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/orders'),
      headers: _userHeaders(userId),
      body: jsonEncode({
        'listingId': listingId,
        'applicationId': applicationId,
        'amountTotal': amountTotal,
        'remark': remark,
      }),
    );

    _readBody(response);
  }

  Future<void> payOrder({
    required String userId,
    required String orderId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/orders/$orderId/pay'),
      headers: _userHeaders(userId),
    );

    _readBody(response);
  }

  Future<void> acceptOrder({
    required String userId,
    required String orderId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/orders/$orderId/accept'),
      headers: _userHeaders(userId),
    );

    _readBody(response);
  }

  Future<void> deliverOrder({
    required String userId,
    required String orderId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/orders/$orderId/deliver'),
      headers: _userHeaders(userId),
    );

    _readBody(response);
  }

  Future<void> confirmOrder({
    required String userId,
    required String orderId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/orders/$orderId/confirm'),
      headers: _userHeaders(userId),
    );

    _readBody(response);
  }

  Future<void> requestRefund({
    required String userId,
    required String orderId,
    required String reasonCode,
    String? description,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/orders/$orderId/refund'),
      headers: _userHeaders(userId),
      body: jsonEncode({
        'reasonCode': reasonCode,
        'description': description,
      }),
    );

    _readBody(response);
  }

  Future<void> updateListing({
    required String userId,
    required String listingId,
    required CreateListingInput input,
  }) async {
    final response = await _httpClient.patch(
      Uri.parse('$baseUrl/listings/$listingId'),
      headers: _userHeaders(userId),
      body: jsonEncode({
        'title': input.title,
        'description': input.description,
        'categoryCode': input.categoryCode,
        'tagIds': input.tagIds,
        'cityCode': input.cityCode,
        'longitude': input.longitude,
        'latitude': input.latitude,
        'serviceMode': _mapServiceMode(input.serviceMode),
        'budgetType': _mapBudgetType(input.budgetType),
        'budgetAmount': input.budgetAmount,
        'exchangeOfferText': input.exchangeOfferText,
        'exchangeWantText': input.exchangeWantText,
        'locationText': input.locationText,
        'startTime': input.startTime?.toIso8601String(),
        'endTime': input.endTime?.toIso8601String(),
        'images': input.images,
        'isUrgent': input.isUrgent,
        'visibility': 'PUBLIC',
      }),
    );

    _readBody(response);
  }

  Future<void> closeListing({
    required String userId,
    required String listingId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/listings/$listingId/close'),
      headers: _userHeaders(userId),
    );

    _readBody(response);
  }

  Future<void> createReport({
    required String userId,
    required String targetType,
    required String targetId,
    required String reasonCode,
    String? description,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/reports'),
      headers: _userHeaders(userId),
      body: jsonEncode({
        'targetType': targetType,
        'targetId': targetId,
        'reasonCode': reasonCode,
        'description': description,
      }),
    );

    _readBody(response);
  }

  Future<List<AppReview>> getOrderReviews({
    required String userId,
    required String orderId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/orders/$orderId/reviews'),
      headers: _userHeaders(userId),
    );

    final body = _readBody(response);
    final items = body['data'] as List<dynamic>? ?? <dynamic>[];

    return items
        .map((item) => AppReview.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> createOrderReview({
    required String userId,
    required String orderId,
    required int score,
    String? content,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/orders/$orderId/reviews'),
      headers: _userHeaders(userId),
      body: jsonEncode({
        'score': score,
        'content': content,
      }),
    );

    _readBody(response);
  }

  Map<String, String> _userHeaders(String userId) {
    return {..._jsonHeaders, 'x-user-id': userId};
  }

  Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _readBody(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw Exception(decoded['message']?.toString() ?? 'Request failed');
    }

    return decoded;
  }

  String _mapListingType(PublishListingType type) {
    switch (type) {
      case PublishListingType.task:
        return 'TASK';
      case PublishListingType.exchange:
        return 'EXCHANGE';
    }
  }

  String _mapServiceMode(PublishServiceMode mode) {
    switch (mode) {
      case PublishServiceMode.online:
        return 'ONLINE';
      case PublishServiceMode.offline:
        return 'OFFLINE';
      case PublishServiceMode.both:
        return 'BOTH';
    }
  }

  String? _mapBudgetType(PublishBudgetType? type) {
    switch (type) {
      case PublishBudgetType.fixed:
        return 'FIXED';
      case PublishBudgetType.negotiable:
        return 'NEGOTIABLE';
      case PublishBudgetType.freeExchange:
        return 'FREE_EXCHANGE';
      case null:
        return null;
    }
  }
}
