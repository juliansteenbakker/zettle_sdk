import Flutter
import UIKit
import iZettleSDK

public class ZettleSdkPlugin: NSObject, FlutterPlugin {
    private var isInitialized = false
    private var clientId: String?
    private var redirectUrl: String?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "zettle_sdk", binaryMessenger: registrar.messenger())
        let instance = ZettleSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)

        case "initialize":
            initialize(call: call, result: result)

        case "login":
            login(result: result)

        case "logout":
            logout(result: result)

        case "isLoggedIn":
            isLoggedIn(result: result)

        case "charge":
            charge(call: call, result: result)

        case "refund":
            refund(call: call, result: result)

        case "retrievePaymentInfo":
            retrievePaymentInfo(call: call, result: result)

        case "chargeQRC":
            chargeQRC(call: call, result: result)

        case "refundQRC":
            refundQRC(call: call, result: result)

        case "retrieveQRCPaymentInfo":
            retrieveQRCPaymentInfo(call: call, result: result)

        case "chargeManualCardEntry":
            chargeManualCardEntry(call: call, result: result)

        case "refundManualCardEntry":
            refundManualCardEntry(call: call, result: result)

        case "retrieveManualCardEntryInfo":
            retrieveManualCardEntryInfo(call: call, result: result)

        case "openSettings":
            openSettings(call: call, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let clientId = args["clientId"] as? String,
              let redirectUrl = args["redirectUrl"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "clientId and redirectUrl are required", details: nil))
            return
        }

        // Store configuration for later use
        self.clientId = clientId
        self.redirectUrl = redirectUrl

        // iOS SDK doesn't require explicit initialization with auth provider
        // Authentication happens automatically within payment flows
        isInitialized = true
        result(nil)
    }

    private func login(result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized. Call initialize() first.", details: nil))
            return
        }

        // iOS SDK handles authentication automatically within payment flows
        // There's no separate login method in the iOS SDK
        // Return success to maintain API compatibility
        result(nil)
    }

    private func logout(result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized. Call initialize() first.", details: nil))
            return
        }

        // iOS SDK doesn't expose a logout method
        // Authentication is managed automatically by the SDK
        // Return success to maintain API compatibility
        result(nil)
    }

    private func isLoggedIn(result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized. Call initialize() first.", details: nil))
            return
        }

        // iOS SDK doesn't expose auth state directly
        // Return true if initialized, as auth happens automatically
        result(true)
    }

    private func charge(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized. Call initialize() first.", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let amount = args["amount"] as? Int,
              let reference = args["reference"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "amount and reference are required", details: nil))
            return
        }

        guard let viewController = getRootViewController() else {
            result(FlutterError(code: "NO_VIEWCONTROLLER", message: "Unable to get view controller", details: nil))
            return
        }

        let amountDecimal = NSDecimalNumber(value: Double(amount) / 100.0)

        var tippingConfiguration: IZSDKTippingConfiguration = .disabled()
        if let tippingConfig = args["tippingConfiguration"] as? [String: Any] {
            tippingConfiguration = parseTippingConfiguration(tippingConfig)
        }

        iZettleSDK.shared().charge(
            amount: amountDecimal,
            tippingConfiguration: tippingConfiguration,
            reference: reference,
            presentFrom: viewController
        ) { paymentInfo, error in
            if let error = error {
                self.handlePaymentError(error: error, result: result, operation: "PAYMENT")
            } else if let paymentInfo = paymentInfo {
                let resultMap: [String: Any?] = [
                    "referenceId": paymentInfo.referenceNumber,
                    "amount": Int(paymentInfo.amount.doubleValue * 100),
                    "cardBrand": paymentInfo.cardBrand,
                    "cardholderName": nil, // Not available in iOS SDK
                    "obfuscatedPan": paymentInfo.obfuscatedPan,
                    "additionalData": nil
                ]
                result(resultMap)
            } else {
                result(FlutterError(code: "PAYMENT_ERROR", message: "Unknown error", details: nil))
            }
        }
    }

    private func refund(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized. Call initialize() first.", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let paymentReferenceId = args["paymentReferenceId"] as? String,
              let refundReference = args["refundReference"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentReferenceId and refundReference are required", details: nil))
            return
        }

        guard let viewController = getRootViewController() else {
            result(FlutterError(code: "NO_VIEWCONTROLLER", message: "Unable to get view controller", details: nil))
            return
        }

        var refundAmount: NSDecimalNumber? = nil
        if let amount = args["amount"] as? Int {
            refundAmount = NSDecimalNumber(value: Double(amount) / 100.0)
        }

        iZettleSDK.shared().refund(
            amount: refundAmount,
            ofPayment: paymentReferenceId,
            withRefundReference: refundReference,
            presentFrom: viewController
        ) { paymentInfo, error in
            if let error = error {
                self.handlePaymentError(error: error, result: result, operation: "REFUND")
            } else if let paymentInfo = paymentInfo {
                let resultMap: [String: Any?] = [
                    "referenceId": paymentInfo.referenceNumber,
                    "refundedAmount": Int(paymentInfo.amount.doubleValue * 100),
                    "cardBrand": paymentInfo.cardBrand,
                    "obfuscatedPan": paymentInfo.obfuscatedPan,
                    "additionalData": nil
                ]
                result(resultMap)
            } else {
                result(FlutterError(code: "REFUND_ERROR", message: "Unknown error", details: nil))
            }
        }
    }

    private func retrievePaymentInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized. Call initialize() first.", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let referenceId = args["referenceId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "referenceId is required", details: nil))
            return
        }

        guard let viewController = getRootViewController() else {
            result(FlutterError(code: "NO_VIEWCONTROLLER", message: "Unable to get view controller", details: nil))
            return
        }

        iZettleSDK.shared().retrievePaymentInfo(for: referenceId, presentFrom: viewController) { paymentInfo, error in
            if let error = error {
                result(FlutterError(code: "RETRIEVE_FAILED", message: error.localizedDescription, details: nil))
            } else if let paymentInfo = paymentInfo {
                let resultMap: [String: Any?] = [
                    "referenceId": paymentInfo.referenceNumber,
                    "amount": Int(paymentInfo.amount.doubleValue * 100),
                    "cardBrand": paymentInfo.cardBrand,
                    "cardholderName": nil, // Not available in iOS SDK
                    "obfuscatedPan": paymentInfo.obfuscatedPan,
                    "additionalData": nil
                ]
                result(resultMap)
            } else {
                result(FlutterError(code: "RETRIEVE_ERROR", message: "Unknown error", details: nil))
            }
        }
    }

    // QRC Payment Methods

    private func chargeQRC(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized. Call initialize() first.", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let amount = args["amount"] as? Int,
              let reference = args["reference"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "amount and reference are required", details: nil))
            return
        }

        guard let viewController = getRootViewController() else {
            result(FlutterError(code: "NO_VIEWCONTROLLER", message: "Unable to get view controller", details: nil))
            return
        }

        let paymentType = args["paymentType"] as? String ?? "paypal"
        let amountDecimal = NSDecimalNumber(value: Double(amount) / 100.0)

        if #available(iOS 13, *) {
            let appearance: IZSDKPayPalQRCAppearance = (paymentType == "venmo") ? .venmo : .payPal

            iZettleSDK.shared().chargePayPalQRC(
                amount: amountDecimal,
                reference: reference,
                appearance: appearance,
                presentFrom: viewController
            ) { paymentInfo, error in
                if let error = error {
                    self.handleQRCError(error: error, result: result, operation: "payment")
                } else if let paymentInfo = paymentInfo {
                    let resultMap: [String: Any?] = [
                        "referenceId": paymentInfo.referenceNumber,
                        "amount": Int(paymentInfo.amount.doubleValue * 100),
                        "paymentType": paymentType,
                        "additionalData": nil
                    ]
                    result(resultMap)
                } else {
                    result(FlutterError(code: "QRC_PAYMENT_ERROR", message: "Unknown error", details: nil))
                }
            }
        } else {
            result(FlutterError(code: "QRC_NOT_SUPPORTED", message: "QRC payments require iOS 13+", details: nil))
        }
    }

    private func refundQRC(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized. Call initialize() first.", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let paymentReferenceId = args["paymentReferenceId"] as? String,
              let refundReference = args["refundReference"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentReferenceId and refundReference are required", details: nil))
            return
        }

        guard let viewController = getRootViewController() else {
            result(FlutterError(code: "NO_VIEWCONTROLLER", message: "Unable to get view controller", details: nil))
            return
        }

        let paymentType = args["paymentType"] as? String ?? "paypal"
        var refundAmount: NSDecimalNumber? = nil
        if let amount = args["amount"] as? Int {
            refundAmount = NSDecimalNumber(value: Double(amount) / 100.0)
        }

        if #available(iOS 13, *) {
            iZettleSDK.shared().refundPayPalQRC(
                amount: refundAmount,
                ofPayment: paymentReferenceId,
                withRefundReference: refundReference,
                presentFrom: viewController
            ) { paymentInfo, error in
                if let error = error {
                    self.handleQRCError(error: error, result: result, operation: "refund")
                } else if let paymentInfo = paymentInfo {
                    let resultMap: [String: Any?] = [
                        "referenceId": paymentInfo.referenceNumber,
                        "refundedAmount": Int(paymentInfo.amount.doubleValue * 100),
                        "paymentType": paymentType,
                        "additionalData": nil
                    ]
                    result(resultMap)
                } else {
                    result(FlutterError(code: "QRC_REFUND_ERROR", message: "Unknown error", details: nil))
                }
            }
        } else {
            result(FlutterError(code: "QRC_NOT_SUPPORTED", message: "QRC refunds require iOS 13+", details: nil))
        }
    }

    private func retrieveQRCPaymentInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterError(code: "NOT_IMPLEMENTED", message: "retrieveQRCPaymentInfo not yet implemented on iOS", details: nil))
    }

    // Manual Card Entry Methods

    private func chargeManualCardEntry(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized. Call initialize() first.", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let amount = args["amount"] as? Int,
              let reference = args["reference"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "amount and reference are required", details: nil))
            return
        }

        guard let viewController = getRootViewController() else {
            result(FlutterError(code: "NO_VIEWCONTROLLER", message: "Unable to get view controller", details: nil))
            return
        }

        let amountDecimal = NSDecimalNumber(value: Double(amount) / 100.0)
        guard let uuid = UUID(uuidString: reference) else {
            result(FlutterError(code: "INVALID_REFERENCE", message: "reference must be a valid UUID", details: nil))
            return
        }

        iZettleSDK.shared().chargeManualCardEntry(
            amount: amountDecimal,
            reference: uuid,
            presentFrom: viewController
        ) { paymentInfo, error in
            if let error = error {
                self.handleMCEError(error: error, result: result, operation: "payment")
            } else if let paymentInfo = paymentInfo {
                let resultMap: [String: Any?] = [
                    "referenceId": paymentInfo.referenceNumber,
                    "amount": Int(paymentInfo.amount.doubleValue * 100),
                    "cardBrand": nil, // Not available on IZSDKManualCardEntryPaymentInfo
                    "obfuscatedPan": nil, // Not available on IZSDKManualCardEntryPaymentInfo
                    "additionalData": nil
                ]
                result(resultMap)
            } else {
                result(FlutterError(code: "MCE_PAYMENT_ERROR", message: "Unknown error", details: nil))
            }
        }
    }

    private func refundManualCardEntry(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized. Call initialize() first.", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let paymentReferenceId = args["paymentReferenceId"] as? String,
              let refundReference = args["refundReference"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentReferenceId and refundReference are required", details: nil))
            return
        }

        guard let viewController = getRootViewController() else {
            result(FlutterError(code: "NO_VIEWCONTROLLER", message: "Unable to get view controller", details: nil))
            return
        }

        guard let paymentUUID = UUID(uuidString: paymentReferenceId),
              let refundUUID = UUID(uuidString: refundReference) else {
            result(FlutterError(code: "INVALID_REFERENCE", message: "references must be valid UUIDs", details: nil))
            return
        }

        var refundAmount: NSDecimalNumber? = nil
        if let amount = args["amount"] as? Int {
            refundAmount = NSDecimalNumber(value: Double(amount) / 100.0)
        }

        iZettleSDK.shared().refundManualCardEntry(
            amount: refundAmount,
            ofPayment: paymentUUID,
            withRefundReference: refundUUID,
            presentFrom: viewController
        ) { paymentInfo, error in
            if let error = error {
                self.handleMCEError(error: error, result: result, operation: "refund")
            } else if let paymentInfo = paymentInfo {
                let resultMap: [String: Any?] = [
                    "referenceId": paymentInfo.referenceNumber,
                    "refundedAmount": Int(paymentInfo.amount.doubleValue * 100),
                    "cardBrand": nil, // Not available on IZSDKManualCardEntryPaymentInfo
                    "obfuscatedPan": nil, // Not available on IZSDKManualCardEntryPaymentInfo
                    "additionalData": nil
                ]
                result(resultMap)
            } else {
                result(FlutterError(code: "MCE_REFUND_ERROR", message: "Unknown error", details: nil))
            }
        }
    }

    private func retrieveManualCardEntryInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized. Call initialize() first.", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let referenceId = args["referenceId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "referenceId is required", details: nil))
            return
        }

        guard let viewController = getRootViewController() else {
            result(FlutterError(code: "NO_VIEWCONTROLLER", message: "Unable to get view controller", details: nil))
            return
        }

        guard let uuid = UUID(uuidString: referenceId) else {
            result(FlutterError(code: "INVALID_REFERENCE", message: "reference must be a valid UUID", details: nil))
            return
        }

        iZettleSDK.shared().retrieveManualCardEntryInfo(
            for: uuid,
            presentFrom: viewController
        ) { paymentInfo, error in
            if let error = error {
                result(FlutterError(code: "MCE_RETRIEVE_FAILED", message: error.localizedDescription, details: nil))
            } else if let paymentInfo = paymentInfo {
                let resultMap: [String: Any?] = [
                    "referenceId": paymentInfo.referenceNumber,
                    "amount": Int(paymentInfo.amount.doubleValue * 100),
                    "cardBrand": nil, // Not available on IZSDKManualCardEntryPaymentInfo
                    "obfuscatedPan": nil, // Not available on IZSDKManualCardEntryPaymentInfo
                    "additionalData": nil
                ]
                result(resultMap)
            } else {
                result(FlutterError(code: "MCE_RETRIEVE_ERROR", message: "Unknown error", details: nil))
            }
        }
    }

    // Settings Methods

    private func openSettings(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized. Call initialize() first.", details: nil))
            return
        }

        guard let viewController = getRootViewController() else {
            result(FlutterError(code: "NO_VIEWCONTROLLER", message: "Unable to get view controller", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let settingsType = args["settingsType"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "settingsType is required", details: nil))
            return
        }

        // iOS SDK has limited settings screens compared to Android
        // Most settings are handled within the payment flows themselves
        switch settingsType {
        case "cardReader":
            // Card reader settings are typically accessed through the payment flow
            result(FlutterError(code: "NOT_AVAILABLE", message: "Card reader settings are managed through the payment flow on iOS", details: nil))
        case "manualCardEntry":
            result(FlutterError(code: "NOT_AVAILABLE", message: "Manual card entry settings are not available as a separate screen on iOS", details: nil))
        case "qrcPayPal", "qrcVenmo":
            result(FlutterError(code: "NOT_AVAILABLE", message: "QRC settings are not available as a separate screen on iOS", details: nil))
        case "tipping":
            result(FlutterError(code: "NOT_AVAILABLE", message: "Tipping settings are configured within the payment flow on iOS", details: nil))
        default:
            result(FlutterError(code: "INVALID_SETTINGS_TYPE", message: "Unknown settings type: \(settingsType)", details: nil))
        }
    }

    // Helper Methods

    private func parseTippingConfiguration(_ config: [String: Any]) -> IZSDKTippingConfiguration {
        let zettleStyle = config["zettleReaderTippingStyle"] as? String ?? "none"
        let paypalStyle = config["payPalReaderTippingStyle"] as? String ?? "none"

        var ztrStyle: IZZettleReaderTippingStyle = .none
        switch zettleStyle {
        case "amount":
            ztrStyle = .amount
        case "percentage":
            ztrStyle = .percentage
        default:
            ztrStyle = .none
        }

        var pprStyle: IZPayPalReaderTippingStyle = .none
        var predefinedValues: IZSDKPredefinedTippingValues? = nil

        if paypalStyle == "predefinedPercentage" {
            if let percentages = config["payPalReaderPredefinedPercentages"] as? [Int], percentages.count == 3 {
                predefinedValues = IZSDKPredefinedTippingValues(
                    option1: UInt(percentages[0]),
                    option2: UInt(percentages[1]),
                    option3: UInt(percentages[2])
                )
                pprStyle = .predefinedPercentage
            }
        }

        if let predefinedValues = predefinedValues {
            return IZSDKTippingConfiguration(
                zettleReaderTippingStyle: ztrStyle,
                paypalReaderTippingStyle: pprStyle,
                paypalReaderPredefinedTippingValues: predefinedValues
            )
        } else {
            return IZSDKTippingConfiguration(
                zettleReaderTippingStyle: ztrStyle,
                paypalReaderTippingStyle: pprStyle
            )
        }
    }

    private func handlePaymentError(error: Error, result: @escaping FlutterResult, operation: String) {
        let nsError = error as NSError
        // Check if this is an iZettle SDK error (domain contains "iZettle")
        if nsError.domain.contains("iZettle") {
            // Check for user cancellation (typically code 1)
            if nsError.code == 1 {
                result(FlutterError(code: "\(operation)_CANCELLED", message: "\(operation) was cancelled", details: nil))
            } else {
                result(FlutterError(code: "\(operation)_FAILED", message: error.localizedDescription, details: nil))
            }
        } else {
            result(FlutterError(code: "\(operation)_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    private func handleQRCError(error: Error, result: @escaping FlutterResult, operation: String) {
        let nsError = error as NSError
        if nsError.domain.contains("iZettle") {
            if nsError.code == 1 {
                result(FlutterError(code: "QRC_\(operation.uppercased())_CANCELLED", message: "QRC \(operation) was cancelled", details: nil))
            } else {
                result(FlutterError(code: "QRC_\(operation.uppercased())_FAILED", message: error.localizedDescription, details: nil))
            }
        } else {
            result(FlutterError(code: "QRC_\(operation.uppercased())_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    private func handleMCEError(error: Error, result: @escaping FlutterResult, operation: String) {
        let nsError = error as NSError
        if nsError.domain.contains("iZettle") {
            if nsError.code == 1 {
                result(FlutterError(code: "MCE_\(operation.uppercased())_CANCELLED", message: "Manual card entry \(operation) was cancelled", details: nil))
            } else {
                result(FlutterError(code: "MCE_\(operation.uppercased())_FAILED", message: error.localizedDescription, details: nil))
            }
        } else {
            result(FlutterError(code: "MCE_\(operation.uppercased())_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    private func getRootViewController() -> UIViewController? {
        var keyWindow: UIWindow? = nil

        if #available(iOS 13.0, *) {
            keyWindow = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
                .first?
                .windows
                .first { $0.isKeyWindow }
        } else {
            keyWindow = UIApplication.shared.keyWindow
        }

        return keyWindow?.rootViewController
    }
}
