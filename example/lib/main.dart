import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:zettle_sdk/zettle_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zettle SDK Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ZettleExample(),
    );
  }
}

class ZettleExample extends StatefulWidget {
  const ZettleExample({super.key});

  @override
  State<ZettleExample> createState() => _ZettleExampleState();
}

class _ZettleExampleState extends State<ZettleExample> {
  final _zettleSdk = ZettleSdk();
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String _statusMessage = 'Not initialized';
  String? _lastPaymentReference;
  final _amountController = TextEditingController(text: '100'); // 1 euro minimum

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    _zettleSdk.authStateStream.listen((isLoggedIn) {
      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _statusMessage = isLoggedIn ? 'Logged in' : 'Not logged in';
        });
      }
    });

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // TODO: Replace YOUR_CLIENT_ID with your actual Zettle Client ID
      // You can get this from https://developer.zettle.com/
      // The redirectUrl must match the deep link configured in AndroidManifest.xml and Info.plist
      await _zettleSdk.initialize(ZettleConfig(
        clientId: 'YOUR_CLIENT_ID',
        redirectUrl: 'zettleexample://zettle/callback',
        isDevMode: false, // Set to false for production
      ));

      setState(() {
        _isInitialized = true;
        _statusMessage = 'SDK initialized successfully';
      });
    } on ZettleException catch (e) {
      setState(() {
        _statusMessage = 'Initialization failed: ${e.message}';
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      final loggedIn = await _zettleSdk.isLoggedIn();
      setState(() {
        _isLoggedIn = loggedIn;
        _statusMessage = loggedIn ? 'Logged in' : 'Not logged in';
      });
    } on ZettleException catch (e) {
      setState(() {
        _statusMessage = 'Error checking login status: ${e.message}';
      });
    }
  }

  Future<void> _login() async {
    try {
      // Check login status first to see if already logged in
      await _checkLoginStatus();

      if (_isLoggedIn) {
        setState(() {
          _statusMessage = 'Already logged in';
        });
        return;
      }

      await _zettleSdk.login();
      await _checkLoginStatus();
    } on ZettleException catch (e) {
      setState(() {
        _statusMessage = 'Login failed: ${e.message}';
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _zettleSdk.logout();
      setState(() {
        _isLoggedIn = false;
        _statusMessage = 'Logged out successfully';
      });
    } on ZettleException catch (e) {
      setState(() {
        _statusMessage = 'Logout failed: ${e.message}';
      });
    }
  }

  Future<void> _processPayment() async {
    // Android requires explicit login, iOS handles auth automatically
    if (!_isLoggedIn && Platform.isAndroid) {
      setState(() {
        _statusMessage = 'Please log in first';
      });
      return;
    }

    try {
      final amount = int.tryParse(_amountController.text) ?? 100;

      // Validate minimum amount (1 euro = 100 cents)
      if (amount < 100) {
        setState(() {
          _statusMessage = 'Minimum amount is 100 cents (€1.00 / \$1.00)';
        });
        return;
      }

      final reference = 'payment_${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _statusMessage = 'Processing payment...';
      });

      final result = await _zettleSdk.charge(
        amount: amount,
        reference: reference,
      );

      setState(() {
        _lastPaymentReference = result.referenceId;
        _statusMessage = 'Payment successful!\n'
            'Reference: ${result.referenceId}\n'
            'Amount: €${(result.amount / 100).toStringAsFixed(2)}\n'
            'Card: ${result.cardBrand ?? 'Unknown'}';
      });
    } on ZettleException catch (e) {
      setState(() {
        _statusMessage = 'Payment failed: ${e.message} (${e.code})';
      });
    }
  }

  Future<void> _refundLastPayment() async {
    if (_lastPaymentReference == null) {
      setState(() {
        _statusMessage = 'No payment to refund';
      });
      return;
    }

    try {
      setState(() {
        _statusMessage = 'Processing refund...';
      });

      final refundReference = 'refund_${DateTime.now().millisecondsSinceEpoch}';
      final result = await _zettleSdk.refund(
        paymentReferenceId: _lastPaymentReference!,
        refundReference: refundReference,
      );

      setState(() {
        _statusMessage = 'Refund successful!\n'
            'Refunded: €${(result.refundedAmount / 100).toStringAsFixed(2)}';
      });
    } on ZettleException catch (e) {
      setState(() {
        _statusMessage = 'Refund failed: ${e.message} (${e.code})';
      });
    }
  }

  Future<void> _openSettings(SettingsScreenType settingsType) async {
    try {
      await _zettleSdk.openSettings(settingsType);
      setState(() {
        _statusMessage = 'Opened $settingsType settings';
      });
    } on ZettleException catch (e) {
      setState(() {
        _statusMessage = 'Failed to open settings: ${e.message} (${e.code})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zettle SDK Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_statusMessage),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _isLoggedIn ? Icons.check_circle : Icons.cancel,
                            color: _isLoggedIn ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_isLoggedIn ? 'Authenticated' : 'Not authenticated'),
                          ),
                          if (_isInitialized)
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Refresh login status',
                              onPressed: _checkLoginStatus,
                              iconSize: 20,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Setup Section
              if (!_isInitialized) ...[
                ElevatedButton.icon(
                  onPressed: _initialize,
                  icon: const Icon(Icons.settings),
                  label: const Text('Initialize SDK'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Note: Update the clientId and redirectUrl in the code with your actual credentials from https://developer.zettle.com/',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],

              // Authentication Section
              if (_isInitialized) ...[
                if (Platform.isAndroid) ...[
                  // Android requires explicit login
                  if (!_isLoggedIn)
                    ElevatedButton.icon(
                      onPressed: _login,
                      icon: const Icon(Icons.login),
                      label: const Text('Login to Zettle'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ] else ...[
                  // iOS: Login is optional, auth happens automatically during payment
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoggedIn ? null : _login,
                          icon: const Icon(Icons.login),
                          label: const Text('Login (Optional)'),
                        ),
                      ),
                      if (_isLoggedIn) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'iOS: Authentication happens automatically during payment',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // Payment Section
              // On iOS, login is optional - auth happens automatically during payment
              // On Android, explicit login is required
              if (_isLoggedIn || Platform.isIOS) ...[
                Text(
                  'Payment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (cents)',
                    hintText: '100 = €1.00 (minimum)',
                    helperText: 'Minimum: 100 cents (€1.00)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _processPayment,
                  icon: const Icon(Icons.payment),
                  label: const Text('Process Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (_lastPaymentReference != null)
                  OutlinedButton.icon(
                    onPressed: _refundLastPayment,
                    icon: const Icon(Icons.replay),
                    label: const Text('Refund Last Payment'),
                  ),

                const SizedBox(height: 24),

                // Settings Section
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                // iOS: Unified settings view
                // Android: Separate settings screens
                if (Platform.isIOS)
                  ElevatedButton.icon(
                    onPressed: () => _openSettings(SettingsScreenType.cardReader),
                    icon: const Icon(Icons.settings),
                    label: const Text('Open Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openSettings(SettingsScreenType.cardReader),
                        icon: const Icon(Icons.credit_card),
                        label: const Text('Card Reader'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openSettings(SettingsScreenType.manualCardEntry),
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Manual Entry'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openSettings(SettingsScreenType.qrcPayPal),
                        icon: const Icon(Icons.qr_code),
                        label: const Text('PayPal QRC'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openSettings(SettingsScreenType.qrcVenmo),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Venmo QRC'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openSettings(SettingsScreenType.tipping),
                        icon: const Icon(Icons.attach_money),
                        label: const Text('Tipping'),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
