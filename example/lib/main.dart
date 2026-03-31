import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:arke_sdk_flutter/arke_sdk_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _arke = ArkeSdkFlutter();
  Map<String, String> _terminalInfo = {};
  bool _isConnected = false;
  int _beepDuration = 1000;
  int _selectedAlign = 1;
  final List<String> _statusLog = [];

  void _updateStatus(String message) {
    debugPrint('[ExampleStatus] $message');
    if (!mounted) return;
    final time = DateTime.now().toString().split('.').first.split(' ').last;
    setState(() {
      _statusLog.insert(0, '[$time] $message');
      if (_statusLog.length > 50) _statusLog.removeLast();
    });
  }

  // LED state
  final Map<String, bool> _ledStates = {
    'red': false,
    'green': false,
    'yellow': false,
    'blue': false,
  };

  StreamSubscription<VasEvent>? _vasSubscription;
  Completer<void>? _pendingVasDataCompleter;
  String? _pendingVasDataReason;

  final _vasAmountController = TextEditingController(text: '100.0');
  final _vasOrderNumberController = TextEditingController();
  final _vasVoucherController = TextEditingController();
  final _vasRefController = TextEditingController();
  final _vasTransTypeController = TextEditingController(text: 'ADJUST');
  final _vasTransNameController = TextEditingController(text: 'ADJUST');
  final _vasOrigTransDateController = TextEditingController();
  final _vasOrigAuthCodeController = TextEditingController();
  Map<String, dynamic>? _lastResolvedSaleData;

  String? _trimmedText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String? _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  Iterable<Map<String, dynamic>> _candidateMaps(
      Map<String, dynamic> data) sync* {
    yield data;
    for (final value in data.values) {
      if (value is Map) {
        yield* _candidateMaps(Map<String, dynamic>.from(value));
      }
    }
  }

  String? _findEventValue(Map<String, dynamic> data, List<String> keys) {
    for (final candidate in _candidateMaps(data)) {
      final value = _firstString(candidate, keys);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  void _clearVasReferenceFields() {
    _vasVoucherController.clear();
    _vasRefController.clear();
    _vasOrigTransDateController.clear();
    _vasOrigAuthCodeController.clear();
  }

  List<String> _missingAdjustTipsFields() {
    final missing = <String>[];
    if (_trimmedText(_vasVoucherController) == null) missing.add('voucher');
    return missing;
  }

  Future<bool> _waitForVasData({
    required String reason,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    _pendingVasDataCompleter?.complete();
    final completer = Completer<void>();
    _pendingVasDataCompleter = completer;
    _pendingVasDataReason = reason;

    try {
      await completer.future.timeout(timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      if (identical(_pendingVasDataCompleter, completer)) {
        _pendingVasDataCompleter = null;
        _pendingVasDataReason = null;
      }
    }
  }

  Future<bool> _hydrateAdjustTipsReferences(String? orderNumber) async {
    if (orderNumber == null) {
      return false;
    }

    _updateStatus('Missing sale refs. Querying transaction by order number...');
    final waitFuture = _waitForVasData(reason: 'orderNumberQuery');
    await _arke.vas.orderNumberQuery(VasRequestBody(orderNumber: orderNumber));
    final received = await waitFuture;

    if (!received) {
      _updateStatus('orderNumberQuery timed out before refs were returned');
      return false;
    }

    final stillMissing = _missingAdjustTipsFields();
    if (stillMissing.isNotEmpty) {
      _updateStatus(
        'orderNumberQuery completed but refs still missing: ${stillMissing.join(", ")}',
      );
      return false;
    }

    _updateStatus('Recovered sale refs from orderNumberQuery');
    return true;
  }

  @override
  void dispose() {
    _vasAmountController.dispose();
    _vasOrderNumberController.dispose();
    _vasVoucherController.dispose();
    _vasRefController.dispose();
    _vasTransTypeController.dispose();
    _vasTransNameController.dispose();
    _vasOrigTransDateController.dispose();
    _vasOrigAuthCodeController.dispose();
    _vasSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _generateOrderNumber();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _arke.getPlatformVersion() ?? 'Unknown';
      _isConnected = true;
      _updateStatus('SDK Connected: $platformVersion');
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
      _isConnected = false;
      _updateStatus('SDK Connection Failed');
    }

    if (!mounted) return;
    setState(() => _platformVersion = platformVersion);

    if (_isConnected) _getTerminalInfo();

    _vasSubscription?.cancel();
    _vasSubscription = _arke.vas.vasEvents.listen((event) {
      if (!mounted) return;
      debugPrint('VAS Event: ${event.type}, Data: ${event.data}');
      _updateStatus('VAS Event: ${event.type}');
      if (event.data != null && event.data!.isNotEmpty) {
        _updateStatus('Data: ${event.data}');
        final responseCode = event.data!['responseCode'];
        final responseMessage = event.data!['responseMessage'];
        if (responseCode != null || responseMessage != null) {
          _updateStatus(
            'VAS Response: code=${responseCode ?? "-"} message=${responseMessage ?? "-"}',
          );
        }
        _pendingVasDataCompleter?.complete();
      }

      // Auto-fill tracking fields if present in the response
      if (event.data != null) {
        final data = event.data!;
        _updateStatus('VAS Keys: ${data.keys.join(", ")}');

        final voucher = _findEventValue(data, [
          'voucherNumber',
          'voucherNo',
          'traceNo',
          'origVoucherNumber',
          'origVoucherNo',
        ]);
        if (voucher != null) {
          _vasVoucherController.text = voucher;
        }

        final reference = _findEventValue(data, [
          'referenceNumber',
          'referenceNo',
          'refNo',
          'hostSerialNo',
          'originalReferenceNumber',
          'origReferenceNo',
          'origRefNo',
        ]);
        if (reference != null) {
          _vasRefController.text = reference;
        }

        final authCode = _findEventValue(data, [
          'authCode',
          'authorizationCode',
          'originalAuthorizationCode',
          'origAuthCode',
        ]);
        if (authCode != null) {
          _vasOrigAuthCodeController.text = authCode;
        }

        final transDate = _findEventValue(data, [
          'date',
          'transDate',
          'transactionDate',
          'originalTransactionDate',
          'origTransDate',
        ]);
        if (transDate != null) {
          _vasOrigTransDateController.text = transDate;
        } else if (data.containsKey('orderNumber')) {
          // Fallback: extract YYYYMMDD from our generated order number.
          final orderStr = data['orderNumber'].toString();
          if (orderStr.length >= 8) {
            _vasOrigTransDateController.text = orderStr.substring(0, 8);
          }
        }

        if (event.type == 'onComplete') {
          final interfaceId = _findEventValue(data, ['interfaceId']);
          final transactionType = _findEventValue(data, ['transactionType']);
          if (interfaceId == 'SALE' ||
              interfaceId == 'ORDER_NUMBER_INQUIRY' ||
              transactionType == 'SALE') {
            _lastResolvedSaleData = Map<String, dynamic>.from(data);
          }
        }
      }
    }, onError: (e) {
      if (!mounted) return;
      _updateStatus('VAS Event Error: $e');
    });
  }

  Future<void> _getTerminalInfo() async {
    _updateStatus('Fetching Terminal Info...');
    try {
      final info = await _arke.getTerminalInfo();
      if (info != null) {
        setState(() => _terminalInfo = info);
        _updateStatus('Terminal Info Fetched');
      }
    } catch (e) {
      _updateStatus('Info Fetch Error: $e');
    }
  }

  Future<void> _beep() async {
    _updateStatus('Beeping for ${_beepDuration}ms...');
    try {
      await _arke.beep(milliseconds: _beepDuration);
      _updateStatus('Beep Success');
    } catch (e) {
      _updateStatus('Beep Error: $e');
    }
  }

  // ==================== Printer ====================

  Future<void> _printTestReceipt() async {
    _updateStatus('Printing Receipt...');
    try {
      await _arke.printText("--- ARKE SDK TEST ---", align: 1);
      await _arke.printText("Model: ${_terminalInfo['model'] ?? 'N/A'}",
          align: 0);
      await _arke.printText("Serial: ${_terminalInfo['serialNo'] ?? 'N/A'}",
          align: 0);
      await _arke.printText("OS: $_platformVersion", align: 0);
      await _arke.printText("\nFlutter Plugin Test!\n", align: 1);
      await _arke.printText("---------------------", align: 1);
      _updateStatus('Print Receipt Success');
    } catch (e) {
      _updateStatus('Print Error: $e');
    }
  }

  Future<void> _printBarcode() async {
    _updateStatus('Printing Barcode...');
    try {
      await _arke.printBarcode('1234567890',
          align: 1, codeWidth: 2, codeHeight: -1);
      _updateStatus('Barcode Print Success');
    } catch (e) {
      _updateStatus('Barcode Error: $e');
    }
  }

  Future<void> _printQrCode() async {
    _updateStatus('Printing QR Code...');
    try {
      await _arke.printQrCode('https://flutter.dev',
          align: 1, imageHeight: 200, ecLevel: 3);
      _updateStatus('QR Code Print Success');
    } catch (e) {
      _updateStatus('QR Code Error: $e');
    }
  }

  Future<void> _getPrinterStatus() async {
    _updateStatus('Checking Printer...');
    try {
      final status = await _arke.getPrinterStatus();
      _updateStatus('Printer Status: $status');
    } catch (e) {
      _updateStatus('Printer Status Error: $e');
    }
  }

  // ==================== LED ====================

  Future<void> _toggleLed(String color) async {
    try {
      if (_ledStates[color] == true) {
        await _arke.ledTurnOff([color]);
        setState(() => _ledStates[color] = false);
        _updateStatus('${color.toUpperCase()} LED OFF');
      } else {
        await _arke.ledTurnOn([color]);
        setState(() => _ledStates[color] = true);
        _updateStatus('${color.toUpperCase()} LED ON');
      }
    } catch (e) {
      _updateStatus('LED Error: $e');
    }
  }

  Future<void> _ledAllOn() async {
    try {
      await _arke.ledTurnOnAll();
      setState(() => _ledStates.updateAll((key, value) => true));
      _updateStatus('All LEDs ON');
    } catch (e) {
      _updateStatus('LED Error: $e');
    }
  }

  Future<void> _ledAllOff() async {
    try {
      await _arke.ledTurnOffAll();
      setState(() => _ledStates.updateAll((key, value) => false));
      _updateStatus('All LEDs OFF');
    } catch (e) {
      _updateStatus('LED Error: $e');
    }
  }

  // ==================== Scanner ====================

  Future<void> _startScanner({bool front = false}) async {
    _updateStatus(
        front ? 'Starting Front Scanner...' : 'Starting Back Scanner...');
    try {
      final code =
          front ? await _arke.startFrontScanner() : await _arke.startScanner();
      _updateStatus('Scan Result: $code');
    } catch (e) {
      _updateStatus('Scan Error: $e');
    }
  }

  // ==================== NFC ====================

  Future<void> _startNfcScan() async {
    _updateStatus('Please tap card...');
    try {
      final uid = await _arke.startNfcScan();
      _updateStatus('Card UID: $uid');
    } catch (e) {
      _updateStatus('NFC Error: $e');
    }
  }

  // ==================== Mag Card Reader ====================

  Future<void> _startMagReader() async {
    _updateStatus('Swipe card now...');
    try {
      final data = await _arke.startMagReader(timeout: 30);
      if (data != null && data.isNotEmpty) {
        final parts =
            data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
        _updateStatus('Mag Card: $parts');
      } else {
        _updateStatus('No card data');
      }
    } catch (e) {
      _updateStatus('Mag Reader Error: $e');
    }
  }

  // ==================== VAS ====================

  void _generateOrderNumber() {
    final now = DateTime.now();
    final orderId =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}"
        "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
    setState(() => _vasOrderNumberController.text = orderId);
  }

  Future<void> _vasBind() async {
    _updateStatus('Binding to VAS...');
    try {
      await _arke.vas.bindService();
    } catch (e) {
      _updateStatus('VAS Bind Error: $e');
    }
  }

  Future<void> _vasSignIn() async {
    _updateStatus('SignIn to VAS...');
    try {
      await _arke.vas.signIn();
    } catch (e) {
      _updateStatus('VAS SignIn Error: $e');
    }
  }

  Future<void> _vasSale() async {
    _updateStatus('Starting sale...');
    try {
      _clearVasReferenceFields();
      _lastResolvedSaleData = null;
      final amount = double.tryParse(_vasAmountController.text) ?? 0.0;
      await _arke.vas.sale(VasRequestBody(
        amount: amount,
        orderNumber: _vasOrderNumberController.text.isNotEmpty
            ? _vasOrderNumberController.text
            : null,
      ));
    } catch (e) {
      _updateStatus('VAS sale Error: $e');
    }
  }

  Future<void> _vasSettle() async {
    _updateStatus('Starting Settle via VAS...');
    try {
      await _arke.vas.settle();
    } catch (e) {
      _updateStatus('VAS Settle Error: $e');
    }
  }

  Future<void> _vasBalance() async {
    _updateStatus('Checking Balance via VAS...');
    try {
      await _arke.vas.balance();
    } catch (e) {
      _updateStatus('VAS Balance Error: $e');
    }
  }

  Future<void> _vasRefund() async {
    _updateStatus('Starting refund...');
    try {
      final amount = double.tryParse(_vasAmountController.text) ?? 0.0;
      await _arke.vas.refund(VasRequestBody(
        amount: amount,
        orderNumber: _vasOrderNumberController.text.isNotEmpty
            ? _vasOrderNumberController.text
            : null,
        originalVoucherNumber: _vasVoucherController.text.isNotEmpty
            ? _vasVoucherController.text
            : null,
        originalReferenceNumber:
            _vasRefController.text.isNotEmpty ? _vasRefController.text : null,
        originalTransactionDate: _vasOrigTransDateController.text.isNotEmpty
            ? _vasOrigTransDateController.text
            : null,
      ));
    } catch (e) {
      _updateStatus('VAS refund Error: $e');
    }
  }

  Future<void> _vasAdjustTips() async {
    _updateStatus('Starting adjustTips...');
    try {
      final amount = double.tryParse(_vasAmountController.text) ?? 0.0;
      final orderNumber = _trimmedText(_vasOrderNumberController);
      var missing = _missingAdjustTipsFields();
      if (missing.isNotEmpty) {
        final hydrated = await _hydrateAdjustTipsReferences(orderNumber);
        if (!hydrated) {
          _updateStatus(
            'Adjust tips still requires completed sale refs: ${missing.join(", ")}',
          );
          return;
        }
        missing = _missingAdjustTipsFields();
        if (missing.isNotEmpty) {
          _updateStatus(
            'Adjust tips still requires completed sale refs: ${missing.join(", ")}',
          );
          return;
        }
      }

      final voucher = _trimmedText(_vasVoucherController);
      final reference = _trimmedText(_vasRefController);
      final authCode = _trimmedText(_vasOrigAuthCodeController);
      final cardNumber = _lastResolvedSaleData?['cardNumber']?.toString();
      final expiryDate = _lastResolvedSaleData?['expirationDate']?.toString();

      final optionalMissing = <String>[];
      if (reference == null) optionalMissing.add('reference');
      if (authCode == null) optionalMissing.add('auth code');
      if (optionalMissing.isNotEmpty) {
        _updateStatus(
          'Adjust tips proceeding without optional refs: ${optionalMissing.join(", ")}',
        );
      }

      _updateStatus(
        'Sending adjustTips with voucher=$voucher ref=$reference auth=$authCode card=$cardNumber',
      );
      await _arke.vas.adjustTips(VasRequestBody(
        amount: amount,
        orderNumber: orderNumber,
        originalVoucherNumber: voucher,
        originalReferenceNumber: reference,
        authorizationCode: authCode,
        originalAuthorizationCode: authCode,
        cardNumber: cardNumber,
        expiryDate: expiryDate,
      ));
      _updateStatus('adjustTips request sent. Waiting for VAS event...');
      final received = await _waitForVasData(
        reason: 'adjustTips',
        timeout: const Duration(seconds: 15),
      );
      if (!received) {
        _updateStatus(
          'Adjust tips timed out waiting for VAS event. This usually means the service still needs original reference/auth data from Arke Pay internal records.',
        );
      }
    } catch (e) {
      _updateStatus('VAS adjustTips Error: $e');
    }
  }

  Future<void> _vasSettlementAdjustment() async {
    _updateStatus('Starting settlementAdjustment...');
    try {
      final amount = double.tryParse(_vasAmountController.text) ?? 0.0;
      await _arke.vas.settlementAdjustment(VasRequestBody(
        amount: amount,
        orderNumber: _vasOrderNumberController.text.isNotEmpty
            ? _vasOrderNumberController.text
            : null,
        originalVoucherNumber: _vasVoucherController.text.isNotEmpty
            ? _vasVoucherController.text
            : null,
        originalReferenceNumber:
            _vasRefController.text.isNotEmpty ? _vasRefController.text : null,
        originalTransactionDate: _vasOrigTransDateController.text.isNotEmpty
            ? _vasOrigTransDateController.text
            : null,
        originalAuthorizationCode: _vasOrigAuthCodeController.text.isNotEmpty
            ? _vasOrigAuthCodeController.text
            : null,
      ));
    } catch (e) {
      _updateStatus('VAS settlementAdjustment Error: $e');
    }
  }

  Future<void> _vasVoided() async {
    _updateStatus('Starting voided...');
    try {
      await _arke.vas.voided(VasRequestBody(
        orderNumber: _vasOrderNumberController.text.isNotEmpty
            ? _vasOrderNumberController.text
            : null,
        originalVoucherNumber: _vasVoucherController.text.isNotEmpty
            ? _vasVoucherController.text
            : null,
        originalReferenceNumber:
            _vasRefController.text.isNotEmpty ? _vasRefController.text : null,
      ));
    } catch (e) {
      _updateStatus('VAS voided Error: $e');
    }
  }

  Future<void> _vasPreAuth() async {
    _updateStatus('Starting preAuthorization...');
    try {
      final amount = double.tryParse(_vasAmountController.text) ?? 0.0;
      await _arke.vas.preAuthorization(VasRequestBody(
        amount: amount,
        orderNumber: _vasOrderNumberController.text.isNotEmpty
            ? _vasOrderNumberController.text
            : null,
      ));
    } catch (e) {
      _updateStatus('VAS preAuthorization Error: $e');
    }
  }

  Future<void> _vasPreAuthVoid() async {
    _updateStatus('Starting preAuthorizationVoid...');
    try {
      final amount = double.tryParse(_vasAmountController.text) ?? 0.0;
      await _arke.vas.preAuthorizationVoid(VasRequestBody(
        amount: amount,
        orderNumber: _vasOrderNumberController.text.isNotEmpty
            ? _vasOrderNumberController.text
            : null,
        originalVoucherNumber: _vasVoucherController.text.isNotEmpty
            ? _vasVoucherController.text
            : null,
        originalReferenceNumber:
            _vasRefController.text.isNotEmpty ? _vasRefController.text : null,
        originalTransactionDate: _vasOrigTransDateController.text.isNotEmpty
            ? _vasOrigTransDateController.text
            : null,
        originalAuthorizationCode: _vasOrigAuthCodeController.text.isNotEmpty
            ? _vasOrigAuthCodeController.text
            : null,
      ));
    } catch (e) {
      _updateStatus('VAS preAuthorizationVoid Error: $e');
    }
  }

  Future<void> _vasPreAuthCompletionAdvice() async {
    _updateStatus('Starting preAuthorizationCompletionAdvice...');
    try {
      final amount = double.tryParse(_vasAmountController.text) ?? 0.0;
      await _arke.vas.preAuthorizationCompletionAdvice(VasRequestBody(
        amount: amount,
        orderNumber: _vasOrderNumberController.text.isNotEmpty
            ? _vasOrderNumberController.text
            : null,
        originalVoucherNumber: _vasVoucherController.text.isNotEmpty
            ? _vasVoucherController.text
            : null,
        originalReferenceNumber:
            _vasRefController.text.isNotEmpty ? _vasRefController.text : null,
        originalTransactionDate: _vasOrigTransDateController.text.isNotEmpty
            ? _vasOrigTransDateController.text
            : null,
        originalAuthorizationCode: _vasOrigAuthCodeController.text.isNotEmpty
            ? _vasOrigAuthCodeController.text
            : null,
      ));
    } catch (e) {
      _updateStatus('VAS preAuthorizationCompletionAdvice Error: $e');
    }
  }

  Future<void> _vasPreAuthCompletionRequest() async {
    _updateStatus('Starting preAuthorizationCompletionRequest...');
    try {
      final amount = double.tryParse(_vasAmountController.text) ?? 0.0;
      await _arke.vas.preAuthorizationCompletionRequest(VasRequestBody(
        amount: amount,
        orderNumber: _vasOrderNumberController.text.isNotEmpty
            ? _vasOrderNumberController.text
            : null,
        originalVoucherNumber: _vasVoucherController.text.isNotEmpty
            ? _vasVoucherController.text
            : null,
        originalReferenceNumber:
            _vasRefController.text.isNotEmpty ? _vasRefController.text : null,
        originalTransactionDate: _vasOrigTransDateController.text.isNotEmpty
            ? _vasOrigTransDateController.text
            : null,
        originalAuthorizationCode: _vasOrigAuthCodeController.text.isNotEmpty
            ? _vasOrigAuthCodeController.text
            : null,
      ));
    } catch (e) {
      _updateStatus('VAS preAuthorizationCompletionRequest Error: $e');
    }
  }

  Future<void> _vasPreAuthCompletionVoid() async {
    _updateStatus('Starting preAuthorizationCompletionVoid...');
    try {
      await _arke.vas.preAuthorizationCompletionVoid(VasRequestBody(
        orderNumber: _vasOrderNumberController.text.isNotEmpty
            ? _vasOrderNumberController.text
            : null,
        originalVoucherNumber: _vasVoucherController.text.isNotEmpty
            ? _vasVoucherController.text
            : null,
        originalReferenceNumber:
            _vasRefController.text.isNotEmpty ? _vasRefController.text : null,
      ));
    } catch (e) {
      _updateStatus('VAS preAuthorizationCompletionVoid Error: $e');
    }
  }

  Future<void> _vasDoAction() async {
    _updateStatus('Executing doAction via VAS...');
    try {
      final amount = double.tryParse(_vasAmountController.text) ?? 0.0;
      await _arke.vas.doAction(VasRequestBody(
        amount: amount,
        orderNumber: _vasOrderNumberController.text.isNotEmpty
            ? _vasOrderNumberController.text
            : null,
        originalVoucherNumber: _vasVoucherController.text.isNotEmpty
            ? _vasVoucherController.text
            : null,
        originalReferenceNumber:
            _vasRefController.text.isNotEmpty ? _vasRefController.text : null,
        transType: _vasTransTypeController.text.isNotEmpty
            ? _vasTransTypeController.text
            : null,
        transName: _vasTransNameController.text.isNotEmpty
            ? _vasTransNameController.text
            : null,
      ));
    } catch (e) {
      _updateStatus('VAS doAction Error: $e');
    }
  }

  Future<void> _scanServices() async {
    _updateStatus('Scanning com.arke.vas package...');
    String result = await _arke.vas.scanVasServices();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("VAS Services Found"),
        content: SingleChildScrollView(child: Text(result)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
    _updateStatus('Scan Complete');
  }

  Future<void> _showActionConfig() async {
    _updateStatus('Fetching VAS action config...');
    try {
      final result = await _arke.vas.getActionConfig();
      _updateStatus(
        'VAS Action Config: ${result.isEmpty ? "<empty>" : result}',
      );
      _updateStatus('Action config fetched');
    } catch (e) {
      _updateStatus('VAS action config error: $e');
    }
  }

  Future<void> _showTaskConfig() async {
    _updateStatus('Fetching VAS task config...');
    try {
      final result = await _arke.vas.getTaskConfig();
      _updateStatus(
        'VAS Task Config: ${result.isEmpty ? "<empty>" : result}',
      );
      _updateStatus('Task config fetched');
    } catch (e) {
      _updateStatus('VAS task config error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Arke SDK Example',
                style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.important_devices), text: 'Terminal'),
                Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scanning'),
                Tab(icon: Icon(Icons.payments), text: 'Payments'),
                Tab(icon: Icon(Icons.settings), text: 'Maintenance'),
              ],
            ),
          ),
          body: Column(
            children: [
              _buildCompactHeader(),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTerminalTab(),
                    _buildScanningTab(),
                    _buildPaymentsTab(),
                    _buildMaintenanceTab(),
                  ],
                ),
              ),
              _buildLogView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.error,
            color: _isConnected ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isConnected
                  ? 'Connected: ${_terminalInfo['model'] ?? 'Arke Device'}'
                  : 'Disconnected',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    _isConnected ? Colors.green.shade900 : Colors.red.shade900,
              ),
            ),
          ),
          Text(
            'OS: $_platformVersion',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          IconButton(
            onPressed: initPlatformState,
            icon: const Icon(Icons.refresh, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildLogView() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border:
            Border(top: BorderSide(color: Colors.indigo.shade400, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EVENT LOG',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => setState(() => _statusLog.clear()),
                  child: const Text('CLEAR',
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _statusLog.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _statusLog[index],
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontFamily: 'monospace'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Tabs ====================

  Widget _buildTerminalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoSection(),
          const SizedBox(height: 16),
          _buildBeeperSection(),
          const SizedBox(height: 16),
          _buildLedSection(),
        ],
      ),
    );
  }

  Widget _buildScanningTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildScannerSection(),
          const SizedBox(height: 16),
          _buildNfcSection(),
          const SizedBox(height: 16),
          _buildMagReaderSection(),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVasInputSection(),
          const SizedBox(height: 16),
          _buildVasTransactionSection(),
          const SizedBox(height: 16),
          _buildVasPreAuthSection(),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMaintenanceSection(),
          const SizedBox(height: 16),
          _buildPrinterSection(),
        ],
      ),
    );
  }

  // ==================== Sections ====================

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('System Information',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed: _getTerminalInfo,
                    icon: const Icon(Icons.sync, size: 20)),
              ],
            ),
            const Divider(),
            _infoRow('Model', _terminalInfo['model'] ?? 'N/A'),
            _infoRow('Serial', _terminalInfo['serialNo'] ?? 'N/A'),
            _infoRow('Firmware', _terminalInfo['firmwareVersion'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildBeeperSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Beeper', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _beepDuration.toDouble(),
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    onChanged: (val) =>
                        setState(() => _beepDuration = val.round()),
                  ),
                ),
                Text('${_beepDuration}ms'),
              ],
            ),
            FilledButton.icon(
              onPressed: _isConnected ? _beep : null,
              icon: const Icon(Icons.volume_up),
              label: const Text('Test Beep'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(40)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LED Notifications',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ledIcon('red', Colors.red),
                _ledIcon('green', Colors.green),
                _ledIcon('yellow', Colors.amber),
                _ledIcon('blue', Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: FilledButton.tonal(
                        onPressed: _isConnected ? _ledAllOn : null,
                        child: const Text('All ON'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(
                        onPressed: _isConnected ? _ledAllOff : null,
                        child: const Text('All OFF'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ledIcon(String color, Color displayColor) {
    final isOn = _ledStates[color] == true;
    return InkWell(
      onTap: _isConnected ? () => _toggleLed(color) : null,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOn ? displayColor : Colors.transparent,
          border: Border.all(color: displayColor, width: 2),
          boxShadow: isOn
              ? [BoxShadow(color: displayColor.withOpacity(0.5), blurRadius: 8)]
              : [],
        ),
        child: Icon(Icons.lightbulb,
            color: isOn ? Colors.white : displayColor.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildScannerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Camera Scanner',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _isConnected ? () => _startScanner(front: false) : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed:
                        _isConnected ? () => _startScanner(front: true) : null,
                    icon: const Icon(Icons.camera_front),
                    label: const Text('Front'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNfcSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NFC / Contactless',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isConnected ? _startNfcScan : null,
              icon: const Icon(Icons.contactless),
              label: const Text('Start NFC Scan'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMagReaderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Magnetic Stripe Reader',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isConnected ? _startMagReader : null,
              icon: const Icon(Icons.credit_card),
              label: const Text('Wait for Swipe'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVasInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaction Details',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _vasAmountController,
              decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '฿ ',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vasOrderNumberController,
                    decoration: const InputDecoration(
                        labelText: 'Order Number',
                        border: OutlineInputBorder()),
                  ),
                ),
                IconButton(
                    onPressed: _generateOrderNumber,
                    icon: const Icon(Icons.auto_fix_high)),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('Optional Reference Fields',
                  style: TextStyle(fontSize: 13, color: Colors.indigo)),
              tilePadding: EdgeInsets.zero,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: _vasVoucherController,
                            decoration: const InputDecoration(
                                labelText: 'Voucher No'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: _vasRefController,
                            decoration:
                                const InputDecoration(labelText: 'Ref No'))),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: _vasOrigTransDateController,
                            decoration: const InputDecoration(
                                labelText: 'Orig Date (YYYYMMDD)'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: _vasOrigAuthCodeController,
                            decoration: const InputDecoration(
                                labelText: 'Orig Auth Code'))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVasTransactionSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: FilledButton.icon(
                    onPressed: _isConnected ? _vasSale : null,
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Sale'))),
            const SizedBox(width: 8),
            Expanded(
                child: FilledButton.tonalIcon(
                    onPressed: _isConnected ? _vasRefund : null,
                    icon: const Icon(Icons.history),
                    label: const Text('Refund'))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: _isConnected ? _vasAdjustTips : null,
                    icon: const Icon(Icons.add_task),
                    label: const Text('Adjust Tips'))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: _isConnected ? _vasSettlementAdjustment : null,
                    icon: const Icon(Icons.fact_check),
                    label: const Text('Settle Adj'))),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: _isConnected ? _vasVoided : null,
          icon: const Icon(Icons.cancel),
          label: const Text('Void Transaction'),
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red),
        ),
      ],
    );
  }

  Widget _buildVasPreAuthSection() {
    return Card(
      color: Colors.blue.shade50.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pre-Authorization',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: _isConnected ? _vasPreAuth : null,
                        child: const Text('Pre-Auth'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(
                        onPressed: _isConnected ? _vasPreAuthVoid : null,
                        child: const Text('PA Void'))),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Completion:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                    child: TextButton(
                        onPressed:
                            _isConnected ? _vasPreAuthCompletionAdvice : null,
                        child: const Text('Advice',
                            style: TextStyle(fontSize: 11)))),
                Expanded(
                    child: TextButton(
                        onPressed:
                            _isConnected ? _vasPreAuthCompletionRequest : null,
                        child: const Text('Request',
                            style: TextStyle(fontSize: 11)))),
                Expanded(
                    child: TextButton(
                        onPressed:
                            _isConnected ? _vasPreAuthCompletionVoid : null,
                        child: const Text('Void Comp',
                            style: TextStyle(fontSize: 11)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Operations',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: FilledButton.icon(
                        onPressed: _isConnected ? _vasBind : null,
                        icon: const Icon(Icons.link),
                        label: const Text('Service Bind'))),
                const SizedBox(width: 8),
                Expanded(
                    child: FilledButton.tonalIcon(
                        onPressed: _isConnected ? _vasSignIn : null,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign In'))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _isConnected ? _vasBalance : null,
                        icon: const Icon(Icons.account_balance),
                        label: const Text('Balance'))),
                const SizedBox(width: 8),
                Expanded(
                    child: FilledButton(
                        onPressed: _isConnected ? _vasSettle : null,
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal),
                        child: const Text('Settlement'))),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const Text('Debugging / Advanced',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: _scanServices,
                        child: const Text('Scan VAS Services',
                            style: TextStyle(fontSize: 11)))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(
                        onPressed: _isConnected ? _vasDoAction : null,
                        child: const Text('Custom doAction',
                            style: TextStyle(fontSize: 11)))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: _isConnected ? _showActionConfig : null,
                        child: const Text('Action Config',
                            style: TextStyle(fontSize: 11)))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(
                        onPressed: _isConnected ? _showTaskConfig : null,
                        child: const Text('Task Config',
                            style: TextStyle(fontSize: 11)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Printer Utils',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Center(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                      value: 0,
                      label: Text('Left'),
                      icon: Icon(Icons.format_align_left)),
                  ButtonSegment(
                      value: 1,
                      label: Text('Center'),
                      icon: Icon(Icons.format_align_center)),
                  ButtonSegment(
                      value: 2,
                      label: Text('Right'),
                      icon: Icon(Icons.format_align_right)),
                ],
                selected: {_selectedAlign},
                onSelectionChanged: (val) =>
                    setState(() => _selectedAlign = val.first),
                showSelectedIcon: false,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: _isConnected ? _printTestReceipt : null,
                icon: const Icon(Icons.receipt),
                label: const Text('Print Text Slip')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _isConnected ? _printBarcode : null,
                        icon: const Icon(Icons.barcode_reader),
                        label: const Text('Barcode'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _isConnected ? _printQrCode : null,
                        icon: const Icon(Icons.qr_code),
                        label: const Text('QR'))),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                onPressed: _isConnected ? _getPrinterStatus : null,
                icon: const Icon(Icons.monitor_heart),
                label: const Text('Check Printer Health'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(36))),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }
}
