package com.maritel.trustay.dto.res;

import com.maritel.trustay.constant.MessageType;
import com.maritel.trustay.entity.ChatMessage;
import lombok.*;

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
    /** CONTRACT 메시지가 스캔 문서와 연결된 경우 */
    private Long paperContractDocumentId;

    public static ChatMessageRes of(ChatMessage entity) {
        Long docId = entity.getPaperContractDocument() != null
                ? entity.getPaperContractDocument().getId()
                : null;
        return ChatMessageRes.builder()
                .messageId(entity.getId())
                .senderId(entity.getSender().getId())
                .senderName(entity.getSender().getName())
                .message(entity.getMessage())
                .messageType(entity.getMessageType())
                .regTime(entity.getRegTime()) // BaseEntity 필드 사용
                .paperContractDocumentId(docId)
                .build();
    }
}
