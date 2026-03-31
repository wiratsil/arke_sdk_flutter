package com.arke.sdk.arke_sdk_flutter;

import android.content.Context;
import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.List;

import io.flutter.plugin.common.EventChannel;
import com.arke.sdk.arke_sdk_flutter.vas.VasManager;

/** ArkeSdkFlutterPlugin */
public class ArkeSdkFlutterPlugin implements FlutterPlugin, MethodCallHandler {
  private MethodChannel channel;
  private Context context;
  private VasManager vasManager;
  private EventChannel vasEventChannel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    context = flutterPluginBinding.getApplicationContext();
    com.arke.sdk.ArkeSdkDemoApplication.init(context);
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "arke_sdk_flutter");
    channel.setMethodCallHandler(this);

    vasManager = new VasManager(context);
    vasEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "arke_sdk_flutter/vas_events");
    vasEventChannel.setStreamHandler(vasManager);
  }

  private boolean checkSdkConnected(Result result) {
    if (!com.arke.sdk.ArkeSdkDemoApplication.isSdkConnected()) {
      result.error("SDK_NOT_CONNECTED", "Arke SDK Service is not bound yet or not installed.", null);
      return false;
    }
    return true;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {

      // ==================== System ====================

      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;

      case "getTerminalInfo":
        handleGetTerminalInfo(call, result);
        break;

      case "rebootDevice":
        handleRebootDevice(call, result);
        break;

      case "updateSystemTime":
        handleUpdateSystemTime(call, result);
        break;

      // ==================== Beeper ====================

      case "beep":
        handleBeep(call, result);
        break;

      // ==================== Printer ====================

      case "printText":
        handlePrintText(call, result);
        break;

      case "printBarcode":
        handlePrintBarcode(call, result);
        break;

      case "printQrCode":
        handlePrintQrCode(call, result);
        break;

      case "printImage":
        handlePrintImage(call, result);
        break;

      case "setPrinterGray":
        handleSetPrinterGray(call, result);
        break;

      case "getPrinterStatus":
        handleGetPrinterStatus(call, result);
        break;

      case "feedPaper":
        handleFeedPaper(call, result);
        break;

      // ==================== LED ====================

      case "ledTurnOn":
        handleLedTurnOn(call, result);
        break;

      case "ledTurnOff":
        handleLedTurnOff(call, result);
        break;

      case "ledTurnOnAll":
        handleLedTurnOnAll(call, result);
        break;

      case "ledTurnOffAll":
        handleLedTurnOffAll(call, result);
        break;

      // ==================== Scanner ====================

      case "startScanner":
        handleStartScanner(call, result, false);
        break;

      case "startFrontScanner":
        handleStartScanner(call, result, true);
        break;

      case "stopScanner":
        handleStopScanner(call, result, false);
        break;

      case "stopFrontScanner":
        handleStopScanner(call, result, true);
        break;

      // ==================== NFC ====================

      case "startNfcScan":
        handleStartNfcScan(call, result);
        break;

      // ==================== Magnetic Card Reader ====================

      case "startMagReader":
        handleStartMagReader(call, result);
        break;

      case "stopMagReader":
        handleStopMagReader(call, result);
        break;

      // ==================== Serial Port ====================

      case "serialOpen":
        handleSerialOpen(call, result);
        break;

      case "serialInit":
        handleSerialInit(call, result);
        break;

      case "serialWrite":
        handleSerialWrite(call, result);
        break;

      case "serialRead":
        handleSerialRead(call, result);
        break;

      case "serialClose":
        handleSerialClose(call, result);
        break;

      // ==================== VAS ====================

      case "vasBindService":
        String action = call.argument("action");
        String pkg = call.argument("packageName");
        vasManager.bindService(action, pkg, result);
        break;

      case "vasUnbindService":
        vasManager.unbindService();
        result.success(null);
        break;

      case "vasSignIn":
        vasManager.signIn(result);
        break;

      case "vasSale":
        vasManager.sale((String) call.argument("payloadBody"), result);
        break;

      case "vasVoided":
        vasManager.voided((String) call.argument("payloadBody"), result);
        break;

      case "vasSettle":
        vasManager.settle(result);
        break;

      case "vasOrderNumberQuery":
        vasManager.orderNumberQuery((String) call.argument("payloadBody"), result);
        break;

      case "vasPrintTransactionSummary":
        vasManager.printTransactionSummary(result);
        break;

      case "vasPrintTransactionDetail":
        vasManager.printTransactionDetail(result);
        break;
      case "vasTerminalKeyManagement":
        vasManager.terminalKeyManagement(result);
        break;
      case "vasGetActionConfig":
        vasManager.getActionConfig(result);
        break;
      case "vasGetTaskConfig":
        vasManager.getTaskConfig(result);
        break;
      case "vasScanServices":
        vasManager.scanAvailableVasServices(result);
        break;

      // ==================== PHASE 2: Core Transactions ====================
      case "vasRefund":
        vasManager.refund((String) call.argument("payloadBody"), result);
        break;
      case "vasBalance":
        vasManager.balance(result);
        break;
      case "vasEcashBalanceQuery":
        vasManager.ecashBalanceQuery(result);
        break;
      case "vasOffline":
        vasManager.offline((String) call.argument("payloadBody"), result);
        break;
      case "vasOfflineSettlement":
        vasManager.offlineSettlement((String) call.argument("payloadBody"), result);
        break;

      // ==================== PHASE 2: Pre-Authorization ====================
      case "vasPreAuthorization":
        vasManager.preAuthorization((String) call.argument("payloadBody"), result);
        break;
      case "vasPreAuthorizationVoid":
        vasManager.preAuthorizationVoid((String) call.argument("payloadBody"), result);
        break;
      case "vasPreAuthorizationCompletionRequest":
        vasManager.preAuthorizationCompletionRequest((String) call.argument("payloadBody"), result);
        break;
      case "vasPreAuthorizationCompletionAdvice":
        vasManager.preAuthorizationCompletionAdvice((String) call.argument("payloadBody"), result);
        break;
      case "vasPreAuthorizationCompletionVoid":
        vasManager.preAuthorizationCompletionVoid((String) call.argument("payloadBody"), result);
        break;

      // ==================== PHASE 2: Adjustments ====================
      case "vasSettlementAdjustment":
        vasManager.settlementAdjustment((String) call.argument("payloadBody"), result);
        break;
      case "vasAdjustTips":
        vasManager.adjustTips((String) call.argument("payloadBody"), result);
        break;
      case "vasDoAction":
        vasManager.doAction((String) call.argument("payloadBody"), result);
        break;

      default:
        result.notImplemented();
        break;
    }
  }

  // ==================== System Handlers ====================

  private void handleGetTerminalInfo(MethodCall call, Result result) {
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.api.DeviceManager deviceManager = com.arke.sdk.api.DeviceManager.getInstance();
      java.util.Map<String, String> info = new java.util.HashMap<>();
      info.put("model", deviceManager.getModel());
      info.put("serialNo", deviceManager.getSerialNo());
      info.put("osVersion", deviceManager.getAndroidOSVersion());
      info.put("romVersion", deviceManager.getRomVersion());
      info.put("firmwareVersion", deviceManager.getFirmwareVersion());
      info.put("hardwareVersion", deviceManager.getHardwareVersion());
      result.success(info);
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  private void handleRebootDevice(MethodCall call, Result result) {
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.api.DeviceManager.getInstance().reboot();
      result.success(null);
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  private void handleUpdateSystemTime(MethodCall call, Result result) {
    try {
      if (!checkSdkConnected(result)) return;
      String time = call.argument("time");
      com.arke.sdk.api.DeviceManager.getInstance().updateSystemTime(time);
      result.success(null);
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  // ==================== Beeper Handler ====================

  private void handleBeep(MethodCall call, Result result) {
    int milliseconds = call.argument("milliseconds") != null ? (int) call.argument("milliseconds") : 500;
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.api.Beeper.getInstance().startBeep(milliseconds);
      result.success(null);
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  // ==================== Printer Handlers ====================

  private void handlePrintText(MethodCall call, Result result) {
    String text = call.argument("text");
    int align = call.argument("align") != null ? (int) call.argument("align") : 0;
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.util.printer.Printer printer = com.arke.sdk.util.printer.Printer.getInstance();
      printer.getStatus();
      printer.addText(align, text);
      printer.feedLine(5);
      printer.start(new com.usdk.apiservice.aidl.printer.OnPrintListener.Stub() {
        @Override
        public void onFinish() throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> result.success(null));
        }
        @Override
        public void onError(int errorCode) throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() ->
            result.error("PRINTER_ERROR", com.arke.sdk.util.printer.Printer.getErrorMessage(errorCode), null));
        }
      });
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  private void handlePrintBarcode(MethodCall call, Result result) {
    String barcode = call.argument("barcode");
    int align = call.argument("align") != null ? (int) call.argument("align") : 1;
    int codeWidth = call.argument("codeWidth") != null ? (int) call.argument("codeWidth") : 2;
    int codeHeight = call.argument("codeHeight") != null ? (int) call.argument("codeHeight") : -1;
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.util.printer.Printer printer = com.arke.sdk.util.printer.Printer.getInstance();
      printer.getStatus();
      printer.addBarCode(align, codeWidth, codeHeight, barcode);
      printer.feedLine(5);
      printer.start(new com.usdk.apiservice.aidl.printer.OnPrintListener.Stub() {
        @Override
        public void onFinish() throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> result.success(null));
        }
        @Override
        public void onError(int errorCode) throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() ->
            result.error("PRINTER_ERROR", com.arke.sdk.util.printer.Printer.getErrorMessage(errorCode), null));
        }
      });
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  private void handlePrintQrCode(MethodCall call, Result result) {
    String qrCode = call.argument("qrCode");
    int align = call.argument("align") != null ? (int) call.argument("align") : 1;
    int imageHeight = call.argument("imageHeight") != null ? (int) call.argument("imageHeight") : 240;
    int ecLevel = call.argument("ecLevel") != null ? (int) call.argument("ecLevel") : 3;
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.util.printer.Printer printer = com.arke.sdk.util.printer.Printer.getInstance();
      printer.getStatus();
      printer.addQrCode(align, imageHeight, ecLevel, qrCode);
      printer.feedLine(5);
      printer.start(new com.usdk.apiservice.aidl.printer.OnPrintListener.Stub() {
        @Override
        public void onFinish() throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> result.success(null));
        }
        @Override
        public void onError(int errorCode) throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() ->
            result.error("PRINTER_ERROR", com.arke.sdk.util.printer.Printer.getErrorMessage(errorCode), null));
        }
      });
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  private void handlePrintImage(MethodCall call, Result result) {
    byte[] imageBytes = call.argument("imageBytes");
    int align = call.argument("align") != null ? (int) call.argument("align") : 1;
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.util.printer.Printer printer = com.arke.sdk.util.printer.Printer.getInstance();
      printer.getStatus();
      printer.addImage(align, imageBytes);
      printer.feedLine(5);
      printer.start(new com.usdk.apiservice.aidl.printer.OnPrintListener.Stub() {
        @Override
        public void onFinish() throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> result.success(null));
        }
        @Override
        public void onError(int errorCode) throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() ->
            result.error("PRINTER_ERROR", com.arke.sdk.util.printer.Printer.getErrorMessage(errorCode), null));
        }
      });
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  private void handleSetPrinterGray(MethodCall call, Result result) {
    int gray = call.argument("gray") != null ? (int) call.argument("gray") : 4;
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.util.printer.Printer.getInstance().setPrnGray(gray);
      result.success(null);
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  private void handleGetPrinterStatus(MethodCall call, Result result) {
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.util.printer.Printer.getInstance().getStatus();
      result.success("OK");
    } catch (Exception e) {
      result.error("PRINTER_ERROR", e.getMessage(), null);
    }
  }

  private void handleFeedPaper(MethodCall call, Result result) {
    int lines = call.argument("lines") != null ? (int) call.argument("lines") : 1;
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.util.printer.Printer printer = com.arke.sdk.util.printer.Printer.getInstance();
      printer.feedLine(lines);
      printer.start(new com.usdk.apiservice.aidl.printer.OnPrintListener.Stub() {
        @Override
        public void onFinish() throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> result.success(null));
        }
        @Override
        public void onError(int errorCode) throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() ->
            result.error("PRINTER_ERROR", com.arke.sdk.util.printer.Printer.getErrorMessage(errorCode), null));
        }
      });
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  // ==================== LED Handlers ====================

  private void handleLedTurnOn(MethodCall call, Result result) {
    try {
      if (!checkSdkConnected(result)) return;
      List<String> lights = call.argument("lights");
      if (lights != null) {
        for (String color : lights) {
          int light = com.arke.sdk.api.LED.colorNameToLight(color);
          com.arke.sdk.api.LED.getInstance().turnOn(light);
        }
      }
      result.success(null);
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  private void handleLedTurnOff(MethodCall call, Result result) {
    try {
      if (!checkSdkConnected(result)) return;
      List<String> lights = call.argument("lights");
      if (lights != null) {
        for (String color : lights) {
          int light = com.arke.sdk.api.LED.colorNameToLight(color);
          com.arke.sdk.api.LED.getInstance().turnOff(light);
        }
      }
      result.success(null);
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  private void handleLedTurnOnAll(MethodCall call, Result result) {
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.api.LED.getInstance().turnOnAll();
      result.success(null);
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  private void handleLedTurnOffAll(MethodCall call, Result result) {
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.api.LED.getInstance().turnOffAll();
      result.success(null);
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  // ==================== Scanner Handlers ====================

  private void handleStartScanner(MethodCall call, Result result, boolean isFront) {
    try {
      if (!checkSdkConnected(result)) return;
      android.os.Bundle bundle = new android.os.Bundle();
      bundle.putInt("timeout", 30);

      com.usdk.apiservice.aidl.scanner.UScanner scanner;
      if (isFront) {
        scanner = com.arke.sdk.ArkeSdkDemoApplication.getDeviceService().getFrontScanner();
      } else {
        scanner = com.arke.sdk.ArkeSdkDemoApplication.getDeviceService().getBackScanner();
      }

      scanner.startScan(bundle, new com.usdk.apiservice.aidl.scanner.OnScanListener.Stub() {
        @Override
        public void onSuccess(String code) throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> result.success(code));
        }
        @Override
        public void onError(int error) throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() ->
            result.error("SCANNER_ERROR", "Error code: " + error, null));
        }
        @Override
        public void onTimeout() throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() ->
            result.error("SCANNER_TIMEOUT", "Scanning timed out.", null));
        }
        @Override
        public void onCancel() throws android.os.RemoteException {
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() ->
            result.error("SCANNER_CANCELLED", "Scanning was cancelled.", null));
        }
      });
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  private void handleStopScanner(MethodCall call, Result result, boolean isFront) {
    try {
      if (!checkSdkConnected(result)) return;
      if (isFront) {
        com.arke.sdk.ArkeSdkDemoApplication.getDeviceService().getFrontScanner().stopScan();
      } else {
        com.arke.sdk.ArkeSdkDemoApplication.getDeviceService().getBackScanner().stopScan();
      }
      result.success(null);
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  // ==================== NFC Handler ====================

  private void handleStartNfcScan(MethodCall call, Result result) {
    try {
      if (!checkSdkConnected(result)) return;
      final com.usdk.apiservice.aidl.rfreader.URFReader rfReader =
        com.arke.sdk.ArkeSdkDemoApplication.getDeviceService().getRFReader();
      rfReader.searchCard(new com.usdk.apiservice.aidl.rfreader.OnPassListener.Stub() {
        @Override
        public void onCardPass(int type) throws android.os.RemoteException {
          try {
            com.usdk.apiservice.aidl.data.BytesValue responseData = new com.usdk.apiservice.aidl.data.BytesValue();
            int ret = rfReader.activate(type, responseData);
            if (ret != com.usdk.apiservice.aidl.rfreader.RFError.SUCCESS) {
              throw new Exception("NFC Activation Failed, code: " + ret);
            }
            byte[] uid = rfReader.getCardSerialNo(responseData.getData());
            rfReader.halt();
            StringBuilder sb = new StringBuilder();
            for (byte b : uid) {
              sb.append(String.format("%02X", b));
            }
            final String uidString = sb.toString();
            new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> result.success(uidString));
          } catch (Exception e) {
            new android.os.Handler(android.os.Looper.getMainLooper()).post(() ->
              result.error("NFC_ACTIVATION_ERROR", e.getMessage(), null));
          }
        }
        @Override
        public void onFail(int error) throws android.os.RemoteException {
          try {
            rfReader.halt();
          } catch(Exception ignored) {}
          new android.os.Handler(android.os.Looper.getMainLooper()).post(() ->
            result.error("NFC_ERROR", "Error code: " + error, null));
        }
      });
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  // ==================== Magnetic Card Reader Handlers ====================

  private void handleStartMagReader(MethodCall call, Result result) {
    int timeout = call.argument("timeout") != null ? (int) call.argument("timeout") : 30;
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.api.MagReader.getInstance().searchCard(timeout,
        new com.usdk.apiservice.aidl.magreader.OnSwipeListener.Stub() {
          @Override
          public void onSuccess(android.os.Bundle track) throws android.os.RemoteException {
            java.util.Map<String, String> data = new java.util.HashMap<>();
            if (track != null) {
              String pan = track.getString("PAN");
              String track1 = track.getString("TRACK1");
              String track2 = track.getString("TRACK2");
              String track3 = track.getString("TRACK3");
              String serviceCode = track.getString("SERVICE_CODE");
              String expiredDate = track.getString("EXPIRED_DATE");
              if (pan != null) data.put("pan", pan);
              if (track1 != null) data.put("track1", track1);
              if (track2 != null) data.put("track2", track2);
              if (track3 != null) data.put("track3", track3);
              if (serviceCode != null) data.put("serviceCode", serviceCode);
              if (expiredDate != null) data.put("expiredDate", expiredDate);
            }
            new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> result.success(data));
          }
          @Override
          public void onError(int error) throws android.os.RemoteException {
            new android.os.Handler(android.os.Looper.getMainLooper()).post(() ->
              result.error("MAG_READER_ERROR", "Error code: " + error, null));
          }
          @Override
          public void onTimeout() throws android.os.RemoteException {
            new android.os.Handler(android.os.Looper.getMainLooper()).post(() ->
              result.error("MAG_READER_TIMEOUT", "Mag card reader timed out.", null));
          }
        });
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  private void handleStopMagReader(MethodCall call, Result result) {
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.api.MagReader.getInstance().stopSearch();
      result.success(null);
    } catch (Exception e) {
      result.error("SDK_ERROR", e.getMessage(), null);
    }
  }

  // ==================== Serial Port Handlers ====================

  private void handleSerialOpen(MethodCall call, Result result) {
    String deviceName = call.argument("deviceName");
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.api.SerialPort.getInstance().open(deviceName);
      result.success(null);
    } catch (Exception e) {
      result.error("SERIAL_ERROR", e.getMessage(), null);
    }
  }

  private void handleSerialInit(MethodCall call, Result result) {
    int baudRate = call.argument("baudRate") != null ? (int) call.argument("baudRate") : 9600;
    int parityBit = call.argument("parityBit") != null ? (int) call.argument("parityBit") : 0;
    int dataBit = call.argument("dataBit") != null ? (int) call.argument("dataBit") : 8;
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.api.SerialPort.getInstance().init(baudRate, parityBit, dataBit);
      result.success(null);
    } catch (Exception e) {
      result.error("SERIAL_ERROR", e.getMessage(), null);
    }
  }

  private void handleSerialWrite(MethodCall call, Result result) {
    byte[] data = call.argument("data");
    int timeout = call.argument("timeout") != null ? (int) call.argument("timeout") : 5000;
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.api.SerialPort.getInstance().write(data, timeout);
      result.success(null);
    } catch (Exception e) {
      result.error("SERIAL_ERROR", e.getMessage(), null);
    }
  }

  private void handleSerialRead(MethodCall call, Result result) {
    int length = call.argument("length") != null ? (int) call.argument("length") : 1024;
    int timeout = call.argument("timeout") != null ? (int) call.argument("timeout") : 5000;
    try {
      if (!checkSdkConnected(result)) return;
      byte[] data = com.arke.sdk.api.SerialPort.getInstance().read(length, timeout);
      result.success(data);
    } catch (Exception e) {
      result.error("SERIAL_ERROR", e.getMessage(), null);
    }
  }

  private void handleSerialClose(MethodCall call, Result result) {
    try {
      if (!checkSdkConnected(result)) return;
      com.arke.sdk.api.SerialPort.getInstance().close();
      result.success(null);
    } catch (Exception e) {
      result.error("SERIAL_ERROR", e.getMessage(), null);
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    if (vasManager != null) vasManager.unbindService();
    if (vasEventChannel != null) vasEventChannel.setStreamHandler(null);
  }
}
