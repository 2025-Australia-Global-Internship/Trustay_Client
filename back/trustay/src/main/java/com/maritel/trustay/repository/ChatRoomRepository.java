package com.maritel.trustay.repository;

import com.maritel.trustay.entity.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {

    // 내가 참여 중인(보낸 사람 혹은 받는 사람) 채팅방 목록 조회
    List<ChatRoom> findBySenderIdOrReceiverId(Long senderId, Long receiverId);

    // 특정 매물에 대해 두 사람 사이의 채팅방이 이미 존재하는지 확인
    Optional<ChatRoom> findBySharehouseIdAndSenderIdAndReceiverId(Long houseId, Long senderId, Long receiverId);
}