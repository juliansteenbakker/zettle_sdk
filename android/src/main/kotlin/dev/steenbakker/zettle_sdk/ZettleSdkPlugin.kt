package dev.steenbakker.zettle_sdk

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Parcelable
import androidx.lifecycle.ProcessLifecycleOwner
import com.zettle.sdk.ZettleSDK
import com.zettle.sdk.ZettleSDKLifecycle
import com.zettle.sdk.config
import com.zettle.sdk.core.auth.User
import com.zettle.sdk.feature.cardreader.payment.PayPalReaderTippingStyle
import com.zettle.sdk.feature.cardreader.payment.TippingConfiguration
import com.zettle.sdk.feature.cardreader.payment.ZettleReaderTippingStyle
import com.zettle.sdk.feature.cardreader.payment.TransactionReference
import com.zettle.sdk.feature.cardreader.ui.CardReaderAction
import com.zettle.sdk.feature.cardreader.ui.CardReaderFeature
import com.zettle.sdk.feature.cardreader.ui.payment.CardPaymentResult
import com.zettle.sdk.feature.cardreader.ui.refunds.RefundResult
import com.zettle.sdk.feature.manualcardentry.ui.ManualCardEntryAction
import com.zettle.sdk.feature.manualcardentry.ui.ManualCardEntryFeature
import com.zettle.sdk.feature.qrc.QrcAction
import com.zettle.sdk.feature.qrc.paypal.PayPalQrcAction
import com.zettle.sdk.feature.qrc.paypal.PayPalQrcFeature
import com.zettle.sdk.feature.qrc.venmo.VenmoQrcAction
import com.zettle.sdk.feature.qrc.venmo.VenmoQrcFeature
import com.zettle.sdk.features.charge
import com.zettle.sdk.features.refund
import com.zettle.sdk.features.show
import com.zettle.sdk.ui.ZettleResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import androidx.lifecycle.Observer

class ZettleSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var authStateChannel: EventChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private var isInitialized = false
    private var authStateEventSink: EventChannel.EventSink? = null
    private val authStateObserver = Observer<User.AuthState> { authState ->
        val isLoggedIn = authState is User.AuthState.LoggedIn
        authStateEventSink?.success(isLoggedIn)
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "zettle_sdk")
        channel.setMethodCallHandler(this)

        authStateChannel = EventChannel(flutterPluginBinding.binaryMessenger, "zettle_sdk/auth_state")
        authStateChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                authStateEventSink = events
                // Send current state immediately
                ZettleSDK.instance?.authState?.value?.let { authState ->
                    val isLoggedIn = authState is User.AuthState.LoggedIn
                    events?.success(isLoggedIn)
                }
            }

            override fun onCancel(arguments: Any?) {
                authStateEventSink = null
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }

            "initialize" -> initialize(call, result)
            "login" -> login(result)
            "logout" -> logout(result)
            "isLoggedIn" -> isLoggedIn(result)
            "charge" -> charge(call, result)
            "refund" -> refund(call, result)
            "retrievePaymentInfo" -> retrievePaymentInfo(call, result)
            "chargeQRC" -> chargeQRC(call, result)
            "refundQRC" -> refundQRC(call, result)
            "retrieveQRCPaymentInfo" -> retrieveQRCPaymentInfo(call, result)
            "chargeManualCardEntry" -> chargeManualCardEntry(call, result)
            "refundManualCardEntry" -> refundManualCardEntry(call, result)
            "retrieveManualCardEntryInfo" -> retrieveManualCardEntryInfo(call, result)
            "openSettings" -> openSettings(call, result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(call: MethodCall, result: Result) {
        try {
            val clientId = call.argument<String>("clientId")
                ?: throw IllegalArgumentException("clientId is required")
            val redirectUrl = call.argument<String>("redirectUrl")
                ?: throw IllegalArgumentException("redirectUrl is required")
            val isDevMode = call.argument<Boolean>("isDevMode") ?: false

            val config = config(context) {
                this.isDevMode = isDevMode
                auth {
                    this.clientId = clientId
                    this.redirectUrl = redirectUrl
                }
                addFeature(CardReaderFeature)
                addFeature(PayPalQrcFeature)
                addFeature(VenmoQrcFeature)
                addFeature(ManualCardEntryFeature)
            }

            val sdk = ZettleSDK.configure(config)
            ProcessLifecycleOwner.get().lifecycle.addObserver(ZettleSDKLifecycle())
            sdk.start()

            // Observe auth state changes
            sdk.authState.observeForever(authStateObserver)

            isInitialized = true
            result.success(null)
        } catch (e: Exception) {
            result.error("INITIALIZATION_ERROR", e.message, null)
        }
    }

    private fun login(result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            ZettleSDK.instance?.login(currentActivity)
            result.success(null)
        } catch (e: Exception) {
            result.error("LOGIN_ERROR", e.message, null)
        }
    }

    private fun logout(result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        try {
            ZettleSDK.instance?.logout()
            result.success(null)
        } catch (e: Exception) {
            result.error("LOGOUT_ERROR", e.message, null)
        }
    }

    private fun isLoggedIn(result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        try {
            val authState = ZettleSDK.instance?.authState?.value
            val loggedIn = authState is User.AuthState.LoggedIn
            result.success(loggedIn)
        } catch (e: Exception) {
            result.error("AUTH_STATE_ERROR", e.message, null)
        }
    }

    private fun charge(call: MethodCall, result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            val amount = call.argument<Int>("amount")?.toLong()
                ?: throw IllegalArgumentException("amount is required")
            val reference = call.argument<String>("reference")
                ?: throw IllegalArgumentException("reference is required")
            val enableInstallments = call.argument<Boolean>("enableInstallments") ?: false

            val tippingConfig = call.argument<Map<String, Any>>("tippingConfiguration")?.let {
                parseTippingConfiguration(it)
            }

            // TODO: To receive revenue attribution, specify a unique Build Notation (BN) code as an argument to the function. BN codes track all transactions that originate or are associated with a particular partner. To find your BN code, see Code and Credential Reference.
            val transactionReference = TransactionReference.Builder(reference).build()

            pendingResult = result

            val intent = CardReaderAction.Payment(
                reference = transactionReference,
                amount = amount,
                tippingConfiguration = tippingConfig,
                enableInstallments = enableInstallments
                // OPTIONAL, set payment properties

                // Example: The payee-pricing-tier-id is a code created by Partner managers, SGMs or sales to set pricing tier. This code is included in the Card payments API calls.
//                readerPaymentProperties = readerPaymentProperties
            ).charge(currentActivity)

            currentActivity.startActivityForResult(intent, CHARGE_REQUEST_CODE)
        } catch (e: Exception) {
            result.error("CHARGE_ERROR", e.message, null)
        }
    }

    private fun refund(call: MethodCall, result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            val amount = call.argument<Int>("amount")?.toLong()
            val paymentReferenceId = call.argument<String>("paymentReferenceId")
                ?: throw IllegalArgumentException("paymentReferenceId is required")
            val refundReference = call.argument<String>("refundReference")
                ?: throw IllegalArgumentException("refundReference is required")

            val transactionReference = TransactionReference.Builder(refundReference).build()

            pendingResult = result

            val intent = if (amount != null) {
                CardReaderAction.Refund(
                    amount = amount,
                    paymentReferenceId = paymentReferenceId,
                    refundReference = transactionReference
                ).refund(currentActivity)
            } else {
                CardReaderAction.Refund(
                    paymentReferenceId = paymentReferenceId,
                    refundReference = transactionReference
                ).refund(currentActivity)
            }

            currentActivity.startActivityForResult(intent, REFUND_REQUEST_CODE)
        } catch (e: Exception) {
            result.error("REFUND_ERROR", e.message, null)
        }
    }

    @Suppress("UNUSED_PARAMETER")
    private fun retrievePaymentInfo(call: MethodCall, result: Result) {
        result.error("NOT_IMPLEMENTED", "retrievePaymentInfo not yet implemented on Android", null)
    }

    // QRC Methods

    private fun chargeQRC(call: MethodCall, result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            val amount = call.argument<Int>("amount")?.toLong()
                ?: throw IllegalArgumentException("amount is required")
            val reference = call.argument<String>("reference")
                ?: throw IllegalArgumentException("reference is required")
            val paymentType = call.argument<String>("paymentType") ?: "paypal"

            pendingResult = result

            val intent = when (paymentType) {
                "venmo" -> VenmoQrcAction.Payment(amount = amount, reference = reference).charge(currentActivity)
                else -> PayPalQrcAction.Payment(amount = amount, reference = reference).charge(currentActivity)
            }

            currentActivity.startActivityForResult(intent, QRC_CHARGE_REQUEST_CODE)
        } catch (e: Exception) {
            result.error("QRC_CHARGE_ERROR", e.message, null)
        }
    }

    private fun refundQRC(call: MethodCall, result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            val amount = call.argument<Int>("amount")?.toLong() ?: 0L
            val paymentReferenceId = call.argument<String>("paymentReferenceId")
                ?: throw IllegalArgumentException("paymentReferenceId is required")
            val refundReference = call.argument<String>("refundReference")
                ?: throw IllegalArgumentException("refundReference is required")
            val paymentType = call.argument<String>("paymentType") ?: "paypal"

            pendingResult = result

            val intent = when (paymentType) {
                "venmo" -> VenmoQrcAction.Refund(
                    amount = amount,
                    paymentReference = paymentReferenceId,
                    refundReference = refundReference
                ).refund(currentActivity)
                else -> PayPalQrcAction.Refund(
                    amount = amount,
                    paymentReference = paymentReferenceId,
                    refundReference = refundReference
                ).refund(currentActivity)
            }

            currentActivity.startActivityForResult(intent, QRC_REFUND_REQUEST_CODE)
        } catch (e: Exception) {
            result.error("QRC_REFUND_ERROR", e.message, null)
        }
    }

    @Suppress("UNUSED_PARAMETER")
    private fun retrieveQRCPaymentInfo(call: MethodCall, result: Result) {
        result.error("NOT_IMPLEMENTED", "retrieveQRCPaymentInfo not yet implemented on Android", null)
    }

    // Manual Card Entry Methods

    private fun chargeManualCardEntry(call: MethodCall, result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            val amount = call.argument<Int>("amount")?.toLong()
                ?: throw IllegalArgumentException("amount is required")
            val reference = call.argument<String>("reference")
                ?: throw IllegalArgumentException("reference is required")
            val bnCode = call.argument<String>("bnCode")

            pendingResult = result

            val intent = if (bnCode != null) {
                ManualCardEntryAction.Payment(amount, reference, bnCode).charge(currentActivity)
            } else {
                ManualCardEntryAction.Payment(amount, reference).charge(currentActivity)
            }

            currentActivity.startActivityForResult(intent, MCE_CHARGE_REQUEST_CODE)
        } catch (e: Exception) {
            result.error("MCE_CHARGE_ERROR", e.message, null)
        }
    }

    private fun refundManualCardEntry(call: MethodCall, result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            val amount = call.argument<Int>("amount")?.toLong() ?: 0L
            val paymentReferenceId = call.argument<String>("paymentReferenceId")
                ?: throw IllegalArgumentException("paymentReferenceId is required")
            val refundReference = call.argument<String>("refundReference")
                ?: throw IllegalArgumentException("refundReference is required")

            pendingResult = result

            val intent = ManualCardEntryAction.Refund(
                amount = amount,
                paymentReference = paymentReferenceId,
                refundReference = refundReference
            ).refund(currentActivity)

            currentActivity.startActivityForResult(intent, MCE_REFUND_REQUEST_CODE)
        } catch (e: Exception) {
            result.error("MCE_REFUND_ERROR", e.message, null)
        }
    }

    @Suppress("UNUSED_PARAMETER")
    private fun retrieveManualCardEntryInfo(call: MethodCall, result: Result) {
        result.error("NOT_IMPLEMENTED", "retrieveManualCardEntryInfo not yet implemented on Android", null)
    }

    // Settings Methods

    private fun openSettings(call: MethodCall, result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            val settingsType = call.argument<String>("settingsType") ?: "cardReader"

            val intent = when (settingsType) {
                "manualCardEntry" -> ManualCardEntryAction.Activation.show(currentActivity)
                "qrcPayPal" -> PayPalQrcAction.Activation.show(currentActivity)
                "qrcVenmo" -> VenmoQrcAction.Activation.show(currentActivity)
                "tipping" -> CardReaderAction.TippingSettings().show(currentActivity)
                else -> CardReaderAction.Settings.show(currentActivity)
            }

            currentActivity.startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", e.message, null)
        }
    }

    private fun parseTippingConfiguration(config: Map<String, Any>): TippingConfiguration {
        val ztrStyle = when (config["zettleReaderTippingStyle"] as? String) {
            "amount" -> ZettleReaderTippingStyle.Amount
            "percentage" -> ZettleReaderTippingStyle.Percentage
            else -> ZettleReaderTippingStyle.None
        }

        val pprStyle = when (config["payPalReaderTippingStyle"] as? String) {
            "predefinedPercentage" -> PayPalReaderTippingStyle.None
            else -> PayPalReaderTippingStyle.None
        }

        return TippingConfiguration(ztrStyle, pprStyle)
    }

    private fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val result = pendingResult ?: return false

        when (requestCode) {
            CHARGE_REQUEST_CODE -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    handleChargeResult(data, result)
                } else {
                    result.error("PAYMENT_CANCELLED", "Payment was cancelled", null)
                }
                pendingResult = null
                return true
            }
            REFUND_REQUEST_CODE -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    handleRefundResult(data, result)
                } else {
                    result.error("REFUND_CANCELLED", "Refund was cancelled", null)
                }
                pendingResult = null
                return true
            }
            QRC_CHARGE_REQUEST_CODE -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    handleQRCChargeResult(data, result)
                } else {
                    result.error("QRC_PAYMENT_CANCELLED", "QRC payment was cancelled", null)
                }
                pendingResult = null
                return true
            }
            QRC_REFUND_REQUEST_CODE -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    handleQRCRefundResult(data, result)
                } else {
                    result.error("QRC_REFUND_CANCELLED", "QRC refund was cancelled", null)
                }
                pendingResult = null
                return true
            }
            MCE_CHARGE_REQUEST_CODE -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    handleMCEChargeResult(data, result)
                } else {
                    result.error("MCE_PAYMENT_CANCELLED", "Manual card entry was cancelled", null)
                }
                pendingResult = null
                return true
            }
            MCE_REFUND_REQUEST_CODE -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    handleMCERefundResult(data, result)
                } else {
                    result.error("MCE_REFUND_CANCELLED", "Manual card entry refund was cancelled", null)
                }
                pendingResult = null
                return true
            }
        }
        return false
    }

    private fun handleChargeResult(data: Intent, result: Result) {
        try {
            when (val zettleResult = data.getParcelableCompat<ZettleResult>("ZETTLE_RESULT")) {
                is ZettleResult.Completed<*> -> {
                    val payment: CardPaymentResult.Completed = CardReaderAction.fromPaymentResult(zettleResult)
                    val payload = payment.payload

                    val resultMap = hashMapOf<String, Any?>(
                        "referenceId" to payload.reference?.id,
                        "amount" to payload.amount.toInt(),
                    )
                    result.success(resultMap)
                }
                is ZettleResult.Failed -> {
                    result.error("PAYMENT_FAILED", "Payment failed: ${zettleResult.reason}", null)
                }
                is ZettleResult.Cancelled -> {
                    result.error("PAYMENT_CANCELLED", "Payment was cancelled", null)
                }
                else -> {
                    result.error("PAYMENT_ERROR", "Unknown payment result", null)
                }
            }
        } catch (e: Exception) {
            result.error("PAYMENT_ERROR", e.message, null)
        }
    }

    private fun handleRefundResult(data: Intent, result: Result) {
        try {
            when (val zettleResult = data.getParcelableCompat<ZettleResult>("ZETTLE_RESULT")) {
                is ZettleResult.Completed<*> -> {
                    val refund: RefundResult.Completed = CardReaderAction.fromRefundResult(zettleResult)
                    val payload = refund.payload

                    val resultMap = hashMapOf<String, Any?>(
                        "refundedAmount" to payload.refundedAmount.toInt(),
                    )
                    result.success(resultMap)
                }
                is ZettleResult.Failed -> {
                    result.error("REFUND_FAILED", "Refund failed: ${zettleResult.reason}", null)
                }
                is ZettleResult.Cancelled -> {
                    result.error("REFUND_CANCELLED", "Refund was cancelled", null)
                }
                else -> {
                    result.error("REFUND_ERROR", "Unknown refund result", null)
                }
            }
        } catch (e: Exception) {
            result.error("REFUND_ERROR", e.message, null)
        }
    }

    private fun handleQRCChargeResult(data: Intent, result: Result) {
        try {
            when (val zettleResult = data.getParcelableCompat<ZettleResult>("ZETTLE_RESULT")) {
                is ZettleResult.Completed<*> -> {
                    val payment = QrcAction.fromPaymentResult(zettleResult)

                    val resultMap = hashMapOf<String, Any?>(
                        "referenceId" to payment.reference,
                        "amount" to payment.amount.toInt(),
                        "paymentType" to "paypal", // Could be venmo
                    )
                    result.success(resultMap)
                }
                is ZettleResult.Failed -> {
                    result.error("QRC_PAYMENT_FAILED", "QRC payment failed: ${zettleResult.reason}", null)
                }
                is ZettleResult.Cancelled -> {
                    result.error("QRC_PAYMENT_CANCELLED", "QRC payment was cancelled", null)
                }
                else -> {
                    result.error("QRC_PAYMENT_ERROR", "Unknown QRC payment result", null)
                }
            }
        } catch (e: Exception) {
            result.error("QRC_PAYMENT_ERROR", e.message, null)
        }
    }

    private fun handleQRCRefundResult(data: Intent, result: Result) {
        try {
            when (val zettleResult = data.getParcelableCompat<ZettleResult>("ZETTLE_RESULT")) {
                is ZettleResult.Completed<*> -> {
                    val refund = QrcAction.fromRefundResult(zettleResult)

                    val resultMap = hashMapOf<String, Any?>(
                        "referenceId" to refund.reference,
                        "refundedAmount" to refund.amount.toInt(),
                        "paymentType" to "paypal",
                    )
                    result.success(resultMap)
                }
                is ZettleResult.Failed -> {
                    result.error("QRC_REFUND_FAILED", "QRC refund failed: ${zettleResult.reason}", null)
                }
                is ZettleResult.Cancelled -> {
                    result.error("QRC_REFUND_CANCELLED", "QRC refund was cancelled", null)
                }
                else -> {
                    result.error("QRC_REFUND_ERROR", "Unknown QRC refund result", null)
                }
            }
        } catch (e: Exception) {
            result.error("QRC_REFUND_ERROR", e.message, null)
        }
    }

    private fun handleMCEChargeResult(data: Intent, result: Result) {
        try {
            when (val zettleResult = data.getParcelableCompat<ZettleResult>("ZETTLE_RESULT")) {
                is ZettleResult.Completed<*> -> {
                    val payment = ManualCardEntryAction.fromPaymentResult(zettleResult)

                    val resultMap = hashMapOf<String, Any?>(
                        "referenceId" to payment.referenceId,
                        "amount" to payment.amount.toInt(),
                    )
                    result.success(resultMap)
                }
                is ZettleResult.Failed -> {
                    result.error("MCE_PAYMENT_FAILED", "Manual card entry failed: ${zettleResult.reason}", null)
                }
                is ZettleResult.Cancelled -> {
                    result.error("MCE_PAYMENT_CANCELLED", "Manual card entry was cancelled", null)
                }
                else -> {
                    result.error("MCE_PAYMENT_ERROR", "Unknown manual card entry result", null)
                }
            }
        } catch (e: Exception) {
            result.error("MCE_PAYMENT_ERROR", e.message, null)
        }
    }

    private fun handleMCERefundResult(data: Intent, result: Result) {
        try {
            when (val zettleResult = data.getParcelableCompat<ZettleResult>("ZETTLE_RESULT")) {
                is ZettleResult.Completed<*> -> {
                    val refund = ManualCardEntryAction.fromRefundResult(zettleResult)

                    val resultMap = hashMapOf<String, Any?>(
                        "referenceId" to refund.reference,
                        "refundedAmount" to refund.amount.toInt(),
                    )
                    result.success(resultMap)
                }
                is ZettleResult.Failed -> {
                    result.error("MCE_REFUND_FAILED", "Manual card entry refund failed: ${zettleResult.reason}", null)
                }
                is ZettleResult.Cancelled -> {
                    result.error("MCE_REFUND_CANCELLED", "Manual card entry refund was cancelled", null)
                }
                else -> {
                    result.error("MCE_REFUND_ERROR", "Unknown manual card entry refund result", null)
                }
            }
        } catch (e: Exception) {
            result.error("MCE_REFUND_ERROR", e.message, null)
        }
    }

    inline fun <reified T : Parcelable> Intent?.getParcelableCompat(key: String): T? {
        if (this == null) return null
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            getParcelableExtra(key, T::class.java)
        } else {
            @Suppress("DEPRECATION")
            getParcelableExtra(key) as? T
        }
    }


    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        authStateChannel.setStreamHandler(null)
        ZettleSDK.instance?.authState?.removeObserver(authStateObserver)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener { requestCode, resultCode, data ->
            handleActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener { requestCode, resultCode, data ->
            handleActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    companion object {
        private const val CHARGE_REQUEST_CODE = 1001
        private const val REFUND_REQUEST_CODE = 1002
        private const val QRC_CHARGE_REQUEST_CODE = 1003
        private const val QRC_REFUND_REQUEST_CODE = 1004
        private const val MCE_CHARGE_REQUEST_CODE = 1005
        private const val MCE_REFUND_REQUEST_CODE = 1006
    }
}
