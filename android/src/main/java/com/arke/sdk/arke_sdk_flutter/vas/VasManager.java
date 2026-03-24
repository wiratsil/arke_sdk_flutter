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
            sendEvent("onStart", null);
        }

        @Override
        public void onNext(VASPayload responseData) throws RemoteException {
            sendEvent("onNext", responseData != null ? responseData.getBody() : null);
        }

        @Override
        public void onComplete(VASPayload responseData) throws RemoteException {
            sendEvent("onComplete", responseData != null ? responseData.getBody() : null);
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
        try { vasService.signIn(vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void sale(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try {
            // Ensure we have a valid JSON body. If payloadBody is empty or just "{}", 
            // construct a proper RequestBodyData JSON
            String body = payloadBody;
            if (body == null || body.isEmpty() || body.equals("{}")) {
                body = "{\"amount\":0.0}";
            }
            vasService.sale(new VASPayload(body), vasListener); 
            result.success(null); 
        }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void voided(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.voided(new VASPayload(payloadBody != null ? payloadBody : "{}"), vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void settle(MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.settle(vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
    }

    public void orderNumberQuery(String payloadBody, MethodChannel.Result result) {
        if (vasService == null) { result.error("NOT_BOUND", "VAS Service not bound", null); return; }
        try { vasService.orderNumberQuery(new VASPayload(payloadBody != null ? payloadBody : "{}"), vasListener); result.success(null); }
        catch (RemoteException e) { result.error("REMOTE_EXCEPTION", e.getMessage(), null); }
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

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        this.eventSink = null;
    }
}
