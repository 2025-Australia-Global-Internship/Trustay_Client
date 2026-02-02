package com.maritel.trustay.repository;

import com.maritel.trustay.entity.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {

    // 내가 참여 중이고 아직 나가지 않은 채팅방 목록 조회
    @Query("SELECT r FROM ChatRoom r WHERE (r.sender.id = :memberId AND (r.leftBySender = false OR r.leftBySender IS NULL)) " +
            "OR (r.receiver.id = :memberId AND (r.leftByReceiver = false OR r.leftByReceiver IS NULL))")
    List<ChatRoom> findActiveRoomsByMemberId(@Param("memberId") Long memberId);

    // 특정 매물에 대해 두 사람 사이의 채팅방이 이미 존재하는지 확인
    Optional<ChatRoom> findBySharehouse_IdAndSender_IdAndReceiver_Id(Long houseId, Long senderId, Long receiverId);
}