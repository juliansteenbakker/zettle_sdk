/// Zettle SDK Models
library;

/// Result of a payment operation
class PaymentResult {
  final String? referenceId;
  final int amount;
  final String? cardBrand;
  final String? cardholderName;
  final String? obfuscatedPan;
  final Map<String, dynamic>? additionalData;

  PaymentResult({
    this.referenceId,
    required this.amount,
    this.cardBrand,
    this.cardholderName,
    this.obfuscatedPan,
    this.additionalData,
  });

  factory PaymentResult.fromMap(Map<String, dynamic> map) {
    return PaymentResult(
      referenceId: map['referenceId'] as String?,
      amount: map['amount'] as int,
      cardBrand: map['cardBrand'] as String?,
      cardholderName: map['cardholderName'] as String?,
      obfuscatedPan: map['obfuscatedPan'] as String?,
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referenceId': referenceId,
      'amount': amount,
      'cardBrand': cardBrand,
      'cardholderName': cardholderName,
      'obfuscatedPan': obfuscatedPan,
      'additionalData': additionalData,
    };
  }

  @override
  String toString() {
    return 'PaymentResult(referenceId: $referenceId, amount: $amount, cardBrand: $cardBrand)';
  }
}

/// Result of a refund operation
class RefundResult {
  final String? referenceId;
  final int refundedAmount;
  final String? cardBrand;
  final String? obfuscatedPan;
  final Map<String, dynamic>? additionalData;

  RefundResult({
    this.referenceId,
    required this.refundedAmount,
    this.cardBrand,
    this.obfuscatedPan,
    this.additionalData,
  });

  factory RefundResult.fromMap(Map<String, dynamic> map) {
    return RefundResult(
      referenceId: map['referenceId'] as String?,
      refundedAmount: map['refundedAmount'] as int,
      cardBrand: map['cardBrand'] as String?,
      obfuscatedPan: map['obfuscatedPan'] as String?,
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referenceId': referenceId,
      'refundedAmount': refundedAmount,
      'cardBrand': cardBrand,
      'obfuscatedPan': obfuscatedPan,
      'additionalData': additionalData,
    };
  }

  @override
  String toString() {
    return 'RefundResult(referenceId: $referenceId, refundedAmount: $refundedAmount)';
  }
}

/// Exception thrown when a Zettle SDK operation fails
class ZettleException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  ZettleException({required this.code, required this.message, this.details});

  @override
  String toString() => 'ZettleException($code): $message';
}

/// Tipping style for Zettle readers
enum ZettleReaderTippingStyle { none, amount, percentage }

/// Tipping style for PayPal readers
enum PayPalReaderTippingStyle { none, predefinedPercentage }

/// Tipping configuration
class TippingConfiguration {
  final ZettleReaderTippingStyle zettleReaderTippingStyle;
  final PayPalReaderTippingStyle payPalReaderTippingStyle;
  final List<int>? payPalReaderPredefinedPercentages;

  TippingConfiguration({
    this.zettleReaderTippingStyle = ZettleReaderTippingStyle.none,
    this.payPalReaderTippingStyle = PayPalReaderTippingStyle.none,
    this.payPalReaderPredefinedPercentages,
  });

  Map<String, dynamic> toMap() {
    return {
      'zettleReaderTippingStyle': zettleReaderTippingStyle.name,
      'payPalReaderTippingStyle': payPalReaderTippingStyle.name,
      'payPalReaderPredefinedPercentages': payPalReaderPredefinedPercentages,
    };
  }
}

/// Configuration for initializing the Zettle SDK
class ZettleConfig {
  final String clientId;
  final String redirectUrl;
  final bool isDevMode;

  ZettleConfig({
    required this.clientId,
    required this.redirectUrl,
    this.isDevMode = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'redirectUrl': redirectUrl,
      'isDevMode': isDevMode,
    };
  }
}

/// QR Code payment type
enum QRCPaymentType { paypal, venmo }

/// Result of a QRC payment operation
class QRCPaymentResult {
  final String? referenceId;
  final int amount;
  final QRCPaymentType paymentType;
  final Map<String, dynamic>? additionalData;

  QRCPaymentResult({
    this.referenceId,
    required this.amount,
    required this.paymentType,
    this.additionalData,
  });

  factory QRCPaymentResult.fromMap(Map<String, dynamic> map) {
    return QRCPaymentResult(
      referenceId: map['referenceId'] as String?,
      amount: map['amount'] as int,
      paymentType: QRCPaymentType.values.firstWhere(
        (e) => e.name == map['paymentType'],
        orElse: () => QRCPaymentType.paypal,
      ),
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referenceId': referenceId,
      'amount': amount,
      'paymentType': paymentType.name,
      'additionalData': additionalData,
    };
  }

  @override
  String toString() {
    return 'QRCPaymentResult(referenceId: $referenceId, amount: $amount, type: ${paymentType.name})';
  }
}

/// Result of a QRC refund operation
class QRCRefundResult {
  final String? referenceId;
  final int refundedAmount;
  final QRCPaymentType paymentType;
  final Map<String, dynamic>? additionalData;

  QRCRefundResult({
    this.referenceId,
    required this.refundedAmount,
    required this.paymentType,
    this.additionalData,
  });

  factory QRCRefundResult.fromMap(Map<String, dynamic> map) {
    return QRCRefundResult(
      referenceId: map['referenceId'] as String?,
      refundedAmount: map['refundedAmount'] as int,
      paymentType: QRCPaymentType.values.firstWhere(
        (e) => e.name == map['paymentType'],
        orElse: () => QRCPaymentType.paypal,
      ),
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referenceId': referenceId,
      'refundedAmount': refundedAmount,
      'paymentType': paymentType.name,
      'additionalData': additionalData,
    };
  }

  @override
  String toString() {
    return 'QRCRefundResult(referenceId: $referenceId, refundedAmount: $refundedAmount, type: ${paymentType.name})';
  }
}

/// Result of a Manual Card Entry payment operation
class ManualCardEntryResult {
  final String? referenceId;
  final int amount;
  final String? cardBrand;
  final String? obfuscatedPan;
  final Map<String, dynamic>? additionalData;

  ManualCardEntryResult({
    this.referenceId,
    required this.amount,
    this.cardBrand,
    this.obfuscatedPan,
    this.additionalData,
  });

  factory ManualCardEntryResult.fromMap(Map<String, dynamic> map) {
    return ManualCardEntryResult(
      referenceId: map['referenceId'] as String?,
      amount: map['amount'] as int,
      cardBrand: map['cardBrand'] as String?,
      obfuscatedPan: map['obfuscatedPan'] as String?,
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referenceId': referenceId,
      'amount': amount,
      'cardBrand': cardBrand,
      'obfuscatedPan': obfuscatedPan,
      'additionalData': additionalData,
    };
  }

  @override
  String toString() {
    return 'ManualCardEntryResult(referenceId: $referenceId, amount: $amount, cardBrand: $cardBrand)';
  }
}

/// Result of a Manual Card Entry refund operation
class ManualCardEntryRefundResult {
  final String? referenceId;
  final int refundedAmount;
  final String? cardBrand;
  final String? obfuscatedPan;
  final Map<String, dynamic>? additionalData;

  ManualCardEntryRefundResult({
    this.referenceId,
    required this.refundedAmount,
    this.cardBrand,
    this.obfuscatedPan,
    this.additionalData,
  });

  factory ManualCardEntryRefundResult.fromMap(Map<String, dynamic> map) {
    return ManualCardEntryRefundResult(
      referenceId: map['referenceId'] as String?,
      refundedAmount: map['refundedAmount'] as int,
      cardBrand: map['cardBrand'] as String?,
      obfuscatedPan: map['obfuscatedPan'] as String?,
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referenceId': referenceId,
      'refundedAmount': refundedAmount,
      'cardBrand': cardBrand,
      'obfuscatedPan': obfuscatedPan,
      'additionalData': additionalData,
    };
  }

  @override
  String toString() {
    return 'ManualCardEntryRefundResult(referenceId: $referenceId, refundedAmount: $refundedAmount)';
  }
}

/// Settings screen type
enum SettingsScreenType {
  cardReader,
  manualCardEntry,
  qrcPayPal,
  qrcVenmo,
  tipping,
}
