package com.maritel.trustay.controller;

import com.maritel.trustay.dto.req.ChatRoomCreateReq;
import com.maritel.trustay.dto.res.ChatMessageRes;
import com.maritel.trustay.dto.res.ChatRoomListRes;
import com.maritel.trustay.dto.res.DataResponse;
import com.maritel.trustay.service.ChatMessageService;
import com.maritel.trustay.service.ChatRoomService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatRoomController {

    private final ChatRoomService chatRoomService;
    private final ChatMessageService chatMessageService;

    // 채팅방 생성
    @PostMapping("/room")
    public DataResponse<Long> createRoom(@RequestBody ChatRoomCreateReq req) {
        return DataResponse.of(chatRoomService.createOrGetRoom(req));
    }

    @GetMapping("/room/{roomId}/messages/{memberId}")
    public DataResponse<List<ChatMessageRes>> getChatHistory(
            @PathVariable Long roomId,
            @PathVariable Long memberId) { // 읽는 사람의 ID를 추가로 받음
        return DataResponse.of(chatMessageService.getChatHistory(roomId, memberId));
    }

    // 나의 채팅방 목록 조회
    @GetMapping("/rooms/{memberId}")
    public DataResponse<List<ChatRoomListRes>> getRooms(@PathVariable Long memberId) {
        return DataResponse.of(chatRoomService.getMyChatRooms(memberId));
    }
}