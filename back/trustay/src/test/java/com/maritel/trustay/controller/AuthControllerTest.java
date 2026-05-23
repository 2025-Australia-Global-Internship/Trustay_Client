package com.maritel.trustay.controller;

import com.maritel.trustay.dto.req.LoginReq;
import com.maritel.trustay.dto.req.OAuthLoginReq;
import com.maritel.trustay.dto.res.DataResponse;
import com.maritel.trustay.service.AuthService;
import com.maritel.trustay.service.TokenBlacklistService;
import com.maritel.trustay.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;

import java.util.Date;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verifyNoInteractions;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

  @Mock
    private JwtUtil jwtUtil;

  @Mock
    private AuthService authService;

  @Mock
    private TokenBlacklistService tokenBlacklistService;

  @InjectMocks
  private AuthController authController;

    @Test
    void login_success_returnsSuccessResponse() throws Exception {
        when(authService.login(any(LoginReq.class))).thenReturn("mock-jwt-token");

    ResponseEntity<DataResponse<com.maritel.trustay.dto.res.LoginResultRes>> response =
        authController.login(new LoginReq("user@example.com", "Password1!"));

    assertNotNull(response.getBody());
    assertEquals(200, response.getBody().getCode());
    assertEquals("mock-jwt-token", response.getBody().getData().getToken());
    }

    @Test
    void login_whenRuntimeException_returnsNotFoundCode() throws Exception {
        doThrow(new RuntimeException("User not found")).when(authService).login(any(LoginReq.class));

    ResponseEntity<DataResponse<com.maritel.trustay.dto.res.LoginResultRes>> response =
        authController.login(new LoginReq("none@example.com", "Password1!"));

    assertNotNull(response.getBody());
    assertEquals(404, response.getBody().getCode());
  }

  @Test
  void oauth_success_returnsSuccessResponse() {
    when(authService.OAuthLogin(any(OAuthLoginReq.class))).thenReturn("oauth-token");

    ResponseEntity<DataResponse<com.maritel.trustay.dto.res.LoginResultRes>> response =
        authController.oAuthLogin(new OAuthLoginReq("firebase-token"));

    assertNotNull(response.getBody());
    assertEquals(200, response.getBody().getCode());
    assertEquals("oauth-token", response.getBody().getData().getToken());
    }

    @Test
    void logout_withValidBearerToken_blacklistsToken() throws Exception {
        String token = "valid-token";
        long future = System.currentTimeMillis() + 60_000;
        when(jwtUtil.getExpiration(token)).thenReturn(new Date(future));
    HttpServletRequest request = org.mockito.Mockito.mock(HttpServletRequest.class);
    when(request.getHeader("Authorization")).thenReturn("Bearer " + token);

    ResponseEntity<DataResponse<Void>> response = authController.logout(request);

    assertNotNull(response.getBody());
    assertEquals(200, response.getBody().getCode());
        verify(tokenBlacklistService).blacklistToken(eq(token), eq(future));
    }

    @Test
  void logout_whenTokenAlreadyExpired_doesNotBlacklist() {
        String token = "expired-token";
        long past = System.currentTimeMillis() - 60_000;
        when(jwtUtil.getExpiration(token)).thenReturn(new Date(past));
    HttpServletRequest request = org.mockito.Mockito.mock(HttpServletRequest.class);
    when(request.getHeader("Authorization")).thenReturn("Bearer " + token);

    ResponseEntity<DataResponse<Void>> response = authController.logout(request);

    assertNotNull(response.getBody());
    assertEquals(200, response.getBody().getCode());
        verifyNoInteractions(tokenBlacklistService);
    }

  @Test
  void logout_withoutBearerToken_throwsException() {
    HttpServletRequest request = org.mockito.Mockito.mock(HttpServletRequest.class);
    when(request.getHeader("Authorization")).thenReturn(null);

    IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> authController.logout(request));
    assertEquals("토큰이 존재하지 않습니다.", ex.getMessage());
  }
}
