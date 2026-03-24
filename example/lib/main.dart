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
  String _statusMessage = 'Initializing...';

  // LED state
  final Map<String, bool> _ledStates = {
    'red': false,
    'green': false,
    'yellow': false,
    'blue': false,
  };

  StreamSubscription<VasEvent>? _vasSubscription;
  String _vasStatus = 'Not Bound';

  @override
  void dispose() {
    _vasSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _arke.getPlatformVersion() ?? 'Unknown';
      _isConnected = true;
      _statusMessage = 'SDK Connected';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
      _isConnected = false;
      _statusMessage = 'SDK Connection Failed';
    }

    if (!mounted) return;
    setState(() => _platformVersion = platformVersion);

    if (_isConnected) _getTerminalInfo();

    _vasSubscription?.cancel();
    _vasSubscription = _arke.vas.vasEvents.listen((event) {
      if (!mounted) return;
      setState(() {
        _vasStatus = 'Event: ${event.type}\nData: ${event.data}';
      });
    }, onError: (e) {
      if (!mounted) return;
      setState(() => _vasStatus = 'Event Error: $e');
    });
  }

  Future<void> _getTerminalInfo() async {
    setState(() => _statusMessage = 'Fetching Terminal Info...');
    try {
      final info = await _arke.getTerminalInfo();
      if (info != null) {
        setState(() {
          _terminalInfo = info;
          _statusMessage = 'Info Fetched';
        });
      }
    } catch (e) {
      setState(() => _statusMessage = 'Fetch Error: $e');
    }
  }

  // ==================== Beeper ====================

  Future<void> _beep() async {
    setState(() => _statusMessage = 'Beeping for ${_beepDuration}ms...');
    try {
      await _arke.beep(milliseconds: _beepDuration);
      setState(() => _statusMessage = 'Beep Success');
    } catch (e) {
      setState(() => _statusMessage = 'Beep Error: $e');
    }
  }

  // ==================== Printer ====================

  Future<void> _printTestReceipt() async {
    setState(() => _statusMessage = 'Printing Receipt...');
    try {
      await _arke.printText("--- ARKE SDK TEST ---", align: 1);
      await _arke.printText("Model: ${_terminalInfo['model'] ?? 'N/A'}", align: 0);
      await _arke.printText("Serial: ${_terminalInfo['serialNo'] ?? 'N/A'}", align: 0);
      await _arke.printText("OS: $_platformVersion", align: 0);
      await _arke.printText("\nFlutter Plugin Test!\n", align: 1);
      await _arke.printText("---------------------", align: 1);
      setState(() => _statusMessage = 'Print Receipt Success');
    } catch (e) {
      setState(() => _statusMessage = 'Print Error: $e');
    }
  }

  Future<void> _printBarcode() async {
    setState(() => _statusMessage = 'Printing Barcode...');
    try {
      await _arke.printBarcode('1234567890', align: 1, codeWidth: 2, codeHeight: -1);
      setState(() => _statusMessage = 'Barcode Print Success');
    } catch (e) {
      setState(() => _statusMessage = 'Barcode Error: $e');
    }
  }

  Future<void> _printQrCode() async {
    setState(() => _statusMessage = 'Printing QR Code...');
    try {
      await _arke.printQrCode('https://flutter.dev', align: 1, imageHeight: 200, ecLevel: 3);
      setState(() => _statusMessage = 'QR Code Print Success');
    } catch (e) {
      setState(() => _statusMessage = 'QR Code Error: $e');
    }
  }

  Future<void> _getPrinterStatus() async {
    setState(() => _statusMessage = 'Checking Printer...');
    try {
      final status = await _arke.getPrinterStatus();
      setState(() => _statusMessage = 'Printer Status: $status');
    } catch (e) {
      setState(() => _statusMessage = 'Printer Status Error: $e');
    }
  }

  // ==================== LED ====================

  Future<void> _toggleLed(String color) async {
    try {
      if (_ledStates[color] == true) {
        await _arke.ledTurnOff([color]);
        setState(() {
          _ledStates[color] = false;
          _statusMessage = '${color.toUpperCase()} LED OFF';
        });
      } else {
        await _arke.ledTurnOn([color]);
        setState(() {
          _ledStates[color] = true;
          _statusMessage = '${color.toUpperCase()} LED ON';
        });
      }
    } catch (e) {
      setState(() => _statusMessage = 'LED Error: $e');
    }
  }

  Future<void> _ledAllOn() async {
    try {
      await _arke.ledTurnOnAll();
      setState(() {
        _ledStates.updateAll((key, value) => true);
        _statusMessage = 'All LEDs ON';
      });
    } catch (e) {
      setState(() => _statusMessage = 'LED Error: $e');
    }
  }

  Future<void> _ledAllOff() async {
    try {
      await _arke.ledTurnOffAll();
      setState(() {
        _ledStates.updateAll((key, value) => false);
        _statusMessage = 'All LEDs OFF';
      });
    } catch (e) {
      setState(() => _statusMessage = 'LED Error: $e');
    }
  }

  // ==================== Scanner ====================

  Future<void> _startScanner({bool front = false}) async {
    setState(() => _statusMessage = front ? 'Starting Front Scanner...' : 'Starting Back Scanner...');
    try {
      final code = front ? await _arke.startFrontScanner() : await _arke.startScanner();
      setState(() => _statusMessage = 'Scan Result: $code');
    } catch (e) {
      setState(() => _statusMessage = 'Scan Error: $e');
    }
  }

  // ==================== NFC ====================

  Future<void> _startNfcScan() async {
    setState(() => _statusMessage = 'Please tap card...');
    try {
      final uid = await _arke.startNfcScan();
      setState(() => _statusMessage = 'Card UID: $uid');
    } catch (e) {
      setState(() => _statusMessage = 'NFC Error: $e');
    }
  }

  // ==================== Mag Card Reader ====================

  Future<void> _startMagReader() async {
    setState(() => _statusMessage = 'Swipe card now...');
    try {
      final data = await _arke.startMagReader(timeout: 30);
      if (data != null && data.isNotEmpty) {
        final parts = data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        setState(() => _statusMessage = 'Mag Card:\n$parts');
      } else {
        setState(() => _statusMessage = 'No card data');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Mag Reader Error: $e');
    }
  }

  // ==================== VAS ====================

  Future<void> _vasBind() async {
    setState(() => _vasStatus = 'Binding to VAS...');
    try {
      await _arke.vas.bindService();
    } catch (e) {
      setState(() => _vasStatus = 'VAS Bind Error: $e');
    }
  }

  Future<void> _vasSignIn() async {
    setState(() => _vasStatus = 'SignIn to VAS...');
    try {
      await _arke.vas.signIn();
    } catch (e) {
      setState(() => _vasStatus = 'VAS SignIn Error: $e');
    }
  }

  Future<void> _vasSale() async {
    setState(() => _vasStatus = 'Starting Sale to VAS...');
    try {
      await _arke.vas.sale(VasRequestBody(amount: 100.0));
    } catch (e) {
      setState(() => _vasStatus = 'VAS Sale Error: $e');
    }
  }

  Widget _buildVasControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💳 VAS (Value Added Services)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Status: $_vasStatus', style: const TextStyle(fontSize: 12, color: Colors.indigo)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected ? _vasBind : null,
                    child: const Text('Bind Service'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected ? _vasSignIn : null,
                    child: const Text('Sign In'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isConnected ? _vasSale : null,
              icon: const Icon(Icons.payment),
              label: const Text('Test Sale (100.0)'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Build UI ====================

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Arke SDK Tester'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: initPlatformState,
              icon: const Icon(Icons.refresh),
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 12),
              _buildInfoCard(),
              const SizedBox(height: 12),
              _buildBeeperControls(),
              const SizedBox(height: 12),
              _buildPrinterControls(),
              const SizedBox(height: 12),
              _buildLedControls(),
              const SizedBox(height: 12),
              _buildScannerControls(),
              const SizedBox(height: 12),
              _buildNfcControls(),
              const SizedBox(height: 12),
              _buildMagReaderControls(),
              const SizedBox(height: 12),
              _buildVasControls(),
              const SizedBox(height: 16),
              _buildStatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
      child: ListTile(
        leading: Icon(
          _isConnected ? Icons.check_circle : Icons.error,
          color: _isConnected ? Colors.green : Colors.red,
        ),
        title: Text(_isConnected ? 'Device Connected' : 'Device Disconnected'),
        subtitle: Text('Android OS: $_platformVersion'),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Terminal Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(onPressed: _getTerminalInfo, icon: const Icon(Icons.download, size: 20)),
              ],
            ),
            const Divider(),
            _infoRow('Model', _terminalInfo['model'] ?? 'N/A'),
            _infoRow('Serial No', _terminalInfo['serialNo'] ?? 'N/A'),
            _infoRow('ROM', _terminalInfo['romVersion'] ?? 'N/A'),
            _infoRow('Firmware', _terminalInfo['firmwareVersion'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBeeperControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔊 Beeper', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              children: [
                const Text('Duration: '),
                Expanded(
                  child: Slider(
                    value: _beepDuration.toDouble(),
                    min: 100, max: 3000, divisions: 29,
                    label: '${_beepDuration}ms',
                    onChanged: (val) => setState(() => _beepDuration = val.round()),
                  ),
                ),
                Text('${_beepDuration}ms'),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _isConnected ? _beep : null,
              icon: const Icon(Icons.volume_up),
              label: const Text('Play Sound'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🖨️ Printer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _alignOption(0, 'Left'),
                _alignOption(1, 'Center'),
                _alignOption(2, 'Right'),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isConnected ? _printTestReceipt : null,
              icon: const Icon(Icons.receipt_long),
              label: const Text('Print Receipt'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? _printBarcode : null,
                    icon: const Icon(Icons.barcode_reader, size: 18),
                    label: const Text('Barcode'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? _printQrCode : null,
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('QR Code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isConnected ? _getPrinterStatus : null,
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('Check Printer Status'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(36)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alignOption(int value, String label) {
    return Row(
      children: [
        Radio<int>(
          value: value,
          groupValue: _selectedAlign,
          onChanged: (val) => setState(() => _selectedAlign = val!),
          visualDensity: VisualDensity.compact,
        ),
        Text(label),
      ],
    );
  }

  Widget _buildLedControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡 LED', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ledButton('red', Colors.red),
                _ledButton('green', Colors.green),
                _ledButton('yellow', Colors.amber),
                _ledButton('blue', Colors.blue),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected ? _ledAllOn : null,
                    child: const Text('All ON'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isConnected ? _ledAllOff : null,
                    child: const Text('All OFF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ledButton(String color, Color displayColor) {
    final isOn = _ledStates[color] == true;
    return GestureDetector(
      onTap: _isConnected ? () => _toggleLed(color) : null,
      child: Column(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn ? displayColor : displayColor.withOpacity(0.2),
              border: Border.all(color: displayColor, width: 2),
              boxShadow: isOn ? [BoxShadow(color: displayColor.withOpacity(0.5), blurRadius: 10)] : [],
            ),
          ),
          const SizedBox(height: 4),
          Text(color.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: displayColor)),
        ],
      ),
    );
  }

  Widget _buildScannerControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📷 Scanner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? () => _startScanner(front: false) : null,
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Back Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? () => _startScanner(front: true) : null,
                    icon: const Icon(Icons.camera_front, size: 18),
                    label: const Text('Front Camera'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNfcControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📱 NFC / Card Tap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            ElevatedButton.icon(
              onPressed: _isConnected ? _startNfcScan : null,
              icon: const Icon(Icons.tap_and_play),
              label: const Text('Read NFC Card'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMagReaderControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💳 Magnetic Card Reader', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            ElevatedButton.icon(
              onPressed: _isConnected ? _startMagReader : null,
              icon: const Icon(Icons.credit_card),
              label: const Text('Swipe Mag Card'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Text(
        _statusMessage,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
        textAlign: TextAlign.center,
      ),
    );
  }
}
