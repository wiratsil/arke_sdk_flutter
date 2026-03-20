package com.arke.sdk.api;

import android.os.RemoteException;

import com.arke.sdk.ArkeSdkDemoApplication;
import com.usdk.apiservice.aidl.serialport.SerialPortError;
import com.usdk.apiservice.aidl.serialport.USerialPort;

import java.util.Hashtable;
import java.util.Map;

/**
 * SerialPort API for Flutter Plugin (no R.string dependencies).
 */
public class SerialPort {

    /**
     * Serial port object.
     */
    private USerialPort serialPort;

    /**
     * Open.
     */
    public void open(String deviceName) throws RemoteException {
        serialPort = ArkeSdkDemoApplication.getDeviceService().getSerialPort(deviceName);
        int ret = serialPort.open();
        if (ret != SerialPortError.SUCCESS) {
            throw new RemoteException(getErrorMessage(ret));
        }
    }

    /**
     * Init.
     */
    public void init(int baudRate, int parityBit, int dataBit) throws RemoteException {
        int ret = serialPort.init(baudRate, parityBit, dataBit);
        if (ret != SerialPortError.SUCCESS) {
            throw new RemoteException(getErrorMessage(ret));
        }
    }

    /**
     * Write.
     */
    public void write(byte[] data, int timeout) throws RemoteException {
        int ret = serialPort.write(data, timeout);
        if (ret == -1) {
            throw new RemoteException("Serial port write failed");
        }
    }

    /**
     * Read.
     */
    public byte[] read(int length, int timeout) throws RemoteException {
        byte[] data = new byte[length];
        int ret = serialPort.read(data, timeout);
        if (ret == -1) {
            throw new RemoteException("Serial port read failed");
        }
        return data;
    }

    /**
     * Close.
     */
    public void close() throws RemoteException {
        if (serialPort != null) {
            int ret = serialPort.close();
            if (ret != SerialPortError.SUCCESS) {
                throw new RemoteException(getErrorMessage(ret));
            }
            serialPort = null;
        }
    }

    /**
     * Error messages map.
     */
    private static Map<Integer, String> errorMessages;

    static {
        errorMessages = new Hashtable<>();
        errorMessages.put(SerialPortError.SUCCESS, "Success");
        errorMessages.put(SerialPortError.SERVICE_CRASH, "Service crash");
        errorMessages.put(SerialPortError.REQUEST_EXCEPTION, "Request exception");
        errorMessages.put(SerialPortError.ERROR_DEVICE_DISABLE, "Device disabled");
        errorMessages.put(SerialPortError.ERROR_OTHERERR, "Other error");
        errorMessages.put(SerialPortError.ERROR_PARAMERR, "Parameter error");
        errorMessages.put(SerialPortError.ERROR_TIMEOUT, "Timeout");
    }

    /**
     * Get error message string.
     */
    public static String getErrorMessage(int errorCode) {
        if (errorMessages.containsKey(errorCode)) {
            return errorMessages.get(errorCode);
        }
        return "Unknown serial port error: " + errorCode;
    }

    /**
     * Creator.
     */
    private static class Creator {
        private static final SerialPort INSTANCE = new SerialPort();
    }

    /**
     * Get serial port instance.
     */
    public static SerialPort getInstance() {
        return Creator.INSTANCE;
    }

    /**
     * Constructor.
     */
    private SerialPort() {
    }
}
