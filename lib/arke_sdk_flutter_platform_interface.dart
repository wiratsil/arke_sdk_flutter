import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'arke_sdk_flutter_method_channel.dart';

abstract class ArkeSdkFlutterPlatform extends PlatformInterface {
  /// Constructs a ArkeSdkFlutterPlatform.
  ArkeSdkFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static ArkeSdkFlutterPlatform _instance = MethodChannelArkeSdkFlutter();

  /// The default instance of [ArkeSdkFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelArkeSdkFlutter].
  static ArkeSdkFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ArkeSdkFlutterPlatform] when
  /// they register themselves.
  static set instance(ArkeSdkFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // ==================== System ====================

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<Map<String, String>?> getTerminalInfo() {
    throw UnimplementedError('getTerminalInfo() has not been implemented.');
  }

  Future<void> rebootDevice() {
    throw UnimplementedError('rebootDevice() has not been implemented.');
  }

  Future<void> updateSystemTime(String time) {
    throw UnimplementedError('updateSystemTime() has not been implemented.');
  }

  // ==================== Beeper ====================

  Future<void> beep({int milliseconds = 500}) {
    throw UnimplementedError('beep() has not been implemented.');
  }

  // ==================== Printer ====================

  Future<void> printText(String text, {int align = 0}) {
    throw UnimplementedError('printText() has not been implemented.');
  }

  Future<void> printBarcode(String barcode, {int align = 1, int codeWidth = 2, int codeHeight = -1}) {
    throw UnimplementedError('printBarcode() has not been implemented.');
  }

  Future<void> printQrCode(String qrCode, {int align = 1, int imageHeight = 240, int ecLevel = 3}) {
    throw UnimplementedError('printQrCode() has not been implemented.');
  }

  Future<void> printImage(Uint8List imageBytes, {int align = 1}) {
    throw UnimplementedError('printImage() has not been implemented.');
  }

  Future<void> setPrinterGray(int gray) {
    throw UnimplementedError('setPrinterGray() has not been implemented.');
  }

  Future<String> getPrinterStatus() {
    throw UnimplementedError('getPrinterStatus() has not been implemented.');
  }

  Future<void> feedPaper(int lines) {
    throw UnimplementedError('feedPaper() has not been implemented.');
  }

  // ==================== LED ====================

  Future<void> ledTurnOn(List<String> lights) {
    throw UnimplementedError('ledTurnOn() has not been implemented.');
  }

  Future<void> ledTurnOff(List<String> lights) {
    throw UnimplementedError('ledTurnOff() has not been implemented.');
  }

  Future<void> ledTurnOnAll() {
    throw UnimplementedError('ledTurnOnAll() has not been implemented.');
  }

  Future<void> ledTurnOffAll() {
    throw UnimplementedError('ledTurnOffAll() has not been implemented.');
  }

  // ==================== Scanner ====================

  Future<String?> startScanner() {
    throw UnimplementedError('startScanner() has not been implemented.');
  }

  Future<String?> startFrontScanner() {
    throw UnimplementedError('startFrontScanner() has not been implemented.');
  }

  Future<void> stopScanner() {
    throw UnimplementedError('stopScanner() has not been implemented.');
  }

  Future<void> stopFrontScanner() {
    throw UnimplementedError('stopFrontScanner() has not been implemented.');
  }

  // ==================== NFC ====================

  Future<String?> startNfcScan() {
    throw UnimplementedError('startNfcScan() has not been implemented.');
  }

  // ==================== Magnetic Card Reader ====================

  Future<Map<String, String>?> startMagReader({int timeout = 30}) {
    throw UnimplementedError('startMagReader() has not been implemented.');
  }

  Future<void> stopMagReader() {
    throw UnimplementedError('stopMagReader() has not been implemented.');
  }

  // ==================== Serial Port ====================

  Future<void> serialOpen(String deviceName) {
    throw UnimplementedError('serialOpen() has not been implemented.');
  }

  Future<void> serialInit({required int baudRate, int parityBit = 0, int dataBit = 8}) {
    throw UnimplementedError('serialInit() has not been implemented.');
  }

  Future<void> serialWrite(Uint8List data, {int timeout = 5000}) {
    throw UnimplementedError('serialWrite() has not been implemented.');
  }

  Future<Uint8List?> serialRead({required int length, int timeout = 5000}) {
    throw UnimplementedError('serialRead() has not been implemented.');
  }

  Future<void> serialClose() {
    throw UnimplementedError('serialClose() has not been implemented.');
  }
}
