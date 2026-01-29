package com.maritel.trustay.dto.res;

import com.maritel.trustay.constant.ApprovalStatus;
import com.maritel.trustay.constant.HouseType;
import com.maritel.trustay.entity.Sharehouse;
import lombok.Builder;
import lombok.Getter;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

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

    public static SharehouseRes from(Sharehouse sharehouse) {
        return SharehouseRes.builder()
                .id(sharehouse.getId())
                .title(sharehouse.getTitle())
                .address(sharehouse.getAddress())
                .viewCount(sharehouse.getViewCount())
                .houseType(sharehouse.getHouseType())
                .approvalStatus(sharehouse.getApprovalStatus())
                .imageUrls(parseImageUrls(sharehouse.getImageUrls()))
                .build();
    }

    private static List<String> parseImageUrls(String raw) {
        if (raw == null || raw.isBlank()) return List.of();
        return Arrays.stream(raw.split(","))
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .collect(Collectors.toList());
    }
}