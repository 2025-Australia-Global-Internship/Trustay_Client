/// 서버 결제 도메인 응답 DTO 모음

class PaymentPrepareModel {
  final int paymentId;
  final String orderId;
  final int amount;
  final String paymentType; // RENT / UTILITY / DUTCH
  final String? targetAccount;
  final String? settlementGuide;

  PaymentPrepareModel({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.paymentType,
    this.targetAccount,
    this.settlementGuide,
  });

  factory PaymentPrepareModel.fromJson(Map<String, dynamic> json) {
    return PaymentPrepareModel(
      paymentId: json['paymentId'] ?? 0,
      orderId: json['orderId']?.toString() ?? '',
      amount: json['amount'] ?? 0,
      paymentType: json['paymentType']?.toString() ?? '',
      targetAccount: json['targetAccount'] as String?,
      settlementGuide: json['settlementGuide'] as String?,
    );
  }
}

class DutchPaySplitItem {
  final int paymentId;
  final int memberId;
  final int amount;
  final String orderId;
  final String? targetAccount;

  DutchPaySplitItem({
    required this.paymentId,
    required this.memberId,
    required this.amount,
    required this.orderId,
    this.targetAccount,
  });

  factory DutchPaySplitItem.fromJson(Map<String, dynamic> json) {
    return DutchPaySplitItem(
      paymentId: json['paymentId'] ?? 0,
      memberId: json['memberId'] ?? 0,
      amount: json['amount'] ?? 0,
      orderId: json['orderId']?.toString() ?? '',
      targetAccount: json['targetAccount'] as String?,
    );
  }
}

class DutchPayCreateModel {
  final int dutchPayGroupId;
  final List<DutchPaySplitItem> splits;
  final String? settlementGuide;

  DutchPayCreateModel({
    required this.dutchPayGroupId,
    required this.splits,
    this.settlementGuide,
  });

  factory DutchPayCreateModel.fromJson(Map<String, dynamic> json) {
    final raw = json['splits'] as List<dynamic>? ?? [];
    return DutchPayCreateModel(
      dutchPayGroupId: json['dutchPayGroupId'] ?? 0,
      splits: raw
          .map((e) => DutchPaySplitItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      settlementGuide: json['settlementGuide'] as String?,
    );
  }
}

class PaymentConfirmModel {
  final int paymentId;
  final String orderId;
  final String status; // 내부 상태 PENDING / CONFIRMED / FAILED
  final String paymentType;
  final String? tossPaymentStatus;

  PaymentConfirmModel({
    required this.paymentId,
    required this.orderId,
    required this.status,
    required this.paymentType,
    this.tossPaymentStatus,
  });

  factory PaymentConfirmModel.fromJson(Map<String, dynamic> json) {
    return PaymentConfirmModel(
      paymentId: json['paymentId'] ?? 0,
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentType: json['paymentType']?.toString() ?? '',
      tossPaymentStatus: json['tossPaymentStatus'] as String?,
    );
  }
}

class PendingPayment {
  final int paymentId;
  final String orderId;
  final int amount;
  final String paymentType;
  final String? targetAccount;
  final int? dutchPayGroupId;

  PendingPayment({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.paymentType,
    this.targetAccount,
    this.dutchPayGroupId,
  });

  factory PendingPayment.fromJson(Map<String, dynamic> json) {
    return PendingPayment(
      paymentId: json['paymentId'] ?? 0,
      orderId: json['orderId']?.toString() ?? '',
      amount: json['amount'] ?? 0,
      paymentType: json['paymentType']?.toString() ?? '',
      targetAccount: json['targetAccount'] as String?,
      dutchPayGroupId: json['dutchPayGroupId'] as int?,
    );
  }
}

class PaymentHistoryItem {
  final int paymentId;
  final String orderId;
  final int amount;
  final String paymentType; // RENT / UTILITY / DUTCH
  final String status; // PENDING / CONFIRMED / FAILED
  final String? targetAccount;
  final DateTime? transactionDate;
  final bool autoTransfer;
  final int? contractId;
  final int? dutchPayGroupId;

  PaymentHistoryItem({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.paymentType,
    required this.status,
    this.targetAccount,
    this.transactionDate,
    this.autoTransfer = false,
    this.contractId,
    this.dutchPayGroupId,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final raw = json['transactionDate'];
    if (raw is String && raw.isNotEmpty) {
      try {
        parsedDate = DateTime.parse(raw);
      } catch (_) {
        parsedDate = null;
      }
    }
    return PaymentHistoryItem(
      paymentId: json['paymentId'] ?? 0,
      orderId: json['orderId']?.toString() ?? '',
      amount: (json['amount'] is int)
          ? json['amount'] as int
          : ((json['amount'] as num?)?.toInt() ?? 0),
      paymentType: json['paymentType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      targetAccount: json['targetAccount'] as String?,
      transactionDate: parsedDate,
      autoTransfer: json['autoTransfer'] ?? false,
      contractId: json['contractId'] as int?,
      dutchPayGroupId: json['dutchPayGroupId'] as int?,
    );
  }
}

class TossClientConfig {
  final String clientKey;
  TossClientConfig({required this.clientKey});

  factory TossClientConfig.fromJson(Map<String, dynamic> json) =>
      TossClientConfig(clientKey: json['clientKey']?.toString() ?? '');
}
