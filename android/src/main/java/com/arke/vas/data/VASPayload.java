package com.arke.vas.data;

import android.os.Parcel;
import android.os.Parcelable;

public class VASPayload implements Parcelable {
    private String head;
    private String body;

    public VASPayload(String body) {
        this.head = new HeadData().toString();
        this.body = body;
    }

    protected VASPayload(Parcel in) {
        head = in.readString();
        body = in.readString();
    }

    public static final Creator<VASPayload> CREATOR = new Creator<VASPayload>() {
        @Override
        public VASPayload createFromParcel(Parcel in) {
            if (in == null) {
                return new VASPayload("");
            }
            return new VASPayload(in);
        }

        @Override
        public VASPayload[] newArray(int size) {
            return new VASPayload[size];
        }
    };

    public String getHead() {
        return head;
    }

    public void setHead(String head) {
        this.head = head;
    }

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(this.head);
        dest.writeString(this.body);
    }

    public void readFromParcel(Parcel dest) {
        this.head = dest.readString();
        this.body = dest.readString();
    }

    @Override
    public String toString() {
        return "head:" + this.head + ", body:" + this.body;
    }
}
