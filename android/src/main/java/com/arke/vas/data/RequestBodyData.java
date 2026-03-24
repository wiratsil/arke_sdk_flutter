package com.arke.vas.data;

public class RequestBodyData extends BodyData {
    private Double amount;
    private Boolean needAppPrinted;
    private String originalVoucherNumber;
    private String inputRemarkInfo;
    private String originalReferenceNumber;
    private String cardNumber;
    private String expiryDate;
    private String authorizationMethod;
    private String authorizationCode;

    public Double getAmount() { return amount; }
    public void setAmount(Double amount) { this.amount = amount; }
    public Boolean getNeedAppPrinted() { return needAppPrinted; }
    public void setNeedAppPrinted(Boolean needAppPrinted) { this.needAppPrinted = needAppPrinted; }
    public String getOriginalVoucherNumber() { return originalVoucherNumber; }
    public void setOriginalVoucherNumber(String originalVoucherNumber) { this.originalVoucherNumber = originalVoucherNumber; }
    public String getInputRemarkInfo() { return inputRemarkInfo; }
    public void setInputRemarkInfo(String inputRemarkInfo) { this.inputRemarkInfo = inputRemarkInfo; }
    public String getOriginalReferenceNumber() { return originalReferenceNumber; }
    public void setOriginalReferenceNumber(String originalReferenceNumber) { this.originalReferenceNumber = originalReferenceNumber; }
    public String getCardNumber() { return cardNumber; }
    public void setCardNumber(String cardNumber) { this.cardNumber = cardNumber; }
    public String getExpiryDate() { return expiryDate; }
    public void setExpiryDate(String expiryDate) { this.expiryDate = expiryDate; }
    public String getAuthorizationMethod() { return authorizationMethod; }
    public void setAuthorizationMethod(String authorizationMethod) { this.authorizationMethod = authorizationMethod; }
    public String getAuthorizationCode() { return authorizationCode; }
    public void setAuthorizationCode(String authorizationCode) { this.authorizationCode = authorizationCode; }
}
