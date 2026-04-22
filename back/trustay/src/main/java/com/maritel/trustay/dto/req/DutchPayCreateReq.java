package com.maritel.trustay.dto.req;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class DutchPayCreateReq {

    @NotNull
    @Min(1)
    @Schema(description = "N빵 총액(원)")
    private Long totalAmount;

    @NotNull
    @NotEmpty
    @Schema(description = "N빵 참여 회원 ID 목록(중복 없이). 정산 받는 사람도 포함합니다.")
    private List<Long> memberIds;

    @NotNull
    @Schema(description = "실제 송금을 받을 사람(동료들이 보낼 계좌 주인). memberIds 에 반드시 포함")
    private Long payeeMemberId;

    @Schema(description = "메모/제목")
    private String title;

    @Schema(description = "선택: 연관 계약 ID")
    private Long contractId;
}
