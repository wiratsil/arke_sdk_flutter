package com.arke.vas.data;

public class ResponseBodyData extends BodyData {
    private String interfaceId;
    private int responseCode = 0;
    private String responseMessage;
    private String transactionType;
    private String packageName;
    private String responseCodeThirtyNine;
    private String responseMessageThirtyNine;
    private Double amount;
    private String merchantName;
    private String merchantNumber;
    private String terminalNumber;
    private String operatorNumber;
    private String cardNumber;
    private String expirationDate;
    private String batchNumber;
    private String voucherNumber;
    private String referenceNumber;
    private String authCode;
    private String transactionDate;
    private String transactionTime;
    private Boolean voided = null;

    public String getInterfaceId() { return interfaceId; }
    public void setInterfaceId(String interfaceId) { this.interfaceId = interfaceId; }
    public int getResponseCode() { return responseCode; }
    public void setResponseCode(int responseCode) { this.responseCode = responseCode; }
    public String getResponseMessage() { return responseMessage; }
    public void setResponseMessage(String responseMessage) { this.responseMessage = responseMessage; }
    public String getTransactionType() { return transactionType; }
    public void setTransactionType(String transactionType) { this.transactionType = transactionType; }
    public String getPackageName() { return packageName; }
    public void setPackageName(String packageName) { this.packageName = packageName; }
    public String getResponseCodeThirtyNine() { return responseCodeThirtyNine; }
    public void setResponseCodeThirtyNine(String responseCodeThirtyNine) { this.responseCodeThirtyNine = responseCodeThirtyNine; }
    public String getResponseMessageThirtyNine() { return responseMessageThirtyNine; }
    public void setResponseMessageThirtyNine(String responseMessageThirtyNine) { this.responseMessageThirtyNine = responseMessageThirtyNine; }
    public Double getAmount() { return amount; }
    public void setAmount(Double amount) { this.amount = amount; }
    public String getMerchantName() { return merchantName; }
    public void setMerchantName(String merchantName) { this.merchantName = merchantName; }
    public String getMerchantNumber() { return merchantNumber; }
    public void setMerchantNumber(String merchantNumber) { this.merchantNumber = merchantNumber; }
    public String getTerminalNumber() { return terminalNumber; }
    public void setTerminalNumber(String terminalNumber) { this.terminalNumber = terminalNumber; }
    public String getOperatorNumber() { return operatorNumber; }
    public void setOperatorNumber(String operatorNumber) { this.operatorNumber = operatorNumber; }
    public String getCardNumber() { return cardNumber; }
    public void setCardNumber(String cardNumber) { this.cardNumber = cardNumber; }
    public String getExpirationDate() { return expirationDate; }
    public void setExpirationDate(String expirationDate) { this.expirationDate = expirationDate; }
    public String getBatchNumber() { return batchNumber; }
    public void setBatchNumber(String batchNumber) { this.batchNumber = batchNumber; }
    public String getVoucherNumber() { return voucherNumber; }
    public void setVoucherNumber(String voucherNumber) { this.voucherNumber = voucherNumber; }
    public String getReferenceNumber() { return referenceNumber; }
    public void setReferenceNumber(String referenceNumber) { this.referenceNumber = referenceNumber; }
    public String getAuthCode() { return authCode; }
    public void setAuthCode(String authCode) { this.authCode = authCode; }
    public String getTransactionDate() { return transactionDate; }
    public void setTransactionDate(String transactionDate) { this.transactionDate = transactionDate; }
    public String getTransactionTime() { return transactionTime; }
    public void setTransactionTime(String transactionTime) { this.transactionTime = transactionTime; }
    public Boolean getVoided() { return voided; }
    public void setVoided(Boolean voided) { this.voided = voided; }
}
