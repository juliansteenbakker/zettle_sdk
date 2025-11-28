# zettle_sdk

A Flutter plugin for integrating Zettle (iZettle) payment processing into your Flutter applications on Android and iOS.

## Features

- 🔐 **Authentication**: Log in and out of Zettle accounts
- 💳 **Card Payments**: Process card payments with Zettle card readers
- 💰 **Refunds**: Refund previous payments (full or partial)
- 📊 **Payment Info**: Retrieve payment information by reference
- 🎁 **Tipping**: Support for tipping on both Zettle and PayPal readers

## Prerequisites

Before using this plugin, you need to:

1. Register for a Zettle developer account at [developer.zettle.com](https://developer.zettle.com)
2. Create an application to get your `Client ID`
3. Configure your redirect URL for OAuth authentication
4. Have a Zettle account for testing (you can create one at [zettle.com](https://www.zettle.com))

When creating your application, you'll need to provide:

| Field                   | Description                                                                            | Example Value                                                     |
|-------------------------|----------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| **App name***           | The app name shown to merchants (cannot be changed)                                    | `My Retail POS App`                                               |
| **OAuth Redirect URIs** | URIs merchants are redirected to after successful login (comma-separated for multiple) | `myapp://zettle/callback,https://myapp.com/auth/callback`         |
| **App URL***            | Link to your app homepage where users can learn more                                   | `https://myapp.com` or `https://github.com/yourcompany/myapp`     |
| **Bundle ID***          | Your app's unique identifier (cannot be changed later)                                 | iOS: `com.yourcompany.myapp`<br/>Android: `com.yourcompany.myapp` |
| **Company name***       | The company responsible for the app (cannot be changed)                                | `Your Company Name Inc.`                                          |


## Deep Link Setup for OAuth

Zettle uses OAuth for authentication, which requires your app to handle deep links. When a user logs in, they'll be redirected to Zettle's login page in a browser, and after successful authentication, they'll be redirected back to your app via a deep link.

### Understanding Deep Links

A deep link is a URL scheme that opens your app directly. For example:
- `yourapp://zettle/callback` - Opens your app and passes the OAuth callback
- The format is: `scheme://host/path`
  - **scheme**: Your unique app identifier (e.g., `yourapp`, `mycompany`, etc.)
  - **host**: Usually `zettle` for this SDK
  - **path**: Usually `/callback` for the OAuth callback

### Android Deep Link Configuration

Add an intent filter to your `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    ...>

    <!-- Existing MAIN intent filter -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>

    <!-- Deep Link for Zettle OAuth callback -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data
            android:scheme="yourapp"
            android:host="zettle"
            android:path="/callback"/>
    </intent-filter>
</activity>
```

**Important**: Replace `yourapp` with your unique app scheme.

### iOS Deep Link Configuration

Add URL types to your `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

**Important**:
- Replace `yourapp` with your unique app scheme (must match Android)
- Replace `com.yourcompany.yourapp` with your bundle identifier

### Registering Your Redirect URI

When creating your app on the Zettle Developer Portal, you **must** register your redirect URI:

1. Go to [developer.zettle.com](https://developer.zettle.com)
2. Navigate to your app settings
3. In the "OAuth Redirect URIs" field, enter your deep link URL
   - Example: `yourapp://zettle/callback`
   - You can add multiple URIs separated by commas

**The redirect URI in your code must exactly match what you registered in the Zettle Developer Portal.**

### Using Deep Links in Your Code

Initialize the SDK with the same redirect URL you configured:

```dart
await zettleSdk.initialize(ZettleConfig(
  clientId: 'YOUR_CLIENT_ID',
  redirectUrl: 'yourapp://zettle/callback', // Must match your deep link configuration
  isDevMode: true,
));
```

### Testing Deep Links

#### Android Testing

Test if your deep link works using ADB:

```bash
adb shell am start -W -a android.intent.action.VIEW -d "yourapp://zettle/callback"
```

If configured correctly, your app should open.

#### iOS Testing

1. Open Safari on your iOS device or simulator
2. Type your deep link in the address bar: `yourapp://zettle/callback`
3. Press Go
4. Your app should open

### Choosing a URL Scheme

Your URL scheme should be:
- **Unique**: Avoid common words like `app`, `test`, `demo`
- **Descriptive**: Use your company or app name (e.g., `mycompanypos`, `retailapp`)
- **Lowercase**: Use lowercase letters only
- **No special characters**: Stick to alphanumeric characters

**Examples**:
- Good: `acmepay://zettle/callback`, `retailpro://zettle/callback`
- Bad: `app://zettle/callback`, `test://zettle/callback`, `My-App://zettle/callback`

### Common Issues

**"OAuth redirect URI mismatch"**:
- Ensure the `redirectUrl` in your code exactly matches what's registered on the Zettle Developer Portal
- Check for typos, extra spaces, or case mismatches

**App doesn't open after login**:
- Verify deep link configuration in AndroidManifest.xml (Android) or Info.plist (iOS)
- Test your deep link using the testing methods above
- Ensure `android:exported="true"` is set on your MainActivity (Android)

**Multiple apps respond to the deep link**:
- Choose a more unique URL scheme
- Ensure you're not using a common scheme that other apps might use

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  zettle_sdk:
    path: ../zettle_sdk  # Or use git/pub.dev reference when published
```

### Android Setup

#### 1. GitHub Package Authentication

The Zettle Android SDK is hosted on GitHub Packages. You need to authenticate to access it.

Create or edit `~/.gradle/gradle.properties` and add:

```properties
github.username=x
github.token=x
```

Note: For production use, use environment variables instead of hardcoding credentials.

#### 2. Minimum SDK Version

Ensure your `android/app/build.gradle` has:

```gradle
android {
    defaultConfig {
        minSdkVersion 24  // Zettle SDK requires API 24+
    }
}
```

### iOS Setup

#### 1. Minimum iOS Version

Update `ios/Podfile` to require iOS 13.0+:

```ruby
platform :ios, '13.0'
```

#### 2. Install Pods

```bash
cd ios
pod install
```

#### 3. Required Info.plist Configuration

Add the following to your `ios/Runner/Info.plist`:

```xml
<!-- Bluetooth Permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is required to connect to Zettle card readers via Bluetooth</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth is required to connect to Zettle card readers for payment processing</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Bluetooth is required to connect to Zettle card readers for payment processing</string>

<!-- External Accessory Protocol for Card Reader -->
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.izettle.cardreader-one</string>
</array>
```

#### 4. Enable Background Modes

**Option A: Via Info.plist (Recommended for Flutter)**

Add to your `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>external-accessory</string>
    <string>bluetooth-central</string>
</array>
```

**Option B: Via Xcode UI**

1. Open your iOS project in Xcode (`ios/Runner.xcworkspace`)
2. Select your app target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Background Modes**
6. Enable these checkboxes:
   - ✅ **External accessory communication**
   - ✅ **Uses Bluetooth LE accessories**

These background modes allow the app to maintain connection with Zettle card readers when in the background.

**Note:** MFi (Made for iPhone/iPad) program approval from Apple is required before releasing apps supporting Zettle card readers to the App Store.

## Usage

### 1. Initialize the SDK

```dart
import 'package:zettle_sdk/zettle_sdk.dart';

final zettleSdk = ZettleSdk();

await zettleSdk.initialize(ZettleConfig(
  clientId: 'YOUR_CLIENT_ID',
  redirectUrl: 'your-app://zettle/callback',
  isDevMode: true,  // Use false for production
));
```

### 2. Authentication

```dart
// Login
await zettleSdk.login();

// Check login status
bool isLoggedIn = await zettleSdk.isLoggedIn();

// Logout
await zettleSdk.logout();
```

### 3. Process a Payment

```dart
try {
  final result = await zettleSdk.charge(
    amount: 1000,  // Amount in cents ($10.00)
    reference: 'order-123',  // Your unique reference
  );

  print('Payment successful!');
  print('Reference: ${result.referenceId}');
  print('Amount: \$${result.amount / 100}');
  print('Card Brand: ${result.cardBrand}');
} on ZettleException catch (e) {
  print('Payment failed: ${e.message}');
}
```

### 4. Process a Refund

```dart
try {
  final result = await zettleSdk.refund(
    paymentReferenceId: 'order-123',  // Reference from original payment
    refundReference: 'refund-456',     // Your unique refund reference
    amount: 500,  // Optional: partial refund amount in cents
  );

  print('Refund successful!');
  print('Refunded: \$${result.refundedAmount / 100}');
} on ZettleException catch (e) {
  print('Refund failed: ${e.message}');
}
```

### 5. Retrieve Payment Information

```dart
try {
  final paymentInfo = await zettleSdk.retrievePaymentInfo('order-123');
  print('Payment Amount: \$${paymentInfo.amount / 100}');
} on ZettleException catch (e) {
  print('Failed to retrieve payment info: ${e.message}');
}
```

### 6. Tipping Configuration

```dart
final result = await zettleSdk.charge(
  amount: 1000,
  reference: 'order-123',
  tippingConfiguration: TippingConfiguration(
    zettleReaderTippingStyle: ZettleReaderTippingStyle.percentage,
    payPalReaderTippingStyle: PayPalReaderTippingStyle.predefinedPercentage,
    payPalReaderPredefinedPercentages: [10, 15, 20],  // 10%, 15%, 20%
  ),
);
```

### 7. Installments (Android Only)

Enable installment payments for customers to split payments into multiple parts:

```dart
try {
  final result = await zettleSdk.charge(
    amount: 10000,  // $100.00
    reference: 'order-123',
    enableInstallments: true,  // Enable installment option
  );
  print('Payment successful with installments option');
} on ZettleException catch (e) {
  print('Payment failed: ${e.message}');
}
```

**Note:** Installments are only available on Android and in certain markets. The feature allows customers to split their payment into installments during the payment flow. Availability depends on the merchant's market and Zettle's regional support.

### 8. QR Code Payments (PayPal & Venmo)

Process contactless payments using QR codes:

```dart
try {
  // PayPal QRC Payment
  final result = await zettleSdk.chargeQRC(
    amount: 1500,
    reference: 'qrc-order-456',
    paymentType: QRCPaymentType.paypal,
  );
  print('QRC payment successful: ${result.referenceId}');

  // Venmo QRC Payment (US only)
  final venmoResult = await zettleSdk.chargeQRC(
    amount: 2000,
    reference: 'venmo-order-789',
    paymentType: QRCPaymentType.venmo,
  );
} on ZettleException catch (e) {
  print('QRC payment failed: ${e.message}');
}
```

**QRC Refunds:**

```dart
try {
  final refund = await zettleSdk.refundQRC(
    paymentReferenceId: 'qrc-order-456',
    refundReference: 'qrc-refund-123',
    paymentType: QRCPaymentType.paypal,
  );
  print('QRC refund successful');
} on ZettleException catch (e) {
  print('QRC refund failed: ${e.message}');
}
```

### 9. Manual Card Entry

Process payments by manually entering card details when a card reader isn't available:

```dart
try {
  final result = await zettleSdk.chargeManualCardEntry(
    amount: 2500,  // $25.00
    reference: 'mce-order-999',
  );
  print('Manual card entry successful: ${result.referenceId}');
} on ZettleException catch (e) {
  print('Manual card entry failed: ${e.message}');
}
```

**Manual Card Entry Refunds:**

```dart
try {
  final refund = await zettleSdk.refundManualCardEntry(
    paymentReferenceId: 'mce-order-999',
    refundReference: 'mce-refund-456',
  );
} on ZettleException catch (e) {
  print('Refund failed: ${e.message}');
}
```

**Retrieve Manual Card Entry Payment:**

```dart
try {
  final paymentInfo = await zettleSdk.retrieveManualCardEntryInfo('mce-order-999');
  print('Payment: \$${paymentInfo.amount / 100}');
} on ZettleException catch (e) {
  print('Failed to retrieve: ${e.message}');
}
```

### 10. Settings Screens

Open native settings screens for configuration:

```dart
try {
  // Android: Opens specific settings screen based on type
  // iOS: Opens unified settings view (type parameter is ignored)
  await zettleSdk.openSettings(SettingsScreenType.cardReader);
} on ZettleException catch (e) {
  print('Failed to open settings: ${e.message}');
}
```

**Platform Differences:**

- **Android**: Provides separate settings screens for each type:
  - `SettingsScreenType.cardReader` - Card reader settings
  - `SettingsScreenType.manualCardEntry` - Manual card entry activation
  - `SettingsScreenType.qrcPayPal` - PayPal QRC settings
  - `SettingsScreenType.qrcVenmo` - Venmo QRC settings
  - `SettingsScreenType.tipping` - Tipping configuration

- **iOS**: Provides a unified settings view that includes:
  - Account switching
  - FAQ documentation
  - Card reader settings
  - Payment method configuration (PayPal QRC, etc.)
  - Tipping settings

  On iOS, the `settingsType` parameter is ignored and the unified settings view is always shown.

## API Reference

### ZettleSdk

#### Methods

**Authentication:**
- `initialize(ZettleConfig config)` - Initialize the SDK with your credentials
- `login()` - Open login screen for user authentication
- `logout()` - Log out the current user
- `isLoggedIn()` - Check if a user is logged in

**Card Reader Payments:**
- `charge({required int amount, required String reference, TippingConfiguration? tippingConfiguration, bool enableInstallments})` - Process a card reader payment
- `refund({int? amount, required String paymentReferenceId, required String refundReference})` - Refund a card reader payment
- `retrievePaymentInfo(String referenceId)` - Get card payment details

**QR Code Payments:**
- `chargeQRC({required int amount, required String reference, required QRCPaymentType paymentType})` - Process a QRC payment (PayPal or Venmo)
- `refundQRC({int? amount, required String paymentReferenceId, required String refundReference, required QRCPaymentType paymentType})` - Refund a QRC payment
- `retrieveQRCPaymentInfo(String referenceId, QRCPaymentType paymentType)` - Get QRC payment details

**Manual Card Entry:**
- `chargeManualCardEntry({required int amount, required String reference, String? bnCode})` - Process a manual card entry payment
- `refundManualCardEntry({int? amount, required String paymentReferenceId, required String refundReference})` - Refund a manual card entry payment
- `retrieveManualCardEntryInfo(String referenceId)` - Get manual card entry payment details

**Settings:**
- `openSettings(SettingsScreenType settingsType)` - Open a settings screen (Android only)

### Models

#### ZettleConfig
- `clientId` (String) - Your Zettle API client ID
- `redirectUrl` (String) - OAuth redirect URL for your app
- `isDevMode` (bool) - Enable development mode (default: false)

#### PaymentResult
- `referenceId` (String?) - Your payment reference
- `amount` (int) - Payment amount in cents
- `cardBrand` (String?) - Card brand (e.g., "VISA", "MASTERCARD")
- `cardholderName` (String?) - Cardholder name
- `obfuscatedPan` (String?) - Masked card number

#### RefundResult
- `referenceId` (String?) - Refund reference
- `refundedAmount` (int) - Refunded amount in cents
- `cardBrand` (String?) - Card brand
- `obfuscatedPan` (String?) - Masked card number

#### ZettleException
- `code` (String) - Error code
- `message` (String) - Error message
- `details` (dynamic) - Additional error details

#### QRCPaymentResult
- `referenceId` (String?) - Your payment reference
- `amount` (int) - Payment amount in cents
- `paymentType` (QRCPaymentType) - Type of QRC payment (paypal/venmo)

#### QRCRefundResult
- `referenceId` (String?) - Refund reference
- `refundedAmount` (int) - Refunded amount in cents
- `paymentType` (QRCPaymentType) - Type of QRC payment

#### ManualCardEntryResult
- `referenceId` (String?) - Your payment reference
- `amount` (int) - Payment amount in cents
- `cardBrand` (String?) - Card brand
- `obfuscatedPan` (String?) - Masked card number

#### ManualCardEntryRefundResult
- `referenceId` (String?) - Refund reference
- `refundedAmount` (int) - Refunded amount in cents
- `cardBrand` (String?) - Card brand
- `obfuscatedPan` (String?) - Masked card number

#### Enums
- `QRCPaymentType` - `paypal`, `venmo`
- `ZettleReaderTippingStyle` - `none`, `amount`, `percentage`
- `PayPalReaderTippingStyle` - `none`, `predefinedPercentage`
- `SettingsScreenType` - `cardReader`, `manualCardEntry`, `qrcPayPal`, `qrcVenmo`, `tipping`

## Error Handling

All SDK methods can throw `ZettleException`. Common error codes:

**General:**
- `NOT_INITIALIZED` - SDK not initialized before use
- `NOT_AUTHORIZED` - User not logged in
- `NO_ACTIVITY` (Android) / `NO_VIEWCONTROLLER` (iOS) - UI context not available

**Card Reader:**
- `PAYMENT_CANCELLED` - User cancelled the payment
- `PAYMENT_FAILED` - Payment processing failed
- `REFUND_CANCELLED` - User cancelled the refund
- `REFUND_FAILED` - Refund processing failed

**QRC:**
- `QRC_PAYMENT_CANCELLED` - QRC payment was cancelled
- `QRC_PAYMENT_FAILED` - QRC payment processing failed
- `QRC_REFUND_CANCELLED` - QRC refund was cancelled
- `QRC_REFUND_FAILED` - QRC refund processing failed
- `QRC_NOT_SUPPORTED` (iOS) - QRC requires iOS 13+

**Manual Card Entry:**
- `MCE_PAYMENT_CANCELLED` - Manual card entry was cancelled
- `MCE_PAYMENT_FAILED` - Manual card entry failed
- `MCE_REFUND_CANCELLED` - MCE refund was cancelled
- `MCE_REFUND_FAILED` - MCE refund failed
- `INVALID_REFERENCE` (iOS) - Reference must be a valid UUID for MCE on iOS

## Example App

See the [example](example/) directory for a complete working example demonstrating all features.

## Platform-Specific Notes

### Android

- Requires API level 24 (Android 7.0) or higher
- Requires GitHub authentication to download the Zettle SDK
- Uses Activity Result API for handling payment flows

### iOS

- Requires iOS 13.0 or higher
- The SDK uses SwiftUI and Combine frameworks
- Automatic integration via CocoaPods

## Testing

### Development Mode

Set `isDevMode: true` in your `ZettleConfig` to use Zettle's test environment:

```dart
ZettleConfig(
  clientId: 'YOUR_CLIENT_ID',
  redirectUrl: 'your-app://zettle/callback',
  isDevMode: true,  // Uses Zettle test environment
)
```

## Feature Roadmap / TODO

This plugin currently implements **~85% of the native SDK functionality**. Below are features from the native SDKs that are not yet implemented:

### Phase 2 - Enhancement Features 🟡

#### Transaction Metadata (Android Only)
Add custom key-value pairs to transactions for tracking and analytics:
```dart
// Not yet implemented
TransactionReference.Builder(reference)
  .put("ORDER_ID", "12345")
  .put("CUSTOMER_ID", "customer-789")
  .build()
```

#### Enhanced Retrieve Implementation
Currently `retrievePaymentInfo()`, `retrieveQRCPaymentInfo()`, and `retrieveManualCardEntryInfo()` have limited implementations:
- **Android:** Card reader retrieve not implemented; QRC and MCE retrieves not implemented
- **iOS:** Card reader retrieve implemented; MCE retrieve implemented; QRC not implemented

### Phase 3 - Advanced Features 🟢

#### Auth State Observation
Real-time authentication state changes via streams instead of polling:
```dart
// Not yet implemented
zettleSdk.authStateStream.listen((authState) {
  if (authState == AuthState.loggedIn) {
    // Handle logged in
  } else {
    // Handle logged out
  }
});
```

#### Custom Timeout Configuration
Allow developers to configure payment timeout durations.

### Platform-Specific Limitations

#### Settings Screen Differences
- **Android**: Provides separate settings screens for different features (card reader, manual entry, QRC, tipping)
- **iOS**: Provides a unified settings view that includes all settings in one screen

#### Android vs iOS Feature Parity
Some features have platform-specific availability:
- **Installments:** Android only (not available in iOS SDK)
- **Separate Settings Screens:** Android only (iOS has unified settings view)
- **BN Code (Manual Card Entry):** Android only

### Current Implementation Status

| Feature                     | Android | iOS | Status                         |
|-----------------------------|---------|-----|--------------------------------|
| Authentication              | ✅       | ✅   | Complete                       |
| Card Reader Payments        | ✅       | ✅   | Complete                       |
| Card Reader Refunds         | ✅       | ✅   | Complete                       |
| QRC Payments (PayPal/Venmo) | ✅       | ✅   | Complete                       |
| QRC Refunds                 | ✅       | ✅   | Complete                       |
| Manual Card Entry Payments  | ✅       | ✅   | Complete                       |
| Manual Card Entry Refunds   | ✅       | ✅   | Complete                       |
| Tipping Configuration       | ✅       | ✅   | Complete                       |
| Installments                | ✅       | N/A | Complete (Android only)        |
| Settings Screens            | ✅       | ✅   | Complete (unified view on iOS) |
| Retrieve Card Payment       | ⚠️      | ✅   | iOS only                       |
| Retrieve MCE Payment        | ❌       | ✅   | iOS only                       |
| Retrieve QRC Payment        | ❌       | ❌   | Not implemented                |
| Transaction Metadata        | ❌       | N/A | Not implemented                |
| Auth State Stream           | ❌       | ❌   | Not implemented                |

### Contributing

Want to help implement these features? Contributions are welcome! The codebase is well-structured and documented. Check the existing implementations for patterns to follow.

Priority features for contribution:
1. **Enhanced Retrieve Implementation** - Fill in the gaps for Android
2. **Transaction Metadata** - Useful for order tracking
3. **Auth State Stream** - Better developer experience

## Resources

- [Zettle Developer Portal](https://developer.zettle.com/)
- [Android SDK Documentation](https://developer.zettle.com/docs/payment-integrations/android-sdk)
- [iOS SDK Documentation](https://developer.zettle.com/docs/payment-integrations/ios-sdk)
- [Zettle API Reference](https://developer.zettle.com/docs/api)

## License

This project is licensed under the BSD 3 License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues related to this Flutter plugin, please file an issue on this repository.

For issues related to the Zettle SDK itself, please contact [Zettle Developer Support](https://developer.zettle.com).

