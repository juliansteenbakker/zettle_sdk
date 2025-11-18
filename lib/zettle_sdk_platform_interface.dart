import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'zettle_sdk_method_channel.dart';
import 'models.dart';

abstract class ZettleSdkPlatform extends PlatformInterface {
  /// Constructs a ZettleSdkPlatform.
  ZettleSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static ZettleSdkPlatform _instance = MethodChannelZettleSdk();

  /// The default instance of [ZettleSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelZettleSdk].
  static ZettleSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ZettleSdkPlatform] when
  /// they register themselves.
  static set instance(ZettleSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Initialize the Zettle SDK with configuration
  Future<void> initialize(ZettleConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Login to Zettle account
  Future<void> login() {
    throw UnimplementedError('login() has not been implemented.');
  }

  /// Logout from Zettle account
  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() {
    throw UnimplementedError('isLoggedIn() has not been implemented.');
  }

  /// Process a card payment
  ///
  /// [amount] - Payment amount in cents (e.g., 1000 = $10.00)
  /// [reference] - Unique reference ID for this payment
  /// [tippingConfiguration] - Optional tipping configuration
  /// [enableInstallments] - Enable installments (Android only)
  Future<PaymentResult> charge({
    required int amount,
    required String reference,
    TippingConfiguration? tippingConfiguration,
    bool enableInstallments = false,
  }) {
    throw UnimplementedError('charge() has not been implemented.');
  }

  /// Refund a previous payment
  ///
  /// [amount] - Refund amount in cents (null for full refund)
  /// [paymentReferenceId] - Reference ID of the payment to refund
  /// [refundReference] - Unique reference ID for this refund
  Future<RefundResult> refund({
    int? amount,
    required String paymentReferenceId,
    required String refundReference,
  }) {
    throw UnimplementedError('refund() has not been implemented.');
  }

  /// Retrieve payment information
  ///
  /// [referenceId] - Reference ID of the payment to retrieve
  Future<PaymentResult> retrievePaymentInfo(String referenceId) {
    throw UnimplementedError('retrievePaymentInfo() has not been implemented.');
  }

  // QR Code (QRC) Payment Methods

  /// Process a QRC payment (PayPal or Venmo)
  ///
  /// [amount] - Payment amount in cents (e.g., 1000 = $10.00)
  /// [reference] - Unique reference ID for this payment
  /// [paymentType] - Type of QRC payment (PayPal or Venmo)
  Future<QRCPaymentResult> chargeQRC({
    required int amount,
    required String reference,
    required QRCPaymentType paymentType,
  }) {
    throw UnimplementedError('chargeQRC() has not been implemented.');
  }

  /// Refund a QRC payment
  ///
  /// [amount] - Refund amount in cents (null for full refund)
  /// [paymentReferenceId] - Reference ID of the payment to refund
  /// [refundReference] - Unique reference ID for this refund
  /// [paymentType] - Type of QRC payment (PayPal or Venmo)
  Future<QRCRefundResult> refundQRC({
    int? amount,
    required String paymentReferenceId,
    required String refundReference,
    required QRCPaymentType paymentType,
  }) {
    throw UnimplementedError('refundQRC() has not been implemented.');
  }

  /// Retrieve QRC payment information
  ///
  /// [referenceId] - Reference ID of the payment to retrieve
  /// [paymentType] - Type of QRC payment (PayPal or Venmo)
  Future<QRCPaymentResult> retrieveQRCPaymentInfo(
    String referenceId,
    QRCPaymentType paymentType,
  ) {
    throw UnimplementedError('retrieveQRCPaymentInfo() has not been implemented.');
  }

  // Manual Card Entry Methods

  /// Process a manual card entry payment
  ///
  /// [amount] - Payment amount in cents (e.g., 1000 = $10.00)
  /// [reference] - Unique reference ID for this payment
  /// [bnCode] - Optional BuildNotification code (Android only)
  Future<ManualCardEntryResult> chargeManualCardEntry({
    required int amount,
    required String reference,
    String? bnCode,
  }) {
    throw UnimplementedError('chargeManualCardEntry() has not been implemented.');
  }

  /// Refund a manual card entry payment
  ///
  /// [amount] - Refund amount in cents (null for full refund)
  /// [paymentReferenceId] - Reference ID of the payment to refund
  /// [refundReference] - Unique reference ID for this refund
  Future<ManualCardEntryRefundResult> refundManualCardEntry({
    int? amount,
    required String paymentReferenceId,
    required String refundReference,
  }) {
    throw UnimplementedError('refundManualCardEntry() has not been implemented.');
  }

  /// Retrieve manual card entry payment information
  ///
  /// [referenceId] - Reference ID of the payment to retrieve
  Future<ManualCardEntryResult> retrieveManualCardEntryInfo(String referenceId) {
    throw UnimplementedError('retrieveManualCardEntryInfo() has not been implemented.');
  }

  // Settings Methods

  /// Open a settings screen
  ///
  /// [settingsType] - Type of settings screen to open
  Future<void> openSettings(SettingsScreenType settingsType) {
    throw UnimplementedError('openSettings() has not been implemented.');
  }
}
