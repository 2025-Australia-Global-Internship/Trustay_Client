package com.maritel.trustay.dto.res;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
@AllArgsConstructor
public class DutchPayCreateRes {
    private Long dutchPayGroupId;
    private List<DutchPaySplitItemRes> splits;
    private String settlementGuide;
}
