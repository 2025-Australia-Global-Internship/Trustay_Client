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
    @JoinColumn(name = "room_id", nullable = false)
    private ChatRoom chatRoom;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false)
    private Member sender;

    @Column(columnDefinition = "TEXT")
    private String message; // 메시지 내용 또는 파일 URL

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private MessageType messageType; // TEXT, IMAGE, CONTRACT

    @Column(nullable = false)
    private boolean isRead; // 읽음 확인

    /** 종이 계약 스캔(OCR·PDF) 문서와 연결 (CONTRACT 메시지용, 선택) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "paper_contract_doc_id")
    private PaperContractDocument paperContractDocument;

    @Builder
    public ChatMessage(ChatRoom chatRoom, Member sender, String message, MessageType messageType,
                        PaperContractDocument paperContractDocument) {
        this.chatRoom = chatRoom;
        this.sender = sender;
        this.message = message;
        this.messageType = messageType;
        this.paperContractDocument = paperContractDocument;
        this.isRead = false; // 기본값 미읽음
    }

    // 읽음 처리 메서드 추가
    public void markAsRead() {
        this.isRead = true;
    }
}