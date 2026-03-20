package com.arke.sdk.api;

import android.os.RemoteException;

import com.arke.sdk.ArkeSdkDemoApplication;
import com.usdk.apiservice.aidl.led.Light;
import com.usdk.apiservice.aidl.led.ULed;

/**
 * LED API for Flutter Plugin.
 */
public class LED {

    /**
     * LED object.
     */
    private ULed led = ArkeSdkDemoApplication.getDeviceService().getLed();

    /**
     * Turn on specified lights.
     */
    public void turnOn(int... lights) throws RemoteException {
        for (int light : lights) {
            led.turnOn(light);
        }
    }

    /**
     * Turn off specified lights.
     */
    public void turnOff(int... lights) throws RemoteException {
        for (int light : lights) {
            led.turnOff(light);
        }
    }

    /**
     * Turn on all lights.
     */
    public void turnOnAll() throws RemoteException {
        turnOn(Light.RED, Light.GREEN, Light.YELLOW, Light.BLUE);
    }

    /**
     * Turn off all lights.
     */
    public void turnOffAll() throws RemoteException {
        turnOff(Light.RED, Light.GREEN, Light.YELLOW, Light.BLUE);
    }

    /**
     * Convert string color name to Light constant.
     */
    public static int colorNameToLight(String name) {
        switch (name.toLowerCase()) {
            case "red": return Light.RED;
            case "green": return Light.GREEN;
            case "yellow": return Light.YELLOW;
            case "blue": return Light.BLUE;
            default: throw new IllegalArgumentException("Unknown light color: " + name);
        }
    }

    /**
     * Creator.
     */
    private static class Creator {
        private static final LED INSTANCE = new LED();
    }

    /**
     * Get LED instance.
     */
    public static LED getInstance() {
        return Creator.INSTANCE;
    }

    /**
     * Constructor.
     */
    private LED() {
    }
}
