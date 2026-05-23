package com.maritel.trustay.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.maritel.trustay.dto.req.LoginReq;
import com.maritel.trustay.dto.req.OAuthLoginReq;
import com.maritel.trustay.service.AuthService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@AutoConfigureMockMvc(addFilters = false)
class AuthControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockBean
    AuthService authService;

    @MockBean
    com.maritel.trustay.service.TokenBlacklistService tokenBlacklistService;

    @MockBean
    com.maritel.trustay.util.JwtUtil jwtUtil;

    @Test
    @DisplayName("POST /api/trustay/auth/login - 로그인 성공")
    void login_success() throws Exception {
        LoginReq req = new LoginReq("test@test.com", "Password1!");
        when(authService.login(any())).thenReturn("jwt-token");

        mockMvc.perform(post("/api/trustay/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token").value("jwt-token"))
                .andExpect(jsonPath("$.code").value(200));
    }

    @Test
    @DisplayName("POST /api/trustay/auth/oauth - OAuth 로그인 성공")
    void oauthLogin_success() throws Exception {
        OAuthLoginReq req = new OAuthLoginReq("firebase-id-token");
        when(authService.OAuthLogin(any())).thenReturn("jwt-token");

        mockMvc.perform(post("/api/trustay/auth/oauth")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token").value("jwt-token"));
    }
}
