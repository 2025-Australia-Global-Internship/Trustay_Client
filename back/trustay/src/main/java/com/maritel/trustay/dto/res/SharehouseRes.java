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
    private Integer wishCount;
    private HouseType houseType;
    private ApprovalStatus approvalStatus;
    private List<String> imageUrls;
    private Boolean wishedByMe; // 현재 로그인 사용자 찜 여부 (선택)

    // [수정] 메서드 시그니처에 List<SharehouseImage> images 추가
    public static SharehouseRes from(Sharehouse sharehouse, List<SharehouseImage> images) {
        return from(sharehouse, images, false);
    }

    public static SharehouseRes from(Sharehouse sharehouse, List<SharehouseImage> images, boolean wishedByMe) {
        return SharehouseRes.builder()
                .id(sharehouse.getId())
                .title(sharehouse.getTitle())
                .address(sharehouse.getAddress())
                .viewCount(sharehouse.getViewCount())
                .wishCount(sharehouse.getWishCount() != null ? sharehouse.getWishCount() : 0)
                .wishedByMe(wishedByMe)
                .houseType(sharehouse.getHouseType())
                .approvalStatus(sharehouse.getApprovalStatus())
                // [수정] images 리스트를 스트림으로 변환하여 URL 추출
                .imageUrls(images != null ? images.stream()
                        .map(si -> si.getImage().getImageUrl())
                        .collect(Collectors.toList()) : List.of())
                .build();
    }
}