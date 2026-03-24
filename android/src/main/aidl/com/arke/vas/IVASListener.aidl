package com.arke.vas;
import com.arke.vas.data.VASPayload;
interface IVASListener {
    void onStart();
    void onNext(in VASPayload responseData);
    void onComplete(in VASPayload responseData);
}
