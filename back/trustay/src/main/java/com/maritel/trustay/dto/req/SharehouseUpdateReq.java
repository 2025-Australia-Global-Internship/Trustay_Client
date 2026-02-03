package com.maritel.trustay.dto.req;

import com.maritel.trustay.constant.HouseType;
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
}