package com.arke.sdk.api;

import android.os.RemoteException;

import com.arke.sdk.ArkeSdkDemoApplication;
import com.usdk.apiservice.aidl.magreader.OnSwipeListener;
import com.usdk.apiservice.aidl.magreader.TrackType;
import com.usdk.apiservice.aidl.magreader.UMagReader;

/**
 * MagReader API for Flutter Plugin.
 */
public class MagReader {

    /**
     * Mag reader object.
     */
    private UMagReader magReader = ArkeSdkDemoApplication.getDeviceService().getMagReader();

    /**
     * Search card.
     */
    public void searchCard(int timeout, OnSwipeListener onSwipeListener) throws RemoteException {
        magReader.setTrackType(TrackType.INDUSTRY_CARD);
        magReader.searchCard(timeout, onSwipeListener);
    }

    /**
     * Stop search.
     */
    public void stopSearch() throws RemoteException {
        magReader.stopSearch();
    }

    /**
     * Creator.
     */
    private static class Creator {
        private static final MagReader INSTANCE = new MagReader();
    }

    /**
     * Get mag reader instance.
     */
    public static MagReader getInstance() {
        return Creator.INSTANCE;
    }

    /**
     * Constructor.
     */
    private MagReader() {
    }
}
