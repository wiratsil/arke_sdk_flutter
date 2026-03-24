import 'dart:convert';

class VasRequestBody {
  final double? amount;
  final bool? needAppPrinted;
  final String? originalVoucherNumber;
  final String? inputRemarkInfo;
  final String? originalReferenceNumber;
  final String? cardNumber;
  final String? expiryDate;
  final String? authorizationMethod;
  final String? authorizationCode;
  final String? orderNumber;

  VasRequestBody({
    this.amount,
    this.needAppPrinted,
    this.originalVoucherNumber,
    this.inputRemarkInfo,
    this.originalReferenceNumber,
    this.cardNumber,
    this.expiryDate,
    this.authorizationMethod,
    this.authorizationCode,
    this.orderNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      if (amount != null) 'amount': amount,
      if (needAppPrinted != null) 'needAppPrinted': needAppPrinted,
      if (originalVoucherNumber != null) 'originalVoucherNumber': originalVoucherNumber,
      if (inputRemarkInfo != null) 'inputRemarkInfo': inputRemarkInfo,
      if (originalReferenceNumber != null) 'originalReferenceNumber': originalReferenceNumber,
      if (cardNumber != null) 'cardNumber': cardNumber,
      if (expiryDate != null) 'expiryDate': expiryDate,
      if (authorizationMethod != null) 'authorizationMethod': authorizationMethod,
      if (authorizationCode != null) 'authorizationCode': authorizationCode,
      if (orderNumber != null) 'orderNumber': orderNumber,
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

class VasEvent {
  final String type; // 'onStart', 'onNext', 'onComplete'
  final Map<String, dynamic>? data;

  VasEvent({required this.type, this.data});

  factory VasEvent.fromMap(Map<dynamic, dynamic> map) {
    Map<String, dynamic>? parsedData;
    if (map['data'] != null) {
      try {
        parsedData = jsonDecode(map['data'] as String);
      } catch (e) {
        // ignore
      }
    }
    return VasEvent(
      type: map['event'] as String,
      data: parsedData,
    );
  }
}
