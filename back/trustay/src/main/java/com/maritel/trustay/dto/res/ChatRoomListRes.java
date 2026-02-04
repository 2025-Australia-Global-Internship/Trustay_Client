package com.maritel.trustay.dto.res;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ChatRoomListRes {
    private Long roomId;
    private Long houseId;
    private String houseTitle;     // 매물 제목
    private String otherMemberName; // 상대방 이름 (내가 보낸사람이면 받는사람 이름, 반대면 보낸사람 이름)
    private String lastMessage;     // 마지막 메시지 내용
    private String lastSenderName;  // 마지막 메시지를 보낸 사람
    private String lastMessageTime; // 마지막 메시지 전송 시간
    private String profileImageUrl;

}