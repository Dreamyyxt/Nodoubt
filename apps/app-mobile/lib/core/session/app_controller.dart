import 'package:flutter/foundation.dart';

import '../models/app_application.dart';
import '../config/app_config.dart';
import '../models/app_listing.dart';
import '../models/app_order_detail.dart';
import '../models/app_order.dart';
import '../models/app_review.dart';
import '../models/received_application.dart';
import '../models/app_user.dart';
import '../network/api_client.dart';
import '../../features/applications/models/create_application_input.dart';
import '../../features/publish/data/publish_repository.dart';
import '../../features/publish/models/create_listing_input.dart';

enum AppBootstrapStatus { idle, loading, ready, error }

class AppController extends ChangeNotifier {
  AppController({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(baseUrl: AppConfig.defaultBaseUrl),
      _publishRepository = PublishRepository(
        apiClient ?? ApiClient(baseUrl: AppConfig.defaultBaseUrl),
      );

  static const _devPhone = '13800000000';
  static const _devCode = '123456';

  final ApiClient _apiClient;
  final PublishRepository _publishRepository;

  String? _userId;
  AppUser? _currentUser;
  List<AppListing> _listings = const [];
  List<AppListing> _myListings = const [];
  List<AppApplication> _myApplications = const [];
  List<AppOrder> _myOrders = const [];
  AppBootstrapStatus _status = AppBootstrapStatus.idle;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  List<AppListing> get listings => _listings;
  List<AppListing> get myListings => _myListings;
  List<AppApplication> get myApplications => _myApplications;
  List<AppOrder> get myOrders => _myOrders;
  AppBootstrapStatus get status => _status;
  bool get isBootstrapping => _status == AppBootstrapStatus.loading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _userId != null;
  String get devPhone => _devPhone;
  String get baseUrl => _apiClient.baseUrl;
  String? get userId => _userId;

  Future<void> login({String phone = _devPhone, String code = _devCode}) async {
    if (isBootstrapping) {
      return;
    }

    _status = AppBootstrapStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _userId = await _apiClient.loginWithDevCode(phone: phone, code: code);

      await Future.wait([
        reloadMe(),
        reloadListings(),
        reloadMyListings(),
        reloadMyApplications(),
        reloadMyOrders(),
      ]);

      _status = AppBootstrapStatus.ready;
    } catch (error) {
      _errorMessage = error.toString();
      _status = AppBootstrapStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> reloadMe() async {
    if (_userId == null) {
      return;
    }

    _currentUser = await _apiClient.getMe(_userId!);
    notifyListeners();
  }

  Future<void> reloadListings() async {
    _listings = await _apiClient.getListings(
      userId: _userId,
      includeMine: _userId != null,
    );
    notifyListeners();
  }

  Future<void> reloadMyListings() async {
    if (_userId == null) {
      return;
    }

    _myListings = await _apiClient.getMyListings(_userId!);
    notifyListeners();
  }

  Future<void> reloadMyApplications() async {
    if (_userId == null) {
      return;
    }

    _myApplications = await _apiClient.getMyApplications(_userId!);
    notifyListeners();
  }

  Future<void> reloadMyOrders() async {
    if (_userId == null) {
      return;
    }

    _myOrders = await _apiClient.getMyOrders(_userId!);
    notifyListeners();
  }

  Future<void> refreshAll() async {
    if (_userId == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        reloadMe(),
        reloadListings(),
        reloadMyListings(),
        reloadMyApplications(),
        reloadMyOrders(),
      ]);
      _status = AppBootstrapStatus.ready;
    } catch (error) {
      _errorMessage = error.toString();
      _status = AppBootstrapStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> createListing(CreateListingInput input) async {
    if (_userId == null) {
      throw Exception('Please login before creating a listing');
    }

    await _publishRepository.createListing(userId: _userId!, input: input);
    await reloadListings();
    await reloadMyListings();
  }

  Future<void> updateListing({
    required String listingId,
    required CreateListingInput input,
  }) async {
    if (_userId == null) {
      throw Exception('Please login before updating a listing');
    }

    await _apiClient.updateListing(
      userId: _userId!,
      listingId: listingId,
      input: input,
    );
    await refreshAll();
  }

  Future<void> closeListing(String listingId) async {
    if (_userId == null) {
      throw Exception('Please login before closing a listing');
    }

    await _apiClient.closeListing(
      userId: _userId!,
      listingId: listingId,
    );
    await refreshAll();
  }

  Future<void> createListingReport({
    required String listingId,
    required String reasonCode,
    String? description,
  }) async {
    if (_userId == null) {
      throw Exception('Please login before creating a report');
    }

    await _apiClient.createReport(
      userId: _userId!,
      targetType: 'LISTING',
      targetId: listingId,
      reasonCode: reasonCode,
      description: description,
    );
  }

  Future<void> createApplication({
    required String listingId,
    required CreateApplicationInput input,
  }) async {
    if (_userId == null) {
      throw Exception('Please login before creating an application');
    }

    await _apiClient.createApplication(
      userId: _userId!,
      listingId: listingId,
      input: input,
    );
    await reloadMyApplications();
  }

  Future<void> withdrawApplication(String applicationId) async {
    if (_userId == null) {
      throw Exception('Please login before withdrawing an application');
    }

    await _apiClient.withdrawApplication(
      userId: _userId!,
      applicationId: applicationId,
    );
    await reloadMyApplications();
  }

  Future<List<ReceivedApplication>> getListingApplications(String listingId) async {
    if (_userId == null) {
      throw Exception('Please login before viewing applications');
    }

    return _apiClient.getListingApplications(
      userId: _userId!,
      listingId: listingId,
    );
  }

  Future<void> acceptApplication(String applicationId) async {
    if (_userId == null) {
      throw Exception('Please login before accepting an application');
    }

    await _apiClient.acceptApplication(
      userId: _userId!,
      applicationId: applicationId,
    );
  }

  Future<void> rejectApplication(String applicationId) async {
    if (_userId == null) {
      throw Exception('Please login before rejecting an application');
    }

    await _apiClient.rejectApplication(
      userId: _userId!,
      applicationId: applicationId,
    );
  }

  Future<void> createOrder({
    required String listingId,
    required String applicationId,
    required double amountTotal,
    String? remark,
  }) async {
    if (_userId == null) {
      throw Exception('Please login before creating an order');
    }

    await _apiClient.createOrder(
      userId: _userId!,
      listingId: listingId,
      applicationId: applicationId,
      amountTotal: amountTotal,
      remark: remark,
    );
    await reloadMyOrders();
    await reloadMyListings();
  }

  Future<void> payOrder(String orderId) async {
    if (_userId == null) {
      throw Exception('Please login before paying an order');
    }

    await _apiClient.payOrder(
      userId: _userId!,
      orderId: orderId,
    );
    await refreshAll();
  }

  Future<void> acceptOrder(String orderId) async {
    if (_userId == null) {
      throw Exception('Please login before accepting an order');
    }

    await _apiClient.acceptOrder(
      userId: _userId!,
      orderId: orderId,
    );
    await refreshAll();
  }

  Future<void> deliverOrder(String orderId) async {
    if (_userId == null) {
      throw Exception('Please login before delivering an order');
    }

    await _apiClient.deliverOrder(
      userId: _userId!,
      orderId: orderId,
    );
    await refreshAll();
  }

  Future<void> confirmOrder(String orderId) async {
    if (_userId == null) {
      throw Exception('Please login before confirming an order');
    }

    await _apiClient.confirmOrder(
      userId: _userId!,
      orderId: orderId,
    );
    await refreshAll();
  }

  Future<void> requestRefund({
    required String orderId,
    required String reasonCode,
    String? description,
  }) async {
    if (_userId == null) {
      throw Exception('Please login before requesting a refund');
    }

    await _apiClient.requestRefund(
      userId: _userId!,
      orderId: orderId,
      reasonCode: reasonCode,
      description: description,
    );
    await refreshAll();
  }

  Future<AppOrderDetail> getOrderDetail(String orderId) async {
    if (_userId == null) {
      throw Exception('Please login before viewing order detail');
    }

    return _apiClient.getOrderDetail(
      userId: _userId!,
      orderId: orderId,
    );
  }

  Future<List<AppReview>> getOrderReviews(String orderId) async {
    if (_userId == null) {
      throw Exception('Please login before viewing reviews');
    }

    return _apiClient.getOrderReviews(
      userId: _userId!,
      orderId: orderId,
    );
  }

  Future<void> createOrderReview({
    required String orderId,
    required int score,
    String? content,
  }) async {
    if (_userId == null) {
      throw Exception('Please login before creating a review');
    }

    await _apiClient.createOrderReview(
      userId: _userId!,
      orderId: orderId,
      score: score,
      content: content,
    );
    await refreshAll();
  }

  void resetSession() {
    _userId = null;
    _currentUser = null;
    _listings = const [];
    _myListings = const [];
    _myApplications = const [];
    _myOrders = const [];
    _errorMessage = null;
    _status = AppBootstrapStatus.idle;
    notifyListeners();
  }
}
