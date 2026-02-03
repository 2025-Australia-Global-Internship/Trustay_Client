package com.maritel.trustay.dto.res;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class WishToggleRes {
    private Long sharehouseId;
    private boolean wished; // true: 찜 함, false: 찜 해제
}
