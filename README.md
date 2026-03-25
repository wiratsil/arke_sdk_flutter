# Arke SDK Flutter Plugin

Flutter plugin สำหรับ Arke/Landi USDK — ใช้เข้าถึง hardware ของเครื่อง POS Terminal จาก Flutter app

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  arke_sdk_flutter:
    git:
      url: https://github.com/wiratsil/arke-sdk-flutter.git
      path: arke-sdk-flutter/arke_sdk_flutter
```

## Requirements

- **Android only** (POS Terminal devices)
- Android SDK API level 19+
- USDK Service (`com.usdk.apiservice`) must be installed on the device
- Dart SDK `>=3.3.0 <5.0.0`

## Quick Start

```dart
import 'package:arke_sdk_flutter/arke_sdk_flutter.dart';

final arke = ArkeSdkFlutter();

// Check connection
final version = await arke.getPlatformVersion();
print('Running on: $version');
```

---

## API Reference

### System

#### `getPlatformVersion()`
Returns the Android version string.

```dart
final version = await arke.getPlatformVersion();
// "Android 5.1.1"
```

#### `getTerminalInfo()`
Returns a map of device information.

```dart
final info = await arke.getTerminalInfo();
print(info?['model']);        // "AECR C10"
print(info?['serialNo']);     // "1234567890"
print(info?['osVersion']);    // "5.1.1"
print(info?['romVersion']);
print(info?['firmwareVersion']);
print(info?['hardwareVersion']);
```

#### `rebootDevice()`
Reboots the POS terminal.

```dart
await arke.rebootDevice();
```

#### `updateSystemTime(String time)`
Updates the system time. Format: `yyyyMMddHHmmss`

```dart
await arke.updateSystemTime('20260320120000');
```

---

### Beeper

#### `beep({int milliseconds = 500})`
Plays a beep sound for the specified duration.

```dart
await arke.beep(milliseconds: 1000);  // beep for 1 second
```

---

### Printer

#### `printText(String text, {int align = 0})`
Prints text. Alignment: `0` = Left, `1` = Center, `2` = Right.

```dart
await arke.printText('Hello World!', align: 1);  // center
```

#### `printBarcode(String barcode, {int align, int codeWidth, int codeHeight})`
Prints a barcode.

```dart
await arke.printBarcode(
  '1234567890',
  align: 1,        // Center
  codeWidth: 2,    // Bar width
  codeHeight: -1,  // Auto height
);
```

#### `printQrCode(String qrCode, {int align, int imageHeight, int ecLevel})`
Prints a QR code. EC levels: `0`=L, `1`=M, `2`=Q, `3`=H.

```dart
await arke.printQrCode(
  'https://example.com',
  align: 1,           // Center
  imageHeight: 240,   // QR size in pixels
  ecLevel: 3,         // High error correction
);
```

#### `printImage(Uint8List imageBytes, {int align = 1})`
Prints a bitmap image from raw bytes.

```dart
import 'dart:typed_data';

final bytes = await loadImageBytes();  // your image data
await arke.printImage(bytes, align: 1);
```

#### `setPrinterGray(int gray)`
Sets print darkness/gray level (0–10).

```dart
await arke.setPrinterGray(6);
```

#### `getPrinterStatus()`
Returns printer status. Returns `"OK"` if ready.

```dart
final status = await arke.getPrinterStatus();
if (status == 'OK') {
  // Printer ready
}
```

#### `feedPaper(int lines)`
Feeds paper by the specified number of lines.

```dart
await arke.feedPaper(3);
```

#### Full Printer Example

```dart
await arke.setPrinterGray(6);
await arke.printText('--- RECEIPT ---', align: 1);
await arke.printText('Item: Coffee', align: 0);
await arke.printText('Price: 50.00 THB', align: 0);
await arke.printBarcode('1234567890');
await arke.printQrCode('https://pay.example.com/txn/123');
await arke.feedPaper(5);
```

---

### LED

#### `ledTurnOn(List<String> lights)`
Turns on specified LEDs. Colors: `"red"`, `"green"`, `"yellow"`, `"blue"`.

```dart
await arke.ledTurnOn(['red', 'green']);
```

#### `ledTurnOff(List<String> lights)`
Turns off specified LEDs.

```dart
await arke.ledTurnOff(['red']);
```

#### `ledTurnOnAll()`
Turns on all LEDs.

```dart
await arke.ledTurnOnAll();
```

#### `ledTurnOffAll()`
Turns off all LEDs.

```dart
await arke.ledTurnOffAll();
```

---

### Scanner (Barcode/QR)

#### `startScanner()`
Starts the back camera scanner (30s timeout). Returns the scanned code.

```dart
try {
  final code = await arke.startScanner();
  print('Scanned: $code');
} on PlatformException catch (e) {
  if (e.code == 'SCANNER_TIMEOUT') print('Timed out');
}
```

#### `startFrontScanner()`
Starts the front camera scanner (30s timeout).

```dart
final code = await arke.startFrontScanner();
```

#### `stopScanner()`
Stops the back camera scanner.

```dart
await arke.stopScanner();
```

#### `stopFrontScanner()`
Stops the front camera scanner.

```dart
await arke.stopFrontScanner();
```

---

### NFC / Contactless Card

#### `startNfcScan()`
Waits for an NFC card tap and returns the card UID as hex string.

```dart
try {
  final uid = await arke.startNfcScan();
  print('Card UID: $uid');  // "A1B2C3D4"
} on PlatformException catch (e) {
  print('NFC Error: ${e.message}');
}
```

---

### Magnetic Card Reader

#### `startMagReader({int timeout = 30})`
Waits for a magnetic card swipe. Returns track data.

```dart
try {
  final data = await arke.startMagReader(timeout: 30);
  print('PAN: ${data?['pan']}');
  print('Track 1: ${data?['track1']}');
  print('Track 2: ${data?['track2']}');
  print('Track 3: ${data?['track3']}');
  print('Service Code: ${data?['serviceCode']}');
  print('Expired Date: ${data?['expiredDate']}');
} on PlatformException catch (e) {
  if (e.code == 'MAG_READER_TIMEOUT') print('Timed out');
}
```

#### `stopMagReader()`
Stops the magnetic card reader.

```dart
await arke.stopMagReader();
```

---

### Serial Port

#### `serialOpen(String deviceName)`
Opens a serial port.

```dart
await arke.serialOpen('/dev/ttyS1');
```

#### `serialInit({required int baudRate, int parityBit = 0, int dataBit = 8})`
Initializes the serial port configuration.

```dart
await arke.serialInit(baudRate: 9600, parityBit: 0, dataBit: 8);
```

#### `serialWrite(Uint8List data, {int timeout = 5000})`
Writes data to serial port.

```dart
import 'dart:typed_data';

final data = Uint8List.fromList([0x01, 0x02, 0x03]);
await arke.serialWrite(data, timeout: 3000);
```

#### `serialRead({required int length, int timeout = 5000})`
Reads data from serial port.

```dart
final response = await arke.serialRead(length: 256, timeout: 5000);
if (response != null) {
  print('Received ${response.length} bytes');
}
```

#### `serialClose()`
Closes the serial port.

```dart
await arke.serialClose();
```

#### Full Serial Port Example

```dart
await arke.serialOpen('/dev/ttyS1');
await arke.serialInit(baudRate: 115200);
await arke.serialWrite(Uint8List.fromList([0x01, 0x02]));
final response = await arke.serialRead(length: 64, timeout: 3000);
await arke.serialClose();
```

---

---

### VAS (Value Added Services / Payment)

The Arke SDK allows you to directly interact with the device's main payment application using the VAS API.

#### Bind to VAS Service
You must bind to the native service before calling any transaction methods.

```dart
// Connects to the Arke payment service ('com.arke')
await arke.vas.bindService();
```

#### Listen to Transaction Events
All transaction processes (like Sale, Settle, etc.) return their results asynchronously through a stream.

```dart
arke.vas.vasEvents.listen((event) {
  print('Event Type: ${event.type}'); // "onStart", "onNext", "onComplete"
  print('Payload Data: ${event.data}'); // JSON string from the payment app
});
```

#### `signIn()`
Initiates a handshake with the payment host (Bank/Server).

```dart
await arke.vas.signIn();
```

#### `sale(VasRequestBody request)`
Initiates a payment sale transaction for a specific amount. The payment app will handle the card reading PIN prompt.

```dart
final request = VasRequestBody(amount: 100.0);
await arke.vas.sale(request);
```

#### `settle()`
Performs the end-of-day settlement batch process, concluding all transactions made that day.

```dart
await arke.vas.settle();
```

#### Advanced Transactions
The plugin supports all 35 extended transaction features via the core `com.arke` VAS service, including:

**Core Transactions:**
- `balance()`: Query card balance
- `refund(VasRequestBody request)`: Refund a successful transaction
- `offline(VasRequestBody request)`: Perform an offline transaction
- `offlineSettlement(VasRequestBody request)`: Settle offline records
- `ecashBalanceQuery()`: Query e-Cash balance

**Pre-Authorization:**
- `preAuthorization(VasRequestBody request)`: Reserve card funds
- `preAuthorizationVoid(VasRequestBody request)`: Void a reservation
- `preAuthorizationCompletionRequest(VasRequestBody request)`: Finalize authorization
- `preAuthorizationCompletionAdvice(VasRequestBody request)`
- `preAuthorizationCompletionVoid(VasRequestBody request)`

**Adjustments:**
- `settlementAdjustment(VasRequestBody request)`: Adjust settlement details
- `adjustTips(VasRequestBody request)`: Adjust tips on a previous order

*Example Usage:*
```dart
// Check Balance
await arke.vas.balance();

// Refund 100 THB
await arke.vas.refund(VasRequestBody(amount: 100.0));
```

---

## Error Handling

All methods throw `PlatformException` on failure. Common error codes:

| Error Code | Description |
|-----------|-------------|
| `SDK_NOT_CONNECTED` | USDK service not bound or not installed |
| `SDK_ERROR` | General SDK error |
| `PRINTER_ERROR` | Printer hardware error (paper, overheat, etc.) |
| `SCANNER_ERROR` | Scanner hardware error |
| `SCANNER_TIMEOUT` | Scanner timed out |
| `SCANNER_CANCELLED` | Scanner was cancelled |
| `NFC_ERROR` | NFC reader error |
| `NFC_ACTIVATION_ERROR` | NFC card activation failed |
| `MAG_READER_ERROR` | Magnetic card reader error |
| `MAG_READER_TIMEOUT` | Magnetic card reader timed out |
| `SERIAL_ERROR` | Serial port error |

```dart
try {
  await arke.printText('Test');
} on PlatformException catch (e) {
  switch (e.code) {
    case 'SDK_NOT_CONNECTED':
      print('SDK not ready');
      break;
    case 'PRINTER_ERROR':
      print('Printer error: ${e.message}');
      break;
  }
}
```

---

## Features Summary

| Feature | Methods | Status |
|---------|---------|--------|
| **System** | `getPlatformVersion`, `getTerminalInfo`, `rebootDevice`, `updateSystemTime` | ✅ |
| **Beeper** | `beep` | ✅ |
| **Printer** | `printText`, `printBarcode`, `printQrCode`, `printImage`, `setPrinterGray`, `getPrinterStatus`, `feedPaper` | ✅ |
| **LED** | `ledTurnOn`, `ledTurnOff`, `ledTurnOnAll`, `ledTurnOffAll` | ✅ |
| **Scanner** | `startScanner`, `startFrontScanner`, `stopScanner`, `stopFrontScanner` | ✅ |
| **NFC** | `startNfcScan` | ✅ |
| **Mag Card** | `startMagReader`, `stopMagReader` | ✅ |
| **Serial Port** | `serialOpen`, `serialInit`, `serialWrite`, `serialRead`, `serialClose` | ✅ |
| **VAS Core** | `bindService`, `signIn`, `sale`, `settle`, `voided`, `vasEvents` | ✅ |
| **VAS Advanced** | `refund`, `balance`, `preAuthorization`, `adjustTips`, `offline`, etc. | ✅ |
