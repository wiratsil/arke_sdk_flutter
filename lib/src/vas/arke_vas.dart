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

  /// Scan available services in com.arke.vas package for debugging
  Future<String> scanVasServices() async {
    try {
      final String result = await _channel.invokeMethod('vasScanServices');
      return result;
    } catch (e) {
      return "Error scanning: $e";
    }
  }

  // ==================== PHASE 2: Core Transactions ====================

  /// Refund
  Future<void> refund(VasRequestBody payload) async {
    await _channel.invokeMethod('vasRefund', {'payloadBody': payload.toJsonString()});
  }

  /// Balance
  Future<void> balance() async {
    await _channel.invokeMethod('vasBalance');
  }

  /// eCash Balance Query
  Future<void> ecashBalanceQuery() async {
    await _channel.invokeMethod('vasEcashBalanceQuery');
  }

  /// Offline Transaction
  Future<void> offline(VasRequestBody payload) async {
    await _channel.invokeMethod('vasOffline', {'payloadBody': payload.toJsonString()});
  }

  /// Offline Settlement
  Future<void> offlineSettlement(VasRequestBody payload) async {
    await _channel.invokeMethod('vasOfflineSettlement', {'payloadBody': payload.toJsonString()});
  }

  // ==================== PHASE 2: Pre-Authorization ====================

  /// Pre-Authorization (จองวงเงิน)
  Future<void> preAuthorization(VasRequestBody payload) async {
    await _channel.invokeMethod('vasPreAuthorization', {'payloadBody': payload.toJsonString()});
  }

  /// Pre-Authorization Void (ยกเลิกจองวงเงิน)
  Future<void> preAuthorizationVoid(VasRequestBody payload) async {
    await _channel.invokeMethod('vasPreAuthorizationVoid', {'payloadBody': payload.toJsonString()});
  }

  /// Pre-Authorization Completion Request (ยืนยันหักเงินจอง)
  Future<void> preAuthorizationCompletionRequest(VasRequestBody payload) async {
    await _channel.invokeMethod('vasPreAuthorizationCompletionRequest', {'payloadBody': payload.toJsonString()});
  }

  /// Pre-Authorization Completion Advice
  Future<void> preAuthorizationCompletionAdvice(VasRequestBody payload) async {
    await _channel.invokeMethod('vasPreAuthorizationCompletionAdvice', {'payloadBody': payload.toJsonString()});
  }

  /// Pre-Authorization Completion Void (ยกเลิกการหักเงินจากการจอง)
  Future<void> preAuthorizationCompletionVoid(VasRequestBody payload) async {
    await _channel.invokeMethod('vasPreAuthorizationCompletionVoid', {'payloadBody': payload.toJsonString()});
  }

  // ==================== PHASE 2: Adjustments ====================

  /// Settlement Adjustment (ปรับปรุงยอด)
  Future<void> settlementAdjustment(VasRequestBody payload) async {
    await _channel.invokeMethod('vasSettlementAdjustment', {'payloadBody': payload.toJsonString()});
  }

  /// Adjust Tips (เพิ่มทิป)
  Future<void> adjustTips(VasRequestBody payload) async {
    await _channel.invokeMethod('vasAdjustTips', {'payloadBody': payload.toJsonString()});
  }
}
