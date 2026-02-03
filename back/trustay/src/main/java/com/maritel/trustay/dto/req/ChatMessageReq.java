package com.maritel.trustay.dto.req;


import com.maritel.trustay.constant.MessageType;
import lombok.*;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ChatMessageReq {
    private Long roomId;
    private Long senderId;
    private String message; // 텍스트 내용 또는 FileService가 준 URL
    private MessageType messageType; // TEXT, IMAGE, CONTRACT
}
