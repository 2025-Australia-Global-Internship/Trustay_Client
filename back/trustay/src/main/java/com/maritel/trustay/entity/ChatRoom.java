package com.maritel.trustay.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnDefault;

@Entity
@Table(name = "TBL_CHAT_ROOM")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ChatRoom extends BaseEntity {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "room_id")
    private Long id;

    // 어떤 매물에 대한 문의인지 연결 (선택사항이지만 있으면 좋음)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "house_id")
    private Sharehouse sharehouse;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id") // 채팅을 먼저 건 사람 (보통 세입자)
    private Member sender;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receiver_id") // 받는 사람 (보통 집주인)
    private Member receiver;

    @ColumnDefault("false")
    private Boolean leftBySender = false;

    @ColumnDefault("false")
    private Boolean leftByReceiver = false;

    @Builder
    public ChatRoom(Sharehouse sharehouse, Member sender, Member receiver) {
        this.sharehouse = sharehouse;
        this.sender = sender;
        this.receiver = receiver;
        this.leftBySender = false;
        this.leftByReceiver = false;
    }

    public void leaveBySender() {
        this.leftBySender = true;
    }

    public void leaveByReceiver() {
        this.leftByReceiver = true;
    }
}