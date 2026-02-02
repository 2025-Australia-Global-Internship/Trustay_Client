package com.maritel.trustay.dto.req;

import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class ChatRoomCreateReq {
    private Long houseId;   // 어떤 매물을 보고 문의하는지
    private Long senderId;  // 채팅을 거는 사람 (현재 로그인 유저 ID)
}