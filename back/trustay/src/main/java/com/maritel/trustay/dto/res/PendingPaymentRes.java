package com.maritel.trustay.dto.res;

import com.maritel.trustay.constant.PaymentType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class PendingPaymentRes {
    private Long paymentId;
    private String orderId;
    private Long amount;
    private PaymentType paymentType;
    private String targetAccount;
    private Long dutchPayGroupId;
}
