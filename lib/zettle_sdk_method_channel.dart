import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'zettle_sdk_platform_interface.dart';
import 'models.dart';

/// An implementation of [ZettleSdkPlatform] that uses method channels.
class MethodChannelZettleSdk extends ZettleSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('zettle_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> initialize(ZettleConfig config) async {
    try {
      await methodChannel.invokeMethod('initialize', config.toMap());
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'Failed to initialize SDK',
        details: e.details,
      );
    }
  }

  @override
  Future<void> login() async {
    try {
      await methodChannel.invokeMethod('login');
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'Login failed',
        details: e.details,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await methodChannel.invokeMethod('logout');
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'Logout failed',
        details: e.details,
      );
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('isLoggedIn');
      return result ?? false;
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'Failed to check login status',
        details: e.details,
      );
    }
  }

  @override
  Future<PaymentResult> charge({
    required int amount,
    required String reference,
    TippingConfiguration? tippingConfiguration,
    bool enableInstallments = false,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map>('charge', {
        'amount': amount,
        'reference': reference,
        'tippingConfiguration': tippingConfiguration?.toMap(),
        'enableInstallments': enableInstallments,
      });

      if (result == null) {
        throw ZettleException(
          code: 'PAYMENT_FAILED',
          message: 'Payment returned null result',
        );
      }

      return PaymentResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'Payment failed',
        details: e.details,
      );
    }
  }

  @override
  Future<RefundResult> refund({
    int? amount,
    required String paymentReferenceId,
    required String refundReference,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map>('refund', {
        'amount': amount,
        'paymentReferenceId': paymentReferenceId,
        'refundReference': refundReference,
      });

      if (result == null) {
        throw ZettleException(
          code: 'REFUND_FAILED',
          message: 'Refund returned null result',
        );
      }

      return RefundResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'Refund failed',
        details: e.details,
      );
    }
  }

  @override
  Future<PaymentResult> retrievePaymentInfo(String referenceId) async {
    try {
      final result = await methodChannel.invokeMethod<Map>('retrievePaymentInfo', {
        'referenceId': referenceId,
      });

      if (result == null) {
        throw ZettleException(
          code: 'RETRIEVE_FAILED',
          message: 'Retrieve payment info returned null result',
        );
      }

      return PaymentResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'Failed to retrieve payment info',
        details: e.details,
      );
    }
  }

  // QRC Payment Methods

  @override
  Future<QRCPaymentResult> chargeQRC({
    required int amount,
    required String reference,
    required QRCPaymentType paymentType,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map>('chargeQRC', {
        'amount': amount,
        'reference': reference,
        'paymentType': paymentType.name,
      });

      if (result == null) {
        throw ZettleException(
          code: 'QRC_PAYMENT_FAILED',
          message: 'QRC payment returned null result',
        );
      }

      return QRCPaymentResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'QRC payment failed',
        details: e.details,
      );
    }
  }

  @override
  Future<QRCRefundResult> refundQRC({
    int? amount,
    required String paymentReferenceId,
    required String refundReference,
    required QRCPaymentType paymentType,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map>('refundQRC', {
        'amount': amount,
        'paymentReferenceId': paymentReferenceId,
        'refundReference': refundReference,
        'paymentType': paymentType.name,
      });

      if (result == null) {
        throw ZettleException(
          code: 'QRC_REFUND_FAILED',
          message: 'QRC refund returned null result',
        );
      }

      return QRCRefundResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'QRC refund failed',
        details: e.details,
      );
    }
  }

  @override
  Future<QRCPaymentResult> retrieveQRCPaymentInfo(
    String referenceId,
    QRCPaymentType paymentType,
  ) async {
    try {
      final result = await methodChannel.invokeMethod<Map>('retrieveQRCPaymentInfo', {
        'referenceId': referenceId,
        'paymentType': paymentType.name,
      });

      if (result == null) {
        throw ZettleException(
          code: 'QRC_RETRIEVE_FAILED',
          message: 'Retrieve QRC payment info returned null result',
        );
      }

      return QRCPaymentResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'Failed to retrieve QRC payment info',
        details: e.details,
      );
    }
  }

  // Manual Card Entry Methods

  @override
  Future<ManualCardEntryResult> chargeManualCardEntry({
    required int amount,
    required String reference,
    String? bnCode,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map>('chargeManualCardEntry', {
        'amount': amount,
        'reference': reference,
        'bnCode': bnCode,
      });

      if (result == null) {
        throw ZettleException(
          code: 'MCE_PAYMENT_FAILED',
          message: 'Manual card entry payment returned null result',
        );
      }

      return ManualCardEntryResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'Manual card entry payment failed',
        details: e.details,
      );
    }
  }

  @override
  Future<ManualCardEntryRefundResult> refundManualCardEntry({
    int? amount,
    required String paymentReferenceId,
    required String refundReference,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map>('refundManualCardEntry', {
        'amount': amount,
        'paymentReferenceId': paymentReferenceId,
        'refundReference': refundReference,
      });

      if (result == null) {
        throw ZettleException(
          code: 'MCE_REFUND_FAILED',
          message: 'Manual card entry refund returned null result',
        );
      }

      return ManualCardEntryRefundResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'Manual card entry refund failed',
        details: e.details,
      );
    }
  }

  @override
  Future<ManualCardEntryResult> retrieveManualCardEntryInfo(String referenceId) async {
    try {
      final result = await methodChannel.invokeMethod<Map>('retrieveManualCardEntryInfo', {
        'referenceId': referenceId,
      });

      if (result == null) {
        throw ZettleException(
          code: 'MCE_RETRIEVE_FAILED',
          message: 'Retrieve manual card entry info returned null result',
        );
      }

      return ManualCardEntryResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'Failed to retrieve manual card entry info',
        details: e.details,
      );
    }
  }

  // Settings Methods

  @override
  Future<void> openSettings(SettingsScreenType settingsType) async {
    try {
      await methodChannel.invokeMethod('openSettings', {
        'settingsType': settingsType.name,
      });
    } on PlatformException catch (e) {
      throw ZettleException(
        code: e.code,
        message: e.message ?? 'Failed to open settings',
        details: e.details,
      );
    }
  }
}
