package com.maritel.trustay.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.maritel.trustay.dto.req.ChatRoomCreateReq;
import com.maritel.trustay.dto.res.ChatRoomListRes;
import com.maritel.trustay.service.ChatMessageService;
import com.maritel.trustay.service.ChatRoomService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ChatRoomController.class)
@AutoConfigureMockMvc(addFilters = false)
class ChatRoomControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockBean
    ChatRoomService chatRoomService;

    @MockBean
    ChatMessageService chatMessageService;

    @MockBean
    com.maritel.trustay.config.CustomUserDetailsService customUserDetailsService;

    @Test
    @DisplayName("POST /api/chat/room - 채팅방 생성")
    void createRoom_success() throws Exception {
        ChatRoomCreateReq req = new ChatRoomCreateReq();
        req.setHouseId(1L);
        req.setSenderId(2L);
        when(chatRoomService.createOrGetRoom(any())).thenReturn(1L);

        mockMvc.perform(post("/api/chat/room")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").value(1));
    }

    @Test
    @DisplayName("GET /api/chat/rooms/1 - 내 채팅방 목록")
    void getRooms_success() throws Exception {
        when(chatRoomService.getMyChatRooms(1L)).thenReturn(List.of(
                ChatRoomListRes.builder().roomId(1L).houseTitle("테스트 매물").build()
        ));

        mockMvc.perform(get("/api/chat/rooms/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].roomId").value(1));
    }

    @Test
    @DisplayName("POST /api/chat/room/1/leave - 채팅방 나가기")
    void leaveRoom_success() throws Exception {
        mockMvc.perform(post("/api/chat/room/1/leave")
                        .param("memberId", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200));
        verify(chatRoomService).leaveRoom(1L, 2L);
    }
}
