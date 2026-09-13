# Changelog

## [1.1.0](https://github.com/juliansteenbakker/zettle_sdk/compare/v1.0.0...v1.1.0) (2026-09-13)


### Features

* migrate to AGP 9 and Kotlin Gradle DSL ([a6f7999](https://github.com/juliansteenbakker/zettle_sdk/commit/a6f79991bc3d80dc0a3978d2093bbb7d135af245))


### Bug Fixes

* bump AGP to 8.13.0 ([c39009c](https://github.com/juliansteenbakker/zettle_sdk/commit/c39009c462984e43bffcb52fdd7d486b82f671db))
* bump example Gradle wrapper to 8.14.5 ([359b780](https://github.com/juliansteenbakker/zettle_sdk/commit/359b7807411277661815d45f6554665eef7cad35))
* bump Kotlin to 2.2.21 ([3bc95ed](https://github.com/juliansteenbakker/zettle_sdk/commit/3bc95ede1d194307cb5f281eaeff14ea31f3d0a8))
* remove hardcoded JDK path and placeholder Maven credentials from example gradle.properties ([a7b7de4](https://github.com/juliansteenbakker/zettle_sdk/commit/a7b7de45874e92a68fbd944e667969382c7ac8f5))


### Dependencies

* bump org.mockito:mockito-core from 5.0.0 to 5.23.0 in /android ([5f08257](https://github.com/juliansteenbakker/zettle_sdk/commit/5f082579049105f0ceb21bc339da76dce8bb0907))
* bump zettleVersion from 2.38.2 to 2.52.1 in /android ([c8729a0](https://github.com/juliansteenbakker/zettle_sdk/commit/c8729a0f39196e6a3c0a6e22e52996826eee08b0))

## 1.0.0

### Added
- Initial release of zettle_sdk Flutter plugin
- **Authentication**: OAuth-based login/logout with deep link support
- **Card Reader Payments**: Process payments with Zettle card readers
- **Card Reader Refunds**: Full and partial refund support
- **QR Code Payments**: Support for PayPal and Venmo QRC payments
- **QR Code Refunds**: Refund QRC transactions
- **Manual Card Entry**: Process payments without a card reader
- **Manual Card Entry Refunds**: Refund manual card entry transactions
- **Tipping Configuration**: Customizable tipping for Zettle and PayPal readers
- **Installments**: Enable installment payments (Android only)
- **Settings Screens**: Native settings UI for card readers, tipping, and payment methods
- **Payment Retrieval**: Retrieve payment information by reference ID
- **Multi-platform Support**: Full support for Android (API 24+) and iOS (13.0+)
- **Development Mode**: Test environment support for development

### Platform-Specific Features
- **Android**: Separate settings screens, installments support, BN code for manual card entry
- **iOS**: Unified settings view, comprehensive Info.plist configuration guide

### Documentation
- Comprehensive README with setup instructions
- Deep link configuration guide for OAuth
- Platform-specific setup instructions
- API reference and code examples
- Error handling documentation
- Feature roadmap and contribution guidelines
