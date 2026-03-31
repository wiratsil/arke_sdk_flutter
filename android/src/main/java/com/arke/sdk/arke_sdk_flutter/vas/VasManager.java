package com.arke.sdk.arke_sdk_flutter.vas;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.RemoteException;
import android.util.Log;

import com.arke.vas.IVASInterface;
import com.arke.vas.IVASListener;
import com.arke.vas.data.VASPayload;
import org.json.JSONException;
import org.json.JSONObject;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class VasManager implements EventChannel.StreamHandler {
    private static final String TAG = "VasManager";
    private Context context;
    private IVASInterface vasService;
    private EventChannel.EventSink eventSink;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private boolean isBound = false;

    public VasManager(Context context) {
        this.context = context;
    }

    public void bindService(String action, String packageName, MethodChannel.Result result) {
        if (vasService != null) {
            result.success("Already bound");
            return;
        }
        
        String finalAction = action != null && !action.isEmpty() ? action : "com.arke.vas.service";
        
        if (packageName != null && !packageName.isEmpty()) {
            performBind(finalAction, packageName, result);
        } else {
            // Try common package names - com.arke is the correct one per reference demo
            if (tryBind(finalAction, "com.arke")) {
                result.success("Binding started (com.arke)");
            } else if (tryBind(finalAction, "com.arke.sdk.demo")) {
                result.success("Binding started (com.arke.sdk.demo)");
            } else if (tryBind(finalAction, "com.arke.vas")) {
                result.success("Binding started (com.arke.vas)");
            } else {
                result.error("BIND_FAILED", "Could not bind to Arke VAS service with common packages", null);
            }
        }
    }

    private boolean tryBind(String action, String packageName) {
        Intent intent = new Intent();
        if (action != null && action.contains("/")) {
            String[] parts = action.split("/");
            intent.setComponent(new android.content.ComponentName(parts[0], parts[1]));
        } else {
            intent.setAction(action);
            intent.setPackage(packageName);
        }
        return context.bindService(intent, connection, Context.BIND_AUTO_CREATE);
    }

    private void performBind(String action, String packageName, MethodChannel.Result result) {
        Intent intent = new Intent();
        if (action != null && action.contains("/")) {
            String[] parts = action.split("/");
            intent.setComponent(new android.content.ComponentName(parts[0], parts[1]));
        } else {
            intent.setAction(action);
            intent.setPackage(packageName);
        }
        
        try {
            boolean bound = context.bindService(intent, connection, Context.BIND_AUTO_CREATE);
            if (bound) {
                result.success("Binding started");
            } else {
                result.error("BIND_FAILED", "Could not bind to " + (action.contains("/") ? action : packageName), null);
            }
        } catch (Exception e) {
            result.error("BIND_ERROR", e.getMessage(), null);
        }
    }

    public void scanAvailableVasServices(MethodChannel.Result result) {
        try {
            android.content.pm.PackageManager pm = context.getPackageManager();
            StringBuilder sb = new StringBuilder();
            
            // Scan multiple candidate packages
            String[] candidates = {"com.arke", "com.arke.vas", "com.arke.sdk.demo"};
            for (String pkg : candidates) {
                try {
                    android.content.pm.PackageInfo pi = pm.getPackageInfo(pkg, android.content.pm.PackageManager.GET_SERVICES);
                    sb.append("=== Package: ").append(pkg).append(" ===").append("\n");
                    if (pi.services != null) {
                        for (android.content.pm.ServiceInfo si : pi.services) {
                            sb.append("  Class: ").append(si.name)
                              .append(" | Exported: ").append(si.exported).append("\n");
                        }
                    } else {
                        sb.append("  No services declared\n");
                    }
                } catch (android.content.pm.PackageManager.NameNotFoundException e) {
                    sb.append("=== Package: ").append(pkg).append(" === NOT INSTALLED\n");
                }
            }
            
            if (sb.length() == 0) sb.append("No VAS packages found");
            result.success(sb.toString().trim());
        } catch (Exception e) {
            result.error("SCAN_ERROR", "Scanner Failed: " + e.getMessage(), null);
        }
    }

    public void unbindService() {
        if (isBound) {
            context.unbindService(connection);
            isBound = false;
            vasService = null;
        }
    }

    private final ServiceConnection connection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            vasService = IVASInterface.Stub.asInterface(service);
            isBound = true;
            Log.d(TAG, "VAS Service Connected");
            sendEvent("service_connected", null);
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            vasService = null;
            isBound = false;
            Log.d(TAG, "VAS Service Disconnected");
            sendEvent("service_disconnected", null);
        }
    };

    private final IVASListener.Stub vasListener = new IVASListener.Stub() {
        @Override
        public void onStart() throws RemoteException {
            Log.d(TAG, "VAS Event: onStart");
            sendEvent("onStart", null);
        }

        @Override
        public void onNext(VASPayload responseData) throws RemoteException {
            String body = responseData != null ? responseData.getBody() : null;
            Log.d(TAG, "VAS Event: onNext, Body: " + body);
            sendEvent("onNext", body);
        }

        @Override
        public void onComplete(VASPayload responseData) throws RemoteException {
            String body = responseData != null ? responseData.getBody() : null;
            Log.d(TAG, "VAS Event: onComplete, Body: " + body);
            sendEvent("onComplete", body);
        }
    };

    private void sendEvent(String eventType, String data) {
        mainHandler.post(() -> {
            if (eventSink != null) {
                java.util.Map<String, String> map = new java.util.HashMap<>();
                map.put("event", eventType);
                if (data != null) map.put("data", data);
                eventSink.success(map);
            }
        });
    }

    public void signIn(MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { 
            vasService.signIn(vasListener); 
            result.success(null); 
        }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    private VASPayload createPayload(String body) {
        VASPayload payload = new VASPayload(body != null ? body : "{}");
        // Arke VAS usually expects version in the head
        payload.setHead("{\"version\":\"V1.2.1\"}");
        return payload;
    }

    public void sale(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try {
            Log.d(TAG, "VAS Call: sale, Payload: " + payloadBody);
            // Ensure we have a valid JSON body. If payloadBody is empty or just "{}", 
            // construct a proper RequestBodyData JSON
            String body = payloadBody;
            if (body == null || body.isEmpty() || body.equals("{}")) {
                body = "{\"amount\":0.0}";
            }
            vasService.sale(createPayload(body), vasListener); 
            result.success(null); 
        }
        catch (RemoteException e) { 
            Log.e(TAG, "VAS Call Error: sale", e);
            result.error("REMOTE_EXCEPTION", e.getMessage(), null); 
        }
    }

    public void voided(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { 
            Log.d(TAG, "VAS Call: voided, Payload: " + payloadBody);
            vasService.voided(createPayload(payloadBody), vasListener); 
            result.success(null); 
        }
        catch (RemoteException e) { 
            Log.e(TAG, "VAS Call Error: voided", e);
            result.error("REMOTE_EXCEPTION", e.getMessage(), null); 
        }
    }


    public void settle(MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.settle(vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void orderNumberQuery(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { 
            Log.d(TAG, "VAS Call: orderNumberQuery, Payload: " + payloadBody);
            vasService.orderNumberQuery(createPayload(payloadBody), vasListener); 
            result.success(null); 
        }
        catch (RemoteException e) { 
            Log.e(TAG, "VAS Call Error: orderNumberQuery", e);
            result.error("REMOTE_EXCEPTION", e.getMessage(), null); 
        }
    }

    public void printTransactionSummary(MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.printTransactionSummary(vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void printTransactionDetail(MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.printTransactionDetail(vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void terminalKeyManagement(MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.terminalKeyManagement(vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void getActionConfig(MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { result.success(vasService.getActionConfig()); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void getTaskConfig(MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { result.success(vasService.getTaskConfig()); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    // ==================== PHASE 2: Core Transactions ====================
    public void refund(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { 
            Log.d(TAG, "VAS Call: refund, Payload: " + payloadBody);
            vasService.refund(createPayload(payloadBody), vasListener); 
            result.success(null); 
        }
        catch (RemoteException e) { 
            Log.e(TAG, "VAS Call Error: refund", e);
            result.error("REMOTE_EXCEPTION", e.getMessage(), null); 
        }
    }

    public void balance(MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.balance(vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void ecashBalanceQuery(MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.ecashBalanceQuery(vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void offline(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.offline(createPayload(payloadBody), vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void offlineSettlement(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.offlineSettlement(createPayload(payloadBody), vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    // ==================== PHASE 2: Pre-Authorization ====================
    public void preAuthorization(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { 
            Log.d(TAG, "VAS Call: preAuthorization, Payload: " + payloadBody);
            vasService.preAuthorization(createPayload(payloadBody), vasListener); 
            result.success(null); 
        }
        catch (RemoteException e) { 
            Log.e(TAG, "VAS Call Error: preAuthorization", e);
            result.error("REMOTE_EXCEPTION", e.getMessage(), null); 
        }
    }

    public void preAuthorizationVoid(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.preAuthorizationVoid(createPayload(payloadBody), vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void preAuthorizationCompletionRequest(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.preAuthorizationCompletionRequest(createPayload(payloadBody), vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void preAuthorizationCompletionAdvice(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.preAuthorizationCompletionAdvice(createPayload(payloadBody), vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void preAuthorizationCompletionVoid(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.preAuthorizationCompletionVoid(createPayload(payloadBody), vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    // ==================== PHASE 2: Adjustments ====================
    public void settlementAdjustment(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { 
            Log.d(TAG, "VAS Call: settlementAdjustment, Payload: " + payloadBody);
            vasService.settlementAdjustment(createPayload(payloadBody), vasListener); 
            result.success(null); 
        }
        catch (RemoteException e) { 
            Log.e(TAG, "VAS Call Error: settlementAdjustment", e);
            result.error("REMOTE_EXCEPTION", e.getMessage(), null); 
        }
    }

    public void doAction(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { 
            Log.d(TAG, "VAS Call: doAction, Payload: " + payloadBody);
            vasService.doAction(createPayload(payloadBody), vasListener); 
            result.success(null); 
        }
        catch (RemoteException e) { 
            Log.e(TAG, "VAS Call Error: doAction", e);
            result.error("REMOTE_EXCEPTION", e.getMessage(), null); 
        }
    }

    private String firstNonEmpty(JSONObject payload, String... keys) {
        for (String key : keys) {
            String value = payload.optString(key, null);
            if (value != null) {
                value = value.trim();
                if (!value.isEmpty() && !"null".equalsIgnoreCase(value)) {
                    return value;
                }
            }
        }
        return null;
    }

    private void putIfMissing(JSONObject payload, String key, Object value) throws JSONException {
        if (value == null || payload.has(key)) {
            return;
        }
        if (value instanceof String && ((String) value).trim().isEmpty()) {
            return;
        }
        payload.put(key, value);
    }

    private String normalizeAdjustTipsPayload(String payloadBody) throws JSONException {
        JSONObject payload = new JSONObject(
            payloadBody != null && !payloadBody.trim().isEmpty() ? payloadBody : "{}"
        );
        JSONObject normalized = new JSONObject();

        if (payload.has("amount")) {
            normalized.put("amount", payload.get("amount"));
        }
        if (payload.has("needAppPrinted")) {
            normalized.put("needAppPrinted", payload.get("needAppPrinted"));
        }
        if (payload.has("inputRemarkInfo")) {
            normalized.put("inputRemarkInfo", payload.get("inputRemarkInfo"));
        }
        if (payload.has("orderNumber")) {
            normalized.put("orderNumber", payload.get("orderNumber"));
        }

        String voucher = firstNonEmpty(
            payload,
            "originalVoucherNumber",
            "voucherNumber",
            "voucherNo",
            "origVoucherNumber",
            "origVoucherNo"
        );
        if (voucher != null) {
            normalized.put("originalVoucherNumber", voucher);
        }

        String reference = firstNonEmpty(
            payload,
            "originalReferenceNumber",
            "referenceNumber",
            "referenceNo",
            "refNo",
            "origReferenceNo",
            "origRefNo"
        );
        if (reference != null) {
            normalized.put("originalReferenceNumber", reference);
        }

        String authCode = firstNonEmpty(
            payload,
            "originalAuthorizationCode",
            "authorizationCode",
            "authCode",
            "origAuthCode"
        );
        if (authCode != null) {
            normalized.put("originalAuthorizationCode", authCode);
            putIfMissing(payload, "authorizationCode", authCode);
            if (payload.has("authorizationCode")) {
                normalized.put("authorizationCode", payload.get("authorizationCode"));
            }
        }

        if (payload.has("cardNumber")) {
            normalized.put("cardNumber", payload.get("cardNumber"));
        }
        if (payload.has("expiryDate")) {
            normalized.put("expiryDate", payload.get("expiryDate"));
        }
        if (payload.has("authorizationMethod")) {
            normalized.put("authorizationMethod", payload.get("authorizationMethod"));
        }

        return normalized.toString();
    }

    public void adjustTips(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { 
            String body = normalizeAdjustTipsPayload(payloadBody);
            Log.d(TAG, "VAS Call: adjustTips, Payload: " + body);
            vasService.adjustTips(createPayload(body), vasListener); 
            result.success(null); 
        }
        catch (JSONException e) {
            Log.e(TAG, "VAS Call Error: adjustTips payload", e);
            result.error("INVALID_PAYLOAD", e.getMessage(), null);
        }
        catch (RemoteException e) { 
            Log.e(TAG, "VAS Call Error: adjustTips", e);
            result.error("REMOTE_EXCEPTION", e.getMessage(), null); 
        }
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        this.eventSink = null;
    }
}
