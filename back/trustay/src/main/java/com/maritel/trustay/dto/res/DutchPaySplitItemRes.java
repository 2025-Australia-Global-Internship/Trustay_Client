package com.maritel.trustay.dto.res;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class DutchPaySplitItemRes {
    private Long paymentId;
    private Long memberId;
    private Long amount;
    private String orderId;
    private String targetAccount;
}
