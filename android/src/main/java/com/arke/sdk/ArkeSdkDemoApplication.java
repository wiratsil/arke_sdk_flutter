package com.arke.sdk;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.os.RemoteException;
import android.util.Log;

import com.arke.sdk.api.DeviceService;
import com.arke.sdk.util.printer.Printer;
import com.usdk.apiservice.aidl.UDeviceService;

public class ArkeSdkDemoApplication {

    private static final String TAG = "ArkeSdkManager";
    private static final String USDK_ACTION_NAME = "com.usdk.apiservice";
    private static final String USDK_PACKAGE_NAME = "com.usdk.apiservice";
    private static DeviceService deviceService;
    private static Context context;

    public static void init(Context ctx) {
        context = ctx.getApplicationContext();
        bindSdkDeviceService();
        // Printer setup if needed
        // Printer.initWebView(context); // Commented out to prevent BadTokenException (SYSTEM_ALERT_WINDOW) on Android 10+
    }

    public static Context getContext() {
        return context;
    }

    public static boolean isSdkConnected() {
        return deviceService != null;
    }

    public static DeviceService getDeviceService() {
        if (deviceService == null) {
            throw new RuntimeException("SDK service is still not connected.");
        }
        return deviceService;
    }

    private static void bindSdkDeviceService() {
        Intent intent = new Intent();
        intent.setAction(USDK_ACTION_NAME);
        intent.setPackage(USDK_PACKAGE_NAME);

        Log.d(TAG, "binding sdk device service...");
        boolean flag = context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
        if (!flag) {
            Log.d(TAG, "SDK service binding failed.");
        }
    }

    private static ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceDisconnected(ComponentName name) {
            Log.d(TAG, "SDK service disconnected.");
            deviceService = null;
        }

        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            Log.d(TAG, "SDK service connected.");
            try {
                deviceService = new DeviceService(UDeviceService.Stub.asInterface(service));
                deviceService.register();
                deviceService.debugLog(true, true);
                Log.d(TAG, "SDK deviceService initiated version:" + deviceService.getVersion() + ".");
            } catch (RemoteException e) {
                Log.e(TAG, "SDK deviceService initiating failed.", e);
            }
        }
    };
}
