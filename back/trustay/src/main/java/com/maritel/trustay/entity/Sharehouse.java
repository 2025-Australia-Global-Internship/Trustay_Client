package com.maritel.trustay.entity;

import com.maritel.trustay.constant.ApprovalStatus;
import com.maritel.trustay.constant.HouseType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnDefault;

@Entity
@Table(name = "TBL_SHAREHOUSE")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Sharehouse extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "house_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "host_id") // 집주인 Member ID
    private Member host;

    // --- 기본 정보 ---
    @Column(nullable = false, length = 100)
    private String title;

    @Lob // 대용량 텍스트
    private String description;

    @Column(nullable = false)
    private String address;

    @Column(nullable = false)
    @ColumnDefault("0") // DB 생성 시 기본값 0
    private Integer viewCount = 0;

    // --- 위치 정보 ---
    private Double latitude;  // 위도
    private Double longitude; // 경도

    // --- 매물 상세 정보 ---
    @Enumerated(EnumType.STRING)
    private HouseType houseType; // APARTMENT, HOUSE, UNIT...

    private Integer rentPrice; // 렌트비
    private Integer deposit;   // 보증금

    private Integer roomCount;
    private Integer bathroomCount;
    private Integer currentResidents; // 현재 거주 인원

    // 옵션 (JSON 문자열 또는 콤마 구분)
    @Column(columnDefinition = "TEXT")
    private String options;

    // 이미지 URL들 (콤마로 구분하여 저장)
    @Column(columnDefinition = "TEXT")
    private String imageUrls;

    // --- 관리 정보 ---
    @Enumerated(EnumType.STRING)
    private ApprovalStatus approvalStatus; // PENDING, ACTIVE, REJECTED

    @Builder
    public Sharehouse(Member host, String title, String description, String address,
                      Double latitude, Double longitude,
                      HouseType houseType, Integer rentPrice, Integer deposit,
                      Integer roomCount, Integer bathroomCount, Integer currentResidents,
                      String options, String imageUrls, ApprovalStatus approvalStatus) {
        this.host = host;
        this.title = title;
        this.description = description;
        this.address = address;
        this.latitude = latitude;
        this.longitude = longitude;
        this.houseType = houseType;
        this.rentPrice = rentPrice;
        this.deposit = deposit;
        this.roomCount = roomCount;
        this.bathroomCount = bathroomCount;
        this.currentResidents = currentResidents;
        this.options = options;
        this.imageUrls = imageUrls;
        this.approvalStatus = approvalStatus;
        this.viewCount = 0;
    }

    public void updateSharehouse(String title, String description, Integer rentPrice,
                                 Integer deposit, String options, Integer roomCount,
                                 Integer bathroomCount, Integer currentResidents, HouseType houseType) {
        this.title = title;
        this.description = description;
        this.rentPrice = rentPrice;
        this.deposit = deposit;
        this.options = options;
        this.roomCount = roomCount;
        this.bathroomCount = bathroomCount;
        this.currentResidents = currentResidents;
        this.houseType = houseType;
    }

    // --- 승인 상태 변경 메서드 ---
    public void changeApprovalStatus(ApprovalStatus status) {
        this.approvalStatus = status;
    }
}