package com.maritel.trustay.controller;

import com.maritel.trustay.dto.req.ChatRoomCreateReq;
import com.maritel.trustay.dto.res.ChatMessageRes;
import com.maritel.trustay.dto.res.ChatRoomListRes;
import com.maritel.trustay.dto.res.DataResponse;
import com.maritel.trustay.service.ChatMessageService;
import com.maritel.trustay.service.ChatRoomService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ChatRoomControllerTest {

    @Mock
    private ChatRoomService chatRoomService;

    @Mock
    private ChatMessageService chatMessageService;

    private ChatRoomController chatRoomController;

    @BeforeEach
    void setUp() {
        chatRoomController = new ChatRoomController(chatRoomService, chatMessageService);
    }

    @Test
    void createRoom_returnsRoomId() {
        ChatRoomCreateReq req = new ChatRoomCreateReq();
        req.setHouseId(1L);
        req.setSenderId(10L);
        when(chatRoomService.createOrGetRoom(req)).thenReturn(100L);

        DataResponse<Long> response = chatRoomController.createRoom(req);

        assertEquals(200, response.getCode());
        assertEquals(100L, response.getData());
    }

    @Test
    void getChatHistory_returnsMessages() {
        when(chatMessageService.getChatHistory(1L, 10L)).thenReturn(List.of(ChatMessageRes.builder().messageId(1L).message("hello").build()));

        DataResponse<List<ChatMessageRes>> response = chatRoomController.getChatHistory(1L, 10L);

        assertEquals(200, response.getCode());
        assertNotNull(response.getData());
        assertEquals(1, response.getData().size());
    }

    @Test
    void getRooms_returnsMyChatRooms() {
        when(chatRoomService.getMyChatRooms(10L)).thenReturn(List.of(ChatRoomListRes.builder().roomId(1L).build()));

        DataResponse<List<ChatRoomListRes>> response = chatRoomController.getRooms(10L);

        assertEquals(200, response.getCode());
        assertEquals(1, response.getData().size());
    }

    @Test
    void leaveRoom_returnsSuccess() {
        doNothing().when(chatRoomService).leaveRoom(1L, 10L);

        DataResponse<Void> response = chatRoomController.leaveRoom(1L, 10L);

        assertEquals(200, response.getCode());
        verify(chatRoomService).leaveRoom(1L, 10L);
    }
}
