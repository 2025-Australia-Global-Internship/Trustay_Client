package com.maritel.trustay.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.maritel.trustay.dto.req.CommunityReq;
import com.maritel.trustay.dto.res.CommunityRes;
import com.maritel.trustay.service.CommunityService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.security.Principal;
import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(CommunityController.class)
@AutoConfigureMockMvc(addFilters = false)
class CommunityControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockBean
    CommunityService communityService;

    @MockBean
    com.maritel.trustay.config.CustomUserDetailsService customUserDetailsService;

    @Test
    @WithMockUser(username = "user@test.com")
    @DisplayName("POST /api/trustay/communities - 커뮤니티 생성")
    void createCommunity_success() throws Exception {
        CommunityReq req = new CommunityReq();
        req.setName("테스트 커뮤니티");
        req.setDescription("설명");
        CommunityRes res = CommunityRes.builder().id(1L).name(req.getName()).build();
        when(communityService.createCommunity(eq("user@test.com"), any())).thenReturn(res);

        mockMvc.perform(post("/api/trustay/communities")
                        .principal((Principal) () -> "user@test.com")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.name").value("테스트 커뮤니티"));
    }

    @Test
    @DisplayName("GET /api/trustay/communities - 커뮤니티 목록")
    void getCommunityList_success() throws Exception {
        when(communityService.getCommunityList(any(), any())).thenReturn(new PageImpl<>(List.of()));

        mockMvc.perform(get("/api/trustay/communities"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").isArray());
    }

    @Test
    @DisplayName("GET /api/trustay/communities/1 - 커뮤니티 상세")
    void getCommunityDetail_success() throws Exception {
        CommunityRes res = CommunityRes.builder().id(1L).name("커뮤니티").build();
        when(communityService.getCommunityDetail(1L)).thenReturn(res);

        mockMvc.perform(get("/api/trustay/communities/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(1));
    }

    @Test
    @WithMockUser(username = "user@test.com")
    @DisplayName("POST /api/trustay/communities/1/join - 커뮤니티 가입")
    void joinCommunity_success() throws Exception {
        mockMvc.perform(post("/api/trustay/communities/1/join")
                        .principal((Principal) () -> "user@test.com"))
                .andExpect(status().isOk());
        verify(communityService).joinCommunity(eq("user@test.com"), eq(1L));
    }

    @Test
    @WithMockUser(username = "user@test.com")
    @DisplayName("POST /api/trustay/communities/1/leave - 커뮤니티 탈퇴")
    void leaveCommunity_success() throws Exception {
        mockMvc.perform(post("/api/trustay/communities/1/leave")
                        .principal((Principal) () -> "user@test.com"))
                .andExpect(status().isOk());
        verify(communityService).leaveCommunity(eq("user@test.com"), eq(1L));
    }
}
