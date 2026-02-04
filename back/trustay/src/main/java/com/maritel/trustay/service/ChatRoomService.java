package com.maritel.trustay.service;

import com.maritel.trustay.dto.req.ChatRoomCreateReq;
import com.maritel.trustay.dto.res.ChatRoomListRes;
import com.maritel.trustay.entity.ChatMessage;
import com.maritel.trustay.entity.ChatRoom;
import com.maritel.trustay.entity.Member;
import com.maritel.trustay.entity.Sharehouse;
import com.maritel.trustay.repository.ChatMessageRepository;
import com.maritel.trustay.repository.ChatRoomRepository;
import com.maritel.trustay.repository.MemberRepository;
import com.maritel.trustay.repository.SharehouseRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class ChatRoomService {

    private final ChatRoomRepository chatRoomRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final MemberRepository memberRepository;
    private final SharehouseRepository sharehouseRepository;

    // 1. 채팅방 생성 (이미 있으면 기존 방 반환)
    public Long createOrGetRoom(ChatRoomCreateReq req) {
        Sharehouse house = sharehouseRepository.findById(req.getHouseId())
                .orElseThrow(() -> new EntityNotFoundException("매물을 찾을 수 없습니다."));

        Member sender = memberRepository.findById(req.getSenderId())
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다."));

        Member host = house.getHost(); // 매물 주인

        // 본인 매물에 본인이 채팅하는 것 방지 (선택 사항)
        if (sender.getId().equals(host.getId())) {
            throw new IllegalArgumentException("자신의 매물에는 채팅을 보낼 수 없습니다.");
        }

        // 이미 생성된 방이 있는지 확인
        Optional<ChatRoom> existingRoom = chatRoomRepository
                .findBySharehouse_IdAndSender_IdAndReceiver_Id(house.getId(), sender.getId(), host.getId());

        if (existingRoom.isPresent()) {
            return existingRoom.get().getId();
        }

        // 새 방 생성
        ChatRoom newRoom = ChatRoom.builder()
                .sharehouse(house)
                .sender(sender)
                .receiver(host)
                .build();

        return chatRoomRepository.save(newRoom).getId();
    }

    // 2. 참여 중인 채팅방 목록 조회 (나가지 않은 방만, 마지막 메시지 포함)
    @Transactional(readOnly = true)
    public List<ChatRoomListRes> getMyChatRooms(Long memberId) {
        List<ChatRoom> rooms = chatRoomRepository.findActiveRoomsByMemberId(memberId);

        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다."));

        return rooms.stream().map(room -> {
            // 마지막 메시지 조회 (방 번호로 메시지 중 가장 최근 것 하나)
            // ChatMessageRepository에 별도 쿼리 작성이 필요할 수 있으나, 기본 List 조회 후 처리
            List<ChatMessage> messages = chatMessageRepository.findByChatRoomIdOrderByRegTimeAsc(room.getId());
            ChatMessage lastMsg = messages.isEmpty() ? null : messages.get(messages.size() - 1);

            // 상대방 찾기
            Member other = room.getSender().getId().equals(memberId) ? room.getReceiver() : room.getSender();

            return ChatRoomListRes.builder()
                    .roomId(room.getId())
                    .houseId(room.getSharehouse().getId())
                    .houseTitle(room.getSharehouse().getTitle())
                    .otherMemberName(other.getName())
                    .lastMessage(lastMsg != null ? lastMsg.getMessage() : "대화 내용이 없습니다.")
                    .lastSenderName(lastMsg != null ? lastMsg.getSender().getName() : "")
                    .lastMessageTime(lastMsg != null ? lastMsg.getRegTime().toString() : "")
                    .profileImageUrl(member != null ? member.getProfile().getProfileImage().getImageUrl() : "")
                    .build();
        }).collect(Collectors.toList());
    }

    // 3. 채팅방 나가기
    public void leaveRoom(Long roomId, Long memberId) {
        ChatRoom room = chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("채팅방을 찾을 수 없습니다."));
        if (room.getSender().getId().equals(memberId)) {
            room.leaveBySender();
        } else if (room.getReceiver().getId().equals(memberId)) {
            room.leaveByReceiver();
        } else {
            throw new IllegalArgumentException("해당 채팅방의 참여자가 아닙니다.");
        }
    }
}