package com.maritel.trustay.dto.res;

import com.maritel.trustay.constant.PaymentStatus;
import com.maritel.trustay.constant.PaymentType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class PaymentConfirmRes {
    private Long paymentId;
    private String orderId;
    private PaymentStatus status;
    private PaymentType paymentType;
    /** 토스 결제 객체의 status (예: DONE) */
    private String tossPaymentStatus;
}
