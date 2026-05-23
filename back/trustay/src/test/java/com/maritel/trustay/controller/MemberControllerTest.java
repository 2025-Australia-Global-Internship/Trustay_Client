package com.maritel.trustay.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.maritel.trustay.dto.req.SignupReq;
import com.maritel.trustay.dto.res.ProfileRes;
import com.maritel.trustay.service.MemberService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.security.Principal;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(MemberController.class)
@AutoConfigureMockMvc(addFilters = false)
class MemberControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockBean
    MemberService memberService;

    @MockBean
    com.maritel.trustay.config.CustomUserDetailsService customUserDetailsService;

    @Test
    @DisplayName("POST /api/trustay/members/signup - 회원가입 성공")
    void signup_success() throws Exception {
        SignupReq req = SignupReq.builder()
                .name("테스트유저")
                .email("test@test.com")
                .passwd("Password1!")
                .build();

        mockMvc.perform(post("/api/trustay/members/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200));
        verify(memberService).signup(any());
    }

    @Test
    @WithMockUser(username = "test@test.com")
    @DisplayName("GET /api/trustay/members/profile - 프로필 조회")
    void getProfile_success() throws Exception {
        ProfileRes res = ProfileRes.builder()
                .email("test@test.com")
                .name("테스트유저")
                .build();
        when(memberService.getProfile(eq("test@test.com"))).thenReturn(res);

        mockMvc.perform(get("/api/trustay/members/profile")
                        .principal((Principal) () -> "test@test.com"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.email").value("test@test.com"));
    }
}
