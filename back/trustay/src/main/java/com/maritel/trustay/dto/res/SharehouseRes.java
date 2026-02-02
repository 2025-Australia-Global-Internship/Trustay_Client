package com.maritel.trustay.dto.res;

import com.maritel.trustay.constant.ApprovalStatus;
import com.maritel.trustay.constant.HouseType;
import com.maritel.trustay.entity.Sharehouse;
import com.maritel.trustay.entity.SharehouseImage; // 추가 필수
import lombok.Builder;
import lombok.Getter;

import java.util.List;
import java.util.stream.Collectors; // 추가 필수

@Getter
@Builder
public class SharehouseRes {
    private Long id;
    private String title;
    private String address;
    private Integer viewCount;
    private HouseType houseType;
    private ApprovalStatus approvalStatus;
    private List<String> imageUrls;

    // [수정] 메서드 시그니처에 List<SharehouseImage> images 추가
    public static SharehouseRes from(Sharehouse sharehouse, List<SharehouseImage> images) {
        return SharehouseRes.builder()
                .id(sharehouse.getId())
                .title(sharehouse.getTitle())
                .address(sharehouse.getAddress())
                .viewCount(sharehouse.getViewCount())
                .houseType(sharehouse.getHouseType())
                .approvalStatus(sharehouse.getApprovalStatus())
                // [수정] images 리스트를 스트림으로 변환하여 URL 추출
                .imageUrls(images != null ? images.stream()
                        .map(si -> si.getImage().getImageUrl())
                        .collect(Collectors.toList()) : List.of())
                .build();
    }
}