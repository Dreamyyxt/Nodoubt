class ReceivedApplication {
  const ReceivedApplication({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    required this.message,
    required this.status,
    this.quotedPrice,
    this.orderId,
    this.orderStatus,
  });

  final String id;
  final String applicantId;
  final String applicantName;
  final String message;
  final String status;
  final double? quotedPrice;
  final String? orderId;
  final String? orderStatus;

  bool get hasOrder => orderId != null && orderId!.isNotEmpty;

  factory ReceivedApplication.fromJson(Map<String, dynamic> json) {
    final applicant = (json['applicant'] as Map<String, dynamic>?) ?? const {};
    final quotedPriceRaw = json['quotedPrice'];
    final orders = json['orders'] as List<dynamic>? ?? const <dynamic>[];
    final firstOrder =
        orders.isNotEmpty ? orders.first as Map<String, dynamic> : const <String, dynamic>{};

    return ReceivedApplication(
      id: json['id']?.toString() ?? '',
      applicantId: applicant['id']?.toString() ?? '',
      applicantName: applicant['nickname']?.toString() ?? '匿名申请者',
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      quotedPrice: quotedPriceRaw is num
          ? quotedPriceRaw.toDouble()
          : double.tryParse(quotedPriceRaw?.toString() ?? ''),
      orderId: firstOrder['id']?.toString(),
      orderStatus: firstOrder['orderStatus']?.toString(),
    );
  }
}
