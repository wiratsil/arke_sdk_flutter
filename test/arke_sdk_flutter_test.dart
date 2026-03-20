import 'package:flutter_test/flutter_test.dart';
import 'package:arke_sdk_flutter/arke_sdk_flutter.dart';
import 'package:arke_sdk_flutter/arke_sdk_flutter_platform_interface.dart';
import 'package:arke_sdk_flutter/arke_sdk_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockArkeSdkFlutterPlatform
    with MockPlatformInterfaceMixin
    implements ArkeSdkFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> beep({int milliseconds = 500}) => Future.value();

  @override
  Future<void> printText(String text, {int align = 0}) => Future.value();

  @override
  Future<Map<String, String>?> getTerminalInfo() => Future.value({'model': 'Mock Device'});

  @override
  Future<String?> startScanner() => Future.value('mock_scan_code');

  @override
  Future<String?> startNfcScan() => Future.value('mock_nfc_uid');
}

void main() {
  final ArkeSdkFlutterPlatform initialPlatform = ArkeSdkFlutterPlatform.instance;

  test('$MethodChannelArkeSdkFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelArkeSdkFlutter>());
  });

  test('getPlatformVersion', () async {
    ArkeSdkFlutter arkeSdkFlutterPlugin = ArkeSdkFlutter();
    MockArkeSdkFlutterPlatform fakePlatform = MockArkeSdkFlutterPlatform();
    ArkeSdkFlutterPlatform.instance = fakePlatform;

    expect(await arkeSdkFlutterPlugin.getPlatformVersion(), '42');
  });
}
