package com.maritel.trustay.dto.req;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class PaymentConfirmReq {

    @NotBlank
    @Schema(description = "토스 결제위젯에서 받은 paymentKey")
    private String paymentKey;

    @NotBlank
    @Schema(description = "prepare 단계에서 서버가 내려준 orderId")
    private String orderId;

    @NotNull
    @Min(1)
    private Long amount;
}
