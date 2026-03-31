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
  final String? transType;
  final String? transName;
  final String? originalTransactionDate;
  final String? originalAuthorizationCode;
  final String? interfaceId;

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
    this.transType,
    this.transName,
    this.originalTransactionDate,
    this.originalAuthorizationCode,
    this.interfaceId,
  });

  Map<String, dynamic> toJson() {
    final tipQualifier = (interfaceId ?? transType ?? transName)?.toUpperCase();

    return {
      if (amount != null) ...{
        'amount': amount,
        if (tipQualifier == 'ADJUST' || tipQualifier == 'TIP')
          'tipAmount': amount,
      },
      if (needAppPrinted != null) 'needAppPrinted': needAppPrinted,
      if (inputRemarkInfo != null) 'inputRemarkInfo': inputRemarkInfo,
      if (cardNumber != null) 'cardNumber': cardNumber,
      if (expiryDate != null) 'expiryDate': expiryDate,
      if (authorizationMethod != null)
        'authorizationMethod': authorizationMethod,
      if (authorizationCode != null) 'authorizationCode': authorizationCode,
      if (orderNumber != null) 'orderNumber': orderNumber,
      if (transType != null) 'transType': transType,
      if (transName != null) 'transName': transName,

      // --- Shotgun Mapping: Send multiple key variations for Arke compatibility ---

      // Voucher Number variations
      if (originalVoucherNumber != null) ...{
        'originalVoucherNumber': originalVoucherNumber,
        'voucherNo': originalVoucherNumber,
        'voucherNumber': originalVoucherNumber,
        'origVoucherNo': originalVoucherNumber,
        'origVoucherNumber': originalVoucherNumber,
      },

      // Reference Number variations
      if (originalReferenceNumber != null) ...{
        'originalReferenceNumber': originalReferenceNumber,
        'refNo': originalReferenceNumber,
        'referenceNo': originalReferenceNumber,
        'origRefNo': originalReferenceNumber,
        'origReferenceNo': originalReferenceNumber,
      },

      // Authorization Code variations
      if (originalAuthorizationCode != null) ...{
        'authCode': originalAuthorizationCode,
        'origAuthCode': originalAuthorizationCode,
        'originalAuthorizationCode': originalAuthorizationCode,
      },

      // Transaction Date variations
      if (originalTransactionDate != null) ...{
        'transactionDate': originalTransactionDate,
        'transDate': originalTransactionDate,
        'origTransDate': originalTransactionDate,
        'originalTransactionDate': originalTransactionDate,
      },
      if (interfaceId != null) 'interfaceId': interfaceId,
    };
  }

  Map<String, dynamic> toAdjustTipsJson() {
    return {
      if (amount != null) 'amount': amount,
      if (needAppPrinted != null) 'needAppPrinted': needAppPrinted,
      if (originalVoucherNumber != null)
        'originalVoucherNumber': originalVoucherNumber,
      if (inputRemarkInfo != null) 'inputRemarkInfo': inputRemarkInfo,
      if (originalReferenceNumber != null)
        'originalReferenceNumber': originalReferenceNumber,
      if (cardNumber != null) 'cardNumber': cardNumber,
      if (expiryDate != null) 'expiryDate': expiryDate,
      if (authorizationMethod != null)
        'authorizationMethod': authorizationMethod,
      if (authorizationCode != null) 'authorizationCode': authorizationCode,
      if (orderNumber != null) 'orderNumber': orderNumber,
      if (originalAuthorizationCode != null)
        'originalAuthorizationCode': originalAuthorizationCode,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  String toAdjustTipsJsonString() => jsonEncode(toAdjustTipsJson());
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
