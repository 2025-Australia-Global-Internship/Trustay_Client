package com.maritel.trustay.dto.req;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.util.List;

@Getter
@Setter
@ToString
public class PostUpdateReq {

    private String title;

    private String content;

    private Boolean isNotice;

    private List<String> imageUrls; // 이미지 URL 리스트
}
