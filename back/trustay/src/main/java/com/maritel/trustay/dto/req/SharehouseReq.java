package com.maritel.trustay.dto.req;

import com.maritel.trustay.constant.HouseType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.util.List;

@Getter
@Setter
@ToString
public class SharehouseReq {

    @NotBlank(message = "제목은 필수입니다.")
    private String title;

    @NotBlank(message = "상세 설명은 필수입니다.")
    private String description;

    @NotBlank(message = "주소는 필수입니다.")
    private String address;

    @NotNull(message = "주거 형태를 선택해주세요.")
    private HouseType houseType;

    @NotNull(message = "월세는 필수입니다.")
    private Integer rentPrice;

    @NotNull(message = "보증금은 필수입니다.")
    private Integer deposit;

    private Integer roomCount;
    private Integer bathroomCount;
    private Integer currentResidents;

    private List<String> options;

    // [변경] 파일 객체 대신, 업로드된 이미지 URL 리스트를 받습니다.
    @NotEmpty(message = "이미지는 최소 1장 이상 등록해야 합니다.")
    private List<String> imageUrls;
}