package com.maritel.trustay.controller;

import com.maritel.trustay.constant.MessageType;
import com.maritel.trustay.dto.req.ChatMessageReq;
import com.maritel.trustay.dto.res.ChatMessageRes;
import com.maritel.trustay.service.ChatMessageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ChatStompControllerTest {

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    @Mock
    private ChatMessageService chatMessageService;

    private ChatStompController chatStompController;

    @BeforeEach
    void setUp() {
        chatStompController = new ChatStompController(messagingTemplate, chatMessageService);
    }

    @Test
    void sendMessage_savesAndBroadcastsToRoomTopic() {
        ChatMessageReq req = new ChatMessageReq(1L, 10L, "hello", MessageType.TEXT);
        ChatMessageRes saved = ChatMessageRes.builder().messageId(100L).message("hello").build();
        when(chatMessageService.saveMessage(req)).thenReturn(saved);

        chatStompController.sendMessage(req);

        verify(chatMessageService).saveMessage(req);
        verify(messagingTemplate).convertAndSend(eq("/sub/chat/room/1"), eq(saved));
    }
}
