package com.maritel.trustay.entity;

import com.maritel.trustay.constant.ApprovalStatus;
import com.maritel.trustay.constant.HouseType;
import com.maritel.trustay.constant.RoomType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

@Entity
@Table(name = "TBL_SHAREHOUSE")
@Check(constraints = "view_count >= 0 AND wish_count >= 0 AND rent_price > 0")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Sharehouse extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "house_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "host_id", nullable = false) // 집주인 Member ID
    private Member host;

    // --- 기본 정보 ---
    @Column(nullable = false, length = 100)
    private String title;

    @Lob // 대용량 텍스트
    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, length = 255)
    private String address;

    @Column(nullable = false)
    @ColumnDefault("0") // DB 생성 시 기본값 0
    private Integer viewCount = 0;

    @Column(nullable = false)
    @ColumnDefault("0")
    private Integer wishCount = 0; // 찜 개수

    // --- 위치 정보 ---
    private Double latitude;  // 위도
    private Double longitude; // 경도

    // --- 매물 상세 정보 ---
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private HouseType houseType; // APARTMENT, HOUSE, UNIT...

    @Column(nullable = false)
    private Integer rentPrice; // 렌트비

    private Integer roomCount;
    private Integer bathroomCount;
    private Integer currentResidents; // 현재 거주 인원

    @Column(name = "bills_included", nullable = false)
    private Boolean billsIncluded; // Bills Included


    @Enumerated(EnumType.STRING)
    @Column(name = "room_type")
    private RoomType roomType; // Room Type (e.g. Single, Double)

    @Column(name = "bond_type", nullable = false)
    private Integer bondType; // 2weeks, 4weeks, custom

    @Column(name = "minimum_stay", nullable = false)
    private Integer minimumStay; // Minimum Stay (e.g. weeks)

    @Column(nullable = false, length = 50)
    private String gender; // 선호 성별

    @Column(nullable = false, length = 50)
    private String age; // 선호 연령

    @Column(length = 100)
    private String religion; // 종교 (선택)

    @Column(name = "dietary_preference", length = 200)
    private String dietaryPreference; // 식이 선호 (선택)


    // 옵션 (JSON 문자열 또는 콤마 구분)
    @Column(columnDefinition = "TEXT")
    private String homeRules;

    @Column(columnDefinition = "TEXT")
    private String features;

    // --- 관리 정보 ---
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private ApprovalStatus approvalStatus; // PENDING, ACTIVE, REJECTED

    @Builder
    public Sharehouse(Member host, String title, String description, String address,
                      Double latitude, Double longitude, HouseType houseType,
                      Integer rentPrice, Integer roomCount,
                      Integer bathroomCount, Integer currentResidents,
                      String homeRules, String features, Boolean billsIncluded, RoomType roomType,
                      Integer bondType, Integer minimumStay, String gender, String age,
                      String religion, String dietaryPreference, ApprovalStatus approvalStatus) {
        this.host = host;
        this.title = title;
        this.description = description;
        this.address = address;
        this.latitude = latitude;
        this.longitude = longitude;
        this.houseType = houseType;
        this.rentPrice = rentPrice;
        this.roomCount = roomCount;
        this.bathroomCount = bathroomCount;
        this.currentResidents = currentResidents;
        this.homeRules = homeRules;
        this.features = features;
        this.billsIncluded = billsIncluded;
        this.roomType = roomType;
        this.bondType = bondType;
        this.minimumStay = minimumStay;
        this.gender = gender;
        this.age = age;
        this.religion = religion;
        this.dietaryPreference = dietaryPreference;
        this.approvalStatus = approvalStatus;
        this.viewCount = 0;
        this.wishCount = 0;
    }

    public void increaseWishCount() {
        this.wishCount = (this.wishCount == null ? 0 : this.wishCount) + 1;
    }

    public void decreaseWishCount() {
        if (this.wishCount != null && this.wishCount > 0) {
            this.wishCount--;
        }
    }

    public void updateSharehouse(String title, String description, Integer rentPrice, String homeRules,
                                 String features, Integer roomCount, Integer bathroomCount,
                                 Integer currentResidents, HouseType houseType,
                                 Boolean billsIncluded, RoomType roomType, Integer bondType,
                                 Integer minimumStay, String gender, String age,
                                 String religion, String dietaryPreference) {
        this.title = title;
        this.description = description;
        this.rentPrice = rentPrice;
        this.homeRules = homeRules;
        this.features = features;
        this.roomCount = roomCount;
        this.bathroomCount = bathroomCount;
        this.currentResidents = currentResidents;
        this.houseType = houseType;
        this.billsIncluded = billsIncluded;
        this.roomType = roomType;
        this.bondType = bondType;
        this.minimumStay = minimumStay;
        this.gender = gender;
        this.age = age;
        this.religion = religion;
        this.dietaryPreference = dietaryPreference;
    }

    // --- 승인 상태 변경 메서드 ---
    public void changeApprovalStatus(ApprovalStatus status) {
        this.approvalStatus = status;
    }
}