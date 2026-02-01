package com.maritel.trustay.controller;

import com.maritel.trustay.dto.req.ChatMessageReq;
import com.maritel.trustay.dto.res.ChatMessageRes;
import com.maritel.trustay.service.ChatMessageService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class ChatStompController {

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatMessageService chatMessageService;


    @MessageMapping("/chat/send")
    public void sendMessage(@Payload ChatMessageReq req) {
        // 클라이언트가 전송한 JSON이 ChatMessageReq로 매핑됨
        ChatMessageRes res = chatMessageService.saveMessage(req);

        // 응답 역시 JSON으로 변환되어 구독자들에게 전달됨
        messagingTemplate.convertAndSend("/sub/chat/room/" + req.getRoomId(), res);
    }
}
