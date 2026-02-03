package com.maritel.trustay.service;

import com.maritel.trustay.dto.req.ChatMessageReq;
import com.maritel.trustay.dto.res.ChatMessageRes;
import com.maritel.trustay.entity.ChatMessage;
import com.maritel.trustay.entity.ChatRoom;
import com.maritel.trustay.entity.Member;
import com.maritel.trustay.repository.ChatMessageRepository;
import com.maritel.trustay.repository.ChatRoomRepository;
import com.maritel.trustay.repository.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional; // 이 임포트인지 확인하세요!

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional // 기본적으로 쓰기 가능하게 설정
public class ChatMessageService {
    private final ChatMessageRepository chatMessageRepository;
    private final ChatRoomRepository chatRoomRepository;
    private final MemberRepository memberRepository;

    // 메시지 저장 (보내기)
    public ChatMessageRes saveMessage(ChatMessageReq req) {
        ChatRoom room = chatRoomRepository.findById(req.getRoomId())
                .orElseThrow(() -> new EntityNotFoundException("채팅방이 존재하지 않습니다."));

        Member sender = memberRepository.findById(req.getSenderId())
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다."));

        ChatMessage chatMessage = ChatMessage.builder()
                .chatRoom(room)
                .sender(sender)
                .message(req.getMessage())
                .messageType(req.getMessageType())
                .build();

        chatMessageRepository.save(chatMessage);
        return ChatMessageRes.of(chatMessage);
    }

    // 대화 내역 조회 및 읽음 처리 (읽기)
    public List<ChatMessageRes> getChatHistory(Long roomId, Long readerId) {
        List<ChatMessage> messages = chatMessageRepository.findByChatRoomIdOrderByRegTimeAsc(roomId);

        // 읽음 처리 로직: 내가 아닌 상대방이 보낸 안 읽은 메시지들을 모두 읽음 처리
        messages.stream()
                .filter(m -> !m.getSender().getId().equals(readerId) && !m.isRead())
                .forEach(ChatMessage::markAsRead); // Dirty Checking으로 자동 업데이트

        return messages.stream()
                .map(ChatMessageRes::of)
                .collect(Collectors.toList());
    }
}