package com.maritel.trustay.dto.res;

import com.maritel.trustay.constant.RoomType;
import com.maritel.trustay.entity.Sharehouse;
import com.maritel.trustay.constant.HouseType;
import com.maritel.trustay.entity.SharehouseImage;
import lombok.Builder;
import lombok.Getter;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Getter
@Builder
public class SharehouseResultRes {
    private Long id;
    private String title;
    private String description;
    private String address;
    private HouseType houseType;
    private Integer rentPrice;
    private Integer roomCount;
    private Integer bathroomCount;
    private String homeRulse;
    private String features;
    private Integer viewCount;
    private String hostName; // 집주인 이름 표시
    private Double lat;
    private Double lon;
    private List<String> imageUrls;
    private Boolean billsIncluded;
    private RoomType roomType;
    private Integer bondType;
    private Integer minimumStay;
    private String gender;
    private String age;
    private String religion;
    private String dietaryPreference;

    // Entity -> DTO 변환 메서드
    public static SharehouseResultRes from(Sharehouse sharehouse, List<SharehouseImage> images) {
        return SharehouseResultRes.builder()
                .id(sharehouse.getId())
                .title(sharehouse.getTitle())
                .description(sharehouse.getDescription())
                .address(sharehouse.getAddress())
                .houseType(sharehouse.getHouseType())
                .rentPrice(sharehouse.getRentPrice())
                .roomCount(sharehouse.getRoomCount())
                .bathroomCount(sharehouse.getBathroomCount())
                .homeRulse(sharehouse.getHomeRules())
                .features(sharehouse.getFeatures())
                .viewCount(sharehouse.getViewCount())
                .hostName(sharehouse.getHost().getName())
                .lat(sharehouse.getLatitude())
                .lon(sharehouse.getLongitude())
                // [수정] 리스트 처리
                .imageUrls(images != null ? images.stream()
                        .map(si -> si.getImage().getImageUrl())
                        .collect(Collectors.toList()) : List.of())
                .billsIncluded(sharehouse.getBillsIncluded())
                .roomType(sharehouse.getRoomType())
                .bondType(sharehouse.getBondType())
                .minimumStay(sharehouse.getMinimumStay())
                .gender(sharehouse.getGender())
                .age(sharehouse.getAge())
                .religion(sharehouse.getReligion())
                .dietaryPreference(sharehouse.getDietaryPreference())
                .build();
    }

}