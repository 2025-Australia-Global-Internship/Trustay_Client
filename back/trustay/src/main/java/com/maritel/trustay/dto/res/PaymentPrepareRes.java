package com.maritel.trustay.dto.res;

import com.maritel.trustay.constant.PaymentType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class PaymentPrepareRes {
    private Long paymentId;
    private String orderId;
    private Long amount;
    private PaymentType paymentType;
    /** 집주인/정산 담당 계좌 안내(실제 이체는 사용자가 직접) */
    private String targetAccount;
    private String settlementGuide;
}
