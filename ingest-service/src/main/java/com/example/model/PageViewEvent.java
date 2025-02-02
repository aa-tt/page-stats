package com.example.model;

public class PageViewEvent {
    private String pageName;
    private String region;
    private String timestamp;

    // Getters
    public String getPageName() {
        return pageName;
    }

    public String getRegion() {
        return region;
    }

    public String getTimestamp() {
        return timestamp;
    }

    // Setters
    public void setPageName(String pageName) {
        this.pageName = pageName;
    }

    public void setRegion(String region) {
        this.region = region;
    }

    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }
}