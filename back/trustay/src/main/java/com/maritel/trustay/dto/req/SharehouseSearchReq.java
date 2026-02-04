package com.maritel.trustay.dto.req;

import com.maritel.trustay.constant.HouseType;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.util.List;

@Getter
@Setter
@ToString
public class SharehouseSearchReq {
    // 1. 기본 검색
    private String keyword;       // 검색어 (제목, 주소)
    private String address;       // 지역

    // 2. 필터링
    private HouseType houseType;  // 주거 형태
    private Integer minPrice;     // 최소 월세
    private Integer maxPrice;     // 최대 월세

    // 3. 상세 조건 (새로 추가된 부분)
    private Integer minRoomCount;      // 방 개수 (최소 n개 이상)
    private Integer minBathroomCount;  // 화장실 개수 (최소 n개 이상)
    private Integer currentResidents;  // 현재 거주 인원 (정확히 n명)

    // 4. 옵션 (예: ["WIFI", "PARKING"])
    private List<String> homeRules;
    private List<String> features;
}