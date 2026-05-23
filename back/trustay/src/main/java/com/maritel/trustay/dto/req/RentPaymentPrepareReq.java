package com.maritel.trustay.dto.req;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class RentPaymentPrepareReq {

    @NotNull
    @Schema(description = "계약 ID")
    private Long contractId;

    @NotNull
    @Min(100)
    @Schema(description = "결제 금액(원). 토스 테스트 시에도 보통 100원 이상 권장")
    private Long amount;
}
