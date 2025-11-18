library zettle_sdk;

export 'models.dart';

import 'zettle_sdk_platform_interface.dart';
import 'models.dart';

/// Main SDK class for interacting with Zettle payment services
class ZettleSdk {
  /// Get the platform version (for testing)
  Future<String?> getPlatformVersion() {
    return ZettleSdkPlatform.instance.getPlatformVersion();
  }

  /// Initialize the Zettle SDK with your configuration
  ///
  /// This must be called before any other SDK methods.
  ///
  /// Example:
  /// ```dart
  /// await ZettleSdk().initialize(ZettleConfig(
  ///   clientId: 'your-client-id',
  ///   redirectUrl: 'your-app://zettle/callback',
  ///   isDevMode: true,
  /// ));
  /// ```
  Future<void> initialize(ZettleConfig config) {
    return ZettleSdkPlatform.instance.initialize(config);
  }

  /// Login to Zettle account
  ///
  /// Opens a browser or native login screen for user authentication.
  Future<void> login() {
    return ZettleSdkPlatform.instance.login();
  }

  /// Logout from Zettle account
  Future<void> logout() {
    return ZettleSdkPlatform.instance.logout();
  }

  /// Check if user is currently logged in
  Future<bool> isLoggedIn() {
    return ZettleSdkPlatform.instance.isLoggedIn();
  }

  /// Stream of authentication state changes
  ///
  /// Emits `true` when user is logged in, `false` when logged out.
  /// Subscribe to this stream to react to authentication state changes in real-time.
  ///
  /// The stream emits the current auth state immediately when you subscribe, and
  /// then emits updates whenever the user logs in or logs out.
  ///
  /// Example:
  /// ```dart
  /// ZettleSdk().authStateStream.listen((isLoggedIn) {
  ///   print('User logged in: $isLoggedIn');
  ///   if (isLoggedIn) {
  ///     // User is authenticated, enable payment features
  ///   } else {
  ///     // User is not authenticated, show login button
  ///   }
  /// });
  /// ```
  Stream<bool> get authStateStream {
    return ZettleSdkPlatform.instance.authStateStream;
  }

  /// Process a card payment
  ///
  /// [amount] - Payment amount in cents (e.g., 1000 = $10.00)
  /// [reference] - Unique reference ID for this payment
  /// [tippingConfiguration] - Optional tipping configuration
  /// [enableInstallments] - Enable installments (Android only)
  ///
  /// Returns [PaymentResult] on success.
  /// Throws [ZettleException] on failure.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final result = await ZettleSdk().charge(
  ///     amount: 1000, // $10.00
  ///     reference: 'order-123',
  ///   );
  ///   print('Payment successful: ${result.referenceId}');
  /// } on ZettleException catch (e) {
  ///   print('Payment failed: ${e.message}');
  /// }
  /// ```
  Future<PaymentResult> charge({
    required int amount,
    required String reference,
    TippingConfiguration? tippingConfiguration,
    bool enableInstallments = false,
  }) {
    return ZettleSdkPlatform.instance.charge(
      amount: amount,
      reference: reference,
      tippingConfiguration: tippingConfiguration,
      enableInstallments: enableInstallments,
    );
  }

  /// Refund a previous payment
  ///
  /// [amount] - Refund amount in cents (null for full refund)
  /// [paymentReferenceId] - Reference ID of the payment to refund
  /// [refundReference] - Unique reference ID for this refund
  ///
  /// Returns [RefundResult] on success.
  /// Throws [ZettleException] on failure.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final result = await ZettleSdk().refund(
  ///     paymentReferenceId: 'order-123',
  ///     refundReference: 'refund-456',
  ///   );
  ///   print('Refund successful');
  /// } on ZettleException catch (e) {
  ///   print('Refund failed: ${e.message}');
  /// }
  /// ```
  Future<RefundResult> refund({
    int? amount,
    required String paymentReferenceId,
    required String refundReference,
  }) {
    return ZettleSdkPlatform.instance.refund(
      amount: amount,
      paymentReferenceId: paymentReferenceId,
      refundReference: refundReference,
    );
  }

  /// Retrieve payment information by reference ID
  ///
  /// [referenceId] - Reference ID of the payment to retrieve
  ///
  /// Returns [PaymentResult] with payment details.
  /// Throws [ZettleException] if payment not found.
  Future<PaymentResult> retrievePaymentInfo(String referenceId) {
    return ZettleSdkPlatform.instance.retrievePaymentInfo(referenceId);
  }

  // QR Code (QRC) Payment Methods

  /// Process a QRC payment (PayPal or Venmo)
  ///
  /// [amount] - Payment amount in cents (e.g., 1000 = $10.00)
  /// [reference] - Unique reference ID for this payment
  /// [paymentType] - Type of QRC payment (PayPal or Venmo)
  ///
  /// Returns [QRCPaymentResult] on success.
  /// Throws [ZettleException] on failure.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final result = await ZettleSdk().chargeQRC(
  ///     amount: 1000,
  ///     reference: 'qrc-order-123',
  ///     paymentType: QRCPaymentType.paypal,
  ///   );
  ///   print('QRC payment successful: ${result.referenceId}');
  /// } on ZettleException catch (e) {
  ///   print('QRC payment failed: ${e.message}');
  /// }
  /// ```
  Future<QRCPaymentResult> chargeQRC({
    required int amount,
    required String reference,
    required QRCPaymentType paymentType,
  }) {
    return ZettleSdkPlatform.instance.chargeQRC(
      amount: amount,
      reference: reference,
      paymentType: paymentType,
    );
  }

  /// Refund a QRC payment
  ///
  /// [amount] - Refund amount in cents (null for full refund)
  /// [paymentReferenceId] - Reference ID of the payment to refund
  /// [refundReference] - Unique reference ID for this refund
  /// [paymentType] - Type of QRC payment (PayPal or Venmo)
  ///
  /// Returns [QRCRefundResult] on success.
  /// Throws [ZettleException] on failure.
  Future<QRCRefundResult> refundQRC({
    int? amount,
    required String paymentReferenceId,
    required String refundReference,
    required QRCPaymentType paymentType,
  }) {
    return ZettleSdkPlatform.instance.refundQRC(
      amount: amount,
      paymentReferenceId: paymentReferenceId,
      refundReference: refundReference,
      paymentType: paymentType,
    );
  }

  /// Retrieve QRC payment information by reference ID
  ///
  /// [referenceId] - Reference ID of the payment to retrieve
  /// [paymentType] - Type of QRC payment (PayPal or Venmo)
  ///
  /// Returns [QRCPaymentResult] with payment details.
  /// Throws [ZettleException] if payment not found.
  Future<QRCPaymentResult> retrieveQRCPaymentInfo(
    String referenceId,
    QRCPaymentType paymentType,
  ) {
    return ZettleSdkPlatform.instance.retrieveQRCPaymentInfo(
      referenceId,
      paymentType,
    );
  }

  // Manual Card Entry Methods

  /// Process a manual card entry payment
  ///
  /// [amount] - Payment amount in cents (e.g., 1000 = $10.00)
  /// [reference] - Unique reference ID for this payment
  /// [bnCode] - Optional BuildNotification code (Android only)
  ///
  /// Returns [ManualCardEntryResult] on success.
  /// Throws [ZettleException] on failure.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final result = await ZettleSdk().chargeManualCardEntry(
  ///     amount: 1000,
  ///     reference: 'mce-order-123',
  ///   );
  ///   print('Manual card entry successful: ${result.referenceId}');
  /// } on ZettleException catch (e) {
  ///   print('Manual card entry failed: ${e.message}');
  /// }
  /// ```
  Future<ManualCardEntryResult> chargeManualCardEntry({
    required int amount,
    required String reference,
    String? bnCode,
  }) {
    return ZettleSdkPlatform.instance.chargeManualCardEntry(
      amount: amount,
      reference: reference,
      bnCode: bnCode,
    );
  }

  /// Refund a manual card entry payment
  ///
  /// [amount] - Refund amount in cents (null for full refund)
  /// [paymentReferenceId] - Reference ID of the payment to refund
  /// [refundReference] - Unique reference ID for this refund
  ///
  /// Returns [ManualCardEntryRefundResult] on success.
  /// Throws [ZettleException] on failure.
  Future<ManualCardEntryRefundResult> refundManualCardEntry({
    int? amount,
    required String paymentReferenceId,
    required String refundReference,
  }) {
    return ZettleSdkPlatform.instance.refundManualCardEntry(
      amount: amount,
      paymentReferenceId: paymentReferenceId,
      refundReference: refundReference,
    );
  }

  /// Retrieve manual card entry payment information by reference ID
  ///
  /// [referenceId] - Reference ID of the payment to retrieve
  ///
  /// Returns [ManualCardEntryResult] with payment details.
  /// Throws [ZettleException] if payment not found.
  Future<ManualCardEntryResult> retrieveManualCardEntryInfo(String referenceId) {
    return ZettleSdkPlatform.instance.retrieveManualCardEntryInfo(referenceId);
  }

  // Settings Methods

  /// Open a settings screen
  ///
  /// [settingsType] - Type of settings screen to open
  ///
  /// Opens the native settings UI for configuration.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await ZettleSdk().openSettings(SettingsScreenType.cardReader);
  /// } on ZettleException catch (e) {
  ///   print('Failed to open settings: ${e.message}');
  /// }
  /// ```
  Future<void> openSettings(SettingsScreenType settingsType) {
    return ZettleSdkPlatform.instance.openSettings(settingsType);
  }
}
