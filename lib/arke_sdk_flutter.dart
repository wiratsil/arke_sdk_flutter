
import 'dart:typed_data';
import 'arke_sdk_flutter_platform_interface.dart';

class ArkeSdkFlutter {
  // ==================== System ====================

  Future<String?> getPlatformVersion() {
    return ArkeSdkFlutterPlatform.instance.getPlatformVersion();
  }

  Future<Map<String, String>?> getTerminalInfo() {
    return ArkeSdkFlutterPlatform.instance.getTerminalInfo();
  }

  Future<void> rebootDevice() {
    return ArkeSdkFlutterPlatform.instance.rebootDevice();
  }

  Future<void> updateSystemTime(String time) {
    return ArkeSdkFlutterPlatform.instance.updateSystemTime(time);
  }

  // ==================== Beeper ====================

  Future<void> beep({int milliseconds = 500}) {
    return ArkeSdkFlutterPlatform.instance.beep(milliseconds: milliseconds);
  }

  // ==================== Printer ====================

  Future<void> printText(String text, {int align = 0}) {
    return ArkeSdkFlutterPlatform.instance.printText(text, align: align);
  }

  Future<void> printBarcode(String barcode, {int align = 1, int codeWidth = 2, int codeHeight = -1}) {
    return ArkeSdkFlutterPlatform.instance.printBarcode(barcode, align: align, codeWidth: codeWidth, codeHeight: codeHeight);
  }

  Future<void> printQrCode(String qrCode, {int align = 1, int imageHeight = 240, int ecLevel = 3}) {
    return ArkeSdkFlutterPlatform.instance.printQrCode(qrCode, align: align, imageHeight: imageHeight, ecLevel: ecLevel);
  }

  Future<void> printImage(Uint8List imageBytes, {int align = 1}) {
    return ArkeSdkFlutterPlatform.instance.printImage(imageBytes, align: align);
  }

  Future<void> setPrinterGray(int gray) {
    return ArkeSdkFlutterPlatform.instance.setPrinterGray(gray);
  }

  Future<String> getPrinterStatus() {
    return ArkeSdkFlutterPlatform.instance.getPrinterStatus();
  }

  Future<void> feedPaper(int lines) {
    return ArkeSdkFlutterPlatform.instance.feedPaper(lines);
  }

  // ==================== LED ====================

  Future<void> ledTurnOn(List<String> lights) {
    return ArkeSdkFlutterPlatform.instance.ledTurnOn(lights);
  }

  Future<void> ledTurnOff(List<String> lights) {
    return ArkeSdkFlutterPlatform.instance.ledTurnOff(lights);
  }

  Future<void> ledTurnOnAll() {
    return ArkeSdkFlutterPlatform.instance.ledTurnOnAll();
  }

  Future<void> ledTurnOffAll() {
    return ArkeSdkFlutterPlatform.instance.ledTurnOffAll();
  }

  // ==================== Scanner ====================

  Future<String?> startScanner() {
    return ArkeSdkFlutterPlatform.instance.startScanner();
  }

  Future<String?> startFrontScanner() {
    return ArkeSdkFlutterPlatform.instance.startFrontScanner();
  }

  Future<void> stopScanner() {
    return ArkeSdkFlutterPlatform.instance.stopScanner();
  }

  Future<void> stopFrontScanner() {
    return ArkeSdkFlutterPlatform.instance.stopFrontScanner();
  }

  // ==================== NFC ====================

  Future<String?> startNfcScan() {
    return ArkeSdkFlutterPlatform.instance.startNfcScan();
  }

  // ==================== Magnetic Card Reader ====================

  Future<Map<String, String>?> startMagReader({int timeout = 30}) {
    return ArkeSdkFlutterPlatform.instance.startMagReader(timeout: timeout);
  }

  Future<void> stopMagReader() {
    return ArkeSdkFlutterPlatform.instance.stopMagReader();
  }

  // ==================== Serial Port ====================

  Future<void> serialOpen(String deviceName) {
    return ArkeSdkFlutterPlatform.instance.serialOpen(deviceName);
  }

  Future<void> serialInit({required int baudRate, int parityBit = 0, int dataBit = 8}) {
    return ArkeSdkFlutterPlatform.instance.serialInit(baudRate: baudRate, parityBit: parityBit, dataBit: dataBit);
  }

  Future<void> serialWrite(Uint8List data, {int timeout = 5000}) {
    return ArkeSdkFlutterPlatform.instance.serialWrite(data, timeout: timeout);
  }

  Future<Uint8List?> serialRead({required int length, int timeout = 5000}) {
    return ArkeSdkFlutterPlatform.instance.serialRead(length: length, timeout: timeout);
  }

  Future<void> serialClose() {
    return ArkeSdkFlutterPlatform.instance.serialClose();
  }
}

