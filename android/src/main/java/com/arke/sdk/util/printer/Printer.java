package com.arke.sdk.util.printer;
import android.os.RemoteException;
import com.arke.sdk.ArkeSdkDemoApplication;
import com.usdk.apiservice.aidl.printer.OnPrintListener;
import com.usdk.apiservice.aidl.printer.PrinterError;
import com.usdk.apiservice.aidl.printer.UPrinter;
import java.util.Hashtable;
import java.util.Map;

/**
 * Printer API (Flutter Plugin version - no R.string dependencies).
 */
public class Printer {
    /**
     * Printer object.
     */
    private UPrinter printer = ArkeSdkDemoApplication.getDeviceService().getPrinter();

    /**
     * Get status.
     */
    public void getStatus() throws RemoteException {
        int ret = printer.getStatus();
        if (ret != PrinterError.SUCCESS) {
            throw new RemoteException(getErrorMessage(ret));
        }
    }

    /**
     * Set gray.
     */
    public void setPrnGray(int gray) throws RemoteException {
        printer.setPrnGray(gray);
    }

    /**
     * Print text.
     */
    public void addText(int align, String text) throws RemoteException {
        printer.addText(align, text);
    }

    /**
     * Feed line.
     */
    public void feedLine(int line) throws RemoteException {
        printer.feedLine(line);
    }

    /**
     * Start print.
     */
    public void start(OnPrintListener onPrintListener) throws RemoteException {
        printer.startPrint(onPrintListener);
    }

    /**
     * Add image.
     */
    public void addImage(int align, byte[] imageData) throws RemoteException {
        printer.addImage(align, imageData);
    }

    /**
     * Print barcode.
     */
    public void addBarCode(int align, int codeWith, int codeHeight, String barcode) throws RemoteException {
        printer.addBarCode(align, codeWith, codeHeight, barcode);
    }

    /**
     * Print QR code.
     */
    public void addQrCode(int align, int imageHeight, int ecLevel, String qrCode) throws RemoteException {
        printer.addQrCode(align, imageHeight, ecLevel, qrCode);
    }

    /**
     * Feed pix.
     */
    public void feedPix(int pix) throws RemoteException {
        printer.feedPix(pix);
    }

    /**
     * Creator.
     */
    private static class Creator {
        private static final Printer INSTANCE = new Printer();
    }

    /**
     * Get printer instance.
     */
    public static Printer getInstance() {
        return Creator.INSTANCE;
    }

    /**
     * Error messages map.
     */
    private static Map<Integer, String> errorMessages;

    static {
        errorMessages = new Hashtable<>();
        errorMessages.put(PrinterError.SUCCESS, "Success");
        errorMessages.put(PrinterError.SERVICE_CRASH, "Service crash");
        errorMessages.put(PrinterError.REQUEST_EXCEPTION, "Request exception");
        errorMessages.put(PrinterError.ERROR_PAPERENDED, "Paper ended");
        errorMessages.put(PrinterError.ERROR_HARDERR, "Hardware error");
        errorMessages.put(PrinterError.ERROR_OVERHEAT, "Overheat");
        errorMessages.put(PrinterError.ERROR_BUFOVERFLOW, "Buffer overflow");
        errorMessages.put(PrinterError.ERROR_LOWVOL, "Low voltage");
        errorMessages.put(PrinterError.ERROR_PAPERENDING, "Paper ending");
        errorMessages.put(PrinterError.ERROR_MOTORERR, "Motor error");
        errorMessages.put(PrinterError.ERROR_PENOFOUND, "PE not found");
        errorMessages.put(PrinterError.ERROR_PAPERJAM, "Paper jam");
        errorMessages.put(PrinterError.ERROR_NOBM, "No BM");
        errorMessages.put(PrinterError.ERROR_BUSY, "Printer busy");
        errorMessages.put(PrinterError.ERROR_BMBLACK, "BM black");
        errorMessages.put(PrinterError.ERROR_WORKON, "Power on");
        errorMessages.put(PrinterError.ERROR_LIFTHEAD, "Lift head");
        errorMessages.put(PrinterError.ERROR_CUTPOSITIONERR, "Cutter position error");
        errorMessages.put(PrinterError.ERROR_LOWTEMP, "Low temperature");
    }

    /**
     * Get error message string.
     */
    public static String getErrorMessage(int errorCode) {
        if (errorMessages.containsKey(errorCode)) {
            return errorMessages.get(errorCode);
        }
        return "Unknown printer error: " + errorCode;
    }
}
