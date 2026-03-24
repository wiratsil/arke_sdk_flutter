import 'dart:async';
import 'package:flutter/services.dart';
import 'vas_payload.dart';

export 'vas_payload.dart';

class ArkeVas {
  final MethodChannel _channel;
  final EventChannel _eventChannel = const EventChannel('arke_sdk_flutter/vas_events');
  Stream<VasEvent>? _vasEventStream;

  ArkeVas(this._channel);

  /// Get the stream of VAS transaction events
  Stream<VasEvent> get vasEvents {
    _vasEventStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      return VasEvent.fromMap(event as Map);
    });
    return _vasEventStream!;
  }

  /// Bind to the Arke VAS Service
  Future<void> bindService({String? action, String? packageName}) async {
    await _channel.invokeMethod('vasBindService', {
      'action': action,
      'packageName': packageName,
    });
  }

  /// Unbind from the Arke VAS Service
  Future<void> unbindService() async {
    await _channel.invokeMethod('vasUnbindService');
  }

  /// Sign In
  Future<void> signIn() async {
    await _channel.invokeMethod('vasSignIn');
  }

  /// Sale / Consume
  Future<void> sale(VasRequestBody payload) async {
    await _channel.invokeMethod('vasSale', {'payloadBody': payload.toJsonString()});
  }

  /// Void
  Future<void> voided(VasRequestBody payload) async {
    await _channel.invokeMethod('vasVoided', {'payloadBody': payload.toJsonString()});
  }

  /// Settle
  Future<void> settle() async {
    await _channel.invokeMethod('vasSettle');
  }

  /// Query order
  Future<void> orderNumberQuery(VasRequestBody payload) async {
    await _channel.invokeMethod('vasOrderNumberQuery', {'payloadBody': payload.toJsonString()});
  }

  /// Print Transaction Summary
  Future<void> printTransactionSummary() async {
    await _channel.invokeMethod('vasPrintTransactionSummary');
  }

  /// Print Transaction Detail
  Future<void> printTransactionDetail() async {
    await _channel.invokeMethod('vasPrintTransactionDetail');
  }

  /// Terminal Key Management
  Future<void> terminalKeyManagement() async {
    await _channel.invokeMethod('vasTerminalKeyManagement');
  }
}
