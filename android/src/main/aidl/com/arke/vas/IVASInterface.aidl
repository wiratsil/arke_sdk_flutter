package com.arke.vas;
import com.arke.vas.data.VASPayload;
import com.arke.vas.IVASListener;

interface IVASInterface {
    void signIn(IVASListener listener);
    void sale(in VASPayload requestData, IVASListener listener);
    void voided(in VASPayload requestData, IVASListener listener);
    void settle(IVASListener listener);
    void orderNumberQuery(in VASPayload requestData, IVASListener listener);
    void printTransactionSummary(IVASListener listener);
    void printTransactionDetail(IVASListener listener);
    void terminalKeyManagement(IVASListener listener);
}
