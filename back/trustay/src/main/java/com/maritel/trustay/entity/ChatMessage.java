package com.maritel.trustay.entity;

import com.maritel.trustay.constant.MessageType;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "TBL_CHAT_MESSAGE")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ChatMessage extends BaseEntity { // BaseEntity 상속으로 변경

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "message_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id")
    private ChatRoom chatRoom;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id")
    private Member sender;

    @Column(columnDefinition = "TEXT")
    private String message; // 메시지 내용 또는 파일 URL

    @Enumerated(EnumType.STRING)
    private MessageType messageType; // TEXT, IMAGE, CONTRACT

    private boolean isRead; // 읽음 확인

    @Builder
    public ChatMessage(ChatRoom chatRoom, Member sender, String message, MessageType messageType) {
        this.chatRoom = chatRoom;
        this.sender = sender;
        this.message = message;
        this.messageType = messageType;
        this.isRead = false; // 기본값 미읽음
    }

    // 읽음 처리 메서드 추가
    public void markAsRead() {
        this.isRead = true;
    }
}