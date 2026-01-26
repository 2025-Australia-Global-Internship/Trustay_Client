package com.maritel.trustay.dto.req;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class CommunityReq {

    @NotBlank(message = "커뮤니티 이름은 필수입니다.")
    private String name;

    private String description;

    private String imageUrl;
}
