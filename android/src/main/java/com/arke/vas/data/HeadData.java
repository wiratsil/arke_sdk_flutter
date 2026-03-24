package com.arke.vas.data;

public class HeadData {
    private String version = "V1.2.0";

    @Override
    public String toString() {
        return "{\"version\": \"" + this.version + "\"}";
    }
}
