package com.maritel.trustay.dto.res;

import com.maritel.trustay.constant.MessageType;
import com.maritel.trustay.entity.ChatMessage;
import lombok.*;
import org.checkerframework.checker.units.qual.A;

import java.time.LocalDateTime;

@Getter
@Builder
@AllArgsConstructor
public class ChatMessageRes {
    private Long messageId;
    private Long senderId;
    private String senderName; // 화면에 표시할 이름
    private String message;
    private MessageType messageType;
    private LocalDateTime regTime; // BaseEntity의 생성 시간

    public static ChatMessageRes of(ChatMessage entity) {
        return ChatMessageRes.builder()
                .messageId(entity.getId())
                .senderId(entity.getSender().getId())
                .senderName(entity.getSender().getName())
                .message(entity.getMessage())
                .messageType(entity.getMessageType())
                .regTime(entity.getRegTime()) // BaseEntity 필드 사용
                .build();
    }
}
