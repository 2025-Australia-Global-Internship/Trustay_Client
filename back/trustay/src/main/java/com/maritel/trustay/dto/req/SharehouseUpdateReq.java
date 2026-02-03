package com.maritel.trustay.dto.req;

import com.maritel.trustay.constant.HouseType;
import com.maritel.trustay.constant.BondType;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class SharehouseUpdateReq {
    private String title;
    private String description;
    private Integer rentPrice;
    private String options;
    private Integer roomCount;
    private Integer bathroomCount;
    private Integer currentResidents;
    private HouseType houseType;
    private Boolean billsIncluded;
    private String roomType;
    private BondType bondType;
    private Integer minimumStay;
    private String gender;
    private String age;
    private String religion;       // 선택
    private String dietaryPreference; // 선택
}