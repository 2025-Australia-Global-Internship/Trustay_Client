package com.maritel.trustay.client;

import lombok.Getter;

@Getter
public class TossPaymentsApiException extends RuntimeException {

    private final int httpStatus;
    private final String responseBody;

    public TossPaymentsApiException(int httpStatus, String responseBody) {
        super("Toss API error HTTP " + httpStatus + ": " + responseBody);
        this.httpStatus = httpStatus;
        this.responseBody = responseBody;
    }
}
