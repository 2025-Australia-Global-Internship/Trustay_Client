package com.maritel.trustay.dto.req;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.util.List;

@Getter
@Setter
@ToString
public class PostReq {

    private Long communityId; // 일반 커뮤니티 ID (nullable)

    private Long sharehouseId; // 쉐어하우스 ID (nullable, 쉐어하우스 커뮤니티용)

    @NotBlank(message = "제목은 필수입니다.")
    private String title;

    @NotBlank(message = "내용은 필수입니다.")
    private String content;

    private Boolean isNotice = false; // 공지 여부

    private List<String> imageUrls; // 이미지 URL 리스트
}
