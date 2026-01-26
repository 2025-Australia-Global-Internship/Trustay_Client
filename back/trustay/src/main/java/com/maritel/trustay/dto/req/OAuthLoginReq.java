package com.maritel.trustay.dto.req;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter
@Setter
@ToString
@AllArgsConstructor
public class OAuthLoginReq {
    @NotBlank(message = "토큰은 필수 입력 값입니다.")
    private String firebaseToken;
}
