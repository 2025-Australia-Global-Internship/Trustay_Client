package com.maritel.trustay.repository;

import com.maritel.trustay.entity.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    // 특정 채팅방의 모든 메시지를 과거순(등록시간순)으로 조회
    // BaseEntity의 regTime을 기준으로 정렬합니다.
    List<ChatMessage> findByChatRoomIdOrderByRegTimeAsc(Long roomId);

    // (선택) 읽지 않은 메시지 개수 파악
    long countByChatRoomIdAndIsReadFalseAndSenderIdNot(Long roomId, Long memberId);
}