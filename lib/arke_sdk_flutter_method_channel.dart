import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'arke_sdk_flutter_platform_interface.dart';

/// An implementation of [ArkeSdkFlutterPlatform] that uses method channels.
class MethodChannelArkeSdkFlutter extends ArkeSdkFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('arke_sdk_flutter');

  // ==================== System ====================

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<Map<String, String>?> getTerminalInfo() async {
    final info = await methodChannel.invokeMapMethod<String, String>('getTerminalInfo');
    return info;
  }

  @override
  Future<void> rebootDevice() async {
    await methodChannel.invokeMethod<void>('rebootDevice');
  }

  @override
  Future<void> updateSystemTime(String time) async {
    await methodChannel.invokeMethod<void>('updateSystemTime', {'time': time});
  }

  // ==================== Beeper ====================

  @override
  Future<void> beep({int milliseconds = 500}) async {
    await methodChannel.invokeMethod<void>('beep', {'milliseconds': milliseconds});
  }

  // ==================== Printer ====================

  @override
  Future<void> printText(String text, {int align = 0}) async {
    await methodChannel.invokeMethod<void>('printText', {'text': text, 'align': align});
  }

  @override
  Future<void> printBarcode(String barcode, {int align = 1, int codeWidth = 2, int codeHeight = -1}) async {
    await methodChannel.invokeMethod<void>('printBarcode', {
      'barcode': barcode,
      'align': align,
      'codeWidth': codeWidth,
      'codeHeight': codeHeight,
    });
  }

  @override
  Future<void> printQrCode(String qrCode, {int align = 1, int imageHeight = 240, int ecLevel = 3}) async {
    await methodChannel.invokeMethod<void>('printQrCode', {
      'qrCode': qrCode,
      'align': align,
      'imageHeight': imageHeight,
      'ecLevel': ecLevel,
    });
  }

  @override
  Future<void> printImage(Uint8List imageBytes, {int align = 1}) async {
    await methodChannel.invokeMethod<void>('printImage', {
      'imageBytes': imageBytes,
      'align': align,
    });
  }

  @override
  Future<void> setPrinterGray(int gray) async {
    await methodChannel.invokeMethod<void>('setPrinterGray', {'gray': gray});
  }

  @override
  Future<String> getPrinterStatus() async {
    final status = await methodChannel.invokeMethod<String>('getPrinterStatus');
    return status ?? 'Unknown';
  }

  @override
  Future<void> feedPaper(int lines) async {
    await methodChannel.invokeMethod<void>('feedPaper', {'lines': lines});
  }

  // ==================== LED ====================

  @override
  Future<void> ledTurnOn(List<String> lights) async {
    await methodChannel.invokeMethod<void>('ledTurnOn', {'lights': lights});
  }

  @override
  Future<void> ledTurnOff(List<String> lights) async {
    await methodChannel.invokeMethod<void>('ledTurnOff', {'lights': lights});
  }

  @override
  Future<void> ledTurnOnAll() async {
    await methodChannel.invokeMethod<void>('ledTurnOnAll');
  }

  @override
  Future<void> ledTurnOffAll() async {
    await methodChannel.invokeMethod<void>('ledTurnOffAll');
  }

  // ==================== Scanner ====================

  @override
  Future<String?> startScanner() async {
    final result = await methodChannel.invokeMethod<String>('startScanner');
    return result;
  }

  @override
  Future<String?> startFrontScanner() async {
    final result = await methodChannel.invokeMethod<String>('startFrontScanner');
    return result;
  }

  @override
  Future<void> stopScanner() async {
    await methodChannel.invokeMethod<void>('stopScanner');
  }

  @override
  Future<void> stopFrontScanner() async {
    await methodChannel.invokeMethod<void>('stopFrontScanner');
  }

  // ==================== NFC ====================

  @override
  Future<String?> startNfcScan() async {
    final result = await methodChannel.invokeMethod<String>('startNfcScan');
    return result;
  }

  // ==================== Magnetic Card Reader ====================

  @override
  Future<Map<String, String>?> startMagReader({int timeout = 30}) async {
    final result = await methodChannel.invokeMapMethod<String, String>('startMagReader', {'timeout': timeout});
    return result;
  }

  @override
  Future<void> stopMagReader() async {
    await methodChannel.invokeMethod<void>('stopMagReader');
  }

  // ==================== Serial Port ====================

  @override
  Future<void> serialOpen(String deviceName) async {
    await methodChannel.invokeMethod<void>('serialOpen', {'deviceName': deviceName});
  }

  @override
  Future<void> serialInit({required int baudRate, int parityBit = 0, int dataBit = 8}) async {
    await methodChannel.invokeMethod<void>('serialInit', {
      'baudRate': baudRate,
      'parityBit': parityBit,
      'dataBit': dataBit,
    });
  }

  @override
  Future<void> serialWrite(Uint8List data, {int timeout = 5000}) async {
    await methodChannel.invokeMethod<void>('serialWrite', {
      'data': data,
      'timeout': timeout,
    });
  }

  @override
  Future<Uint8List?> serialRead({required int length, int timeout = 5000}) async {
    final result = await methodChannel.invokeMethod<Uint8List>('serialRead', {
      'length': length,
      'timeout': timeout,
    });
    return result;
  }

  @override
  Future<void> serialClose() async {
    await methodChannel.invokeMethod<void>('serialClose');
  }
}
