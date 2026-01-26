package com.maritel.trustay.controller;

import com.maritel.trustay.dto.req.LoginReq;
import com.maritel.trustay.dto.req.OAuthLoginReq;
import com.maritel.trustay.dto.res.DataResponse;
import com.maritel.trustay.dto.res.LoginResultRes;
import com.maritel.trustay.dto.res.ResponseCode;
import com.maritel.trustay.service.AuthService;
import com.maritel.trustay.service.TokenBlacklistService;
import com.maritel.trustay.util.JwtUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Date;

@Slf4j
@RestController
@RequestMapping("/api/trustay/auth")
@Tag(name = "Auth API")
public class AuthController {

    private final JwtUtil jwtUtil;
    private final AuthService authService;
    private final TokenBlacklistService tokenBlacklistService;

    public AuthController(JwtUtil jwtUtil, AuthService authService, TokenBlacklistService tokenBlacklistService) {
        this.jwtUtil = jwtUtil;
        this.authService = authService;
        this.tokenBlacklistService = tokenBlacklistService;
    }

    @Operation(summary = "로그인")
    @PostMapping("/login")
    public ResponseEntity<DataResponse<LoginResultRes>> login(@RequestBody LoginReq req) {
        LoginResultRes res = new LoginResultRes();
        try {
            String token = this.authService.login(req);
            res.setToken(token);
            return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, res));
        } catch (RuntimeException e) {
            return ResponseEntity.ok(DataResponse.of(ResponseCode.NOT_FOUND, null));
        } catch (Exception e) {
            return ResponseEntity.ok(DataResponse.of(ResponseCode.NOT_MATCHED, null));
        }
    }

    @Operation(summary = "OAuth 로그인")
    @PostMapping("/oauth")
    public ResponseEntity<DataResponse<LoginResultRes>> oAuthLogin(@RequestBody OAuthLoginReq req) {
        LoginResultRes res = new LoginResultRes();
        try {
            String token = this.authService.OAuthLogin(req);
            res.setToken(token);
            return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, res));
        } catch (RuntimeException e) {
            return ResponseEntity.ok(DataResponse.of(ResponseCode.NOT_FOUND, null));
        } catch (Exception e) {
            return ResponseEntity.ok(DataResponse.of(ResponseCode.NOT_MATCHED, null));
        }
    }


    @Operation(summary = "로그아웃")
    @PostMapping("/logout")
    public ResponseEntity<DataResponse<Void>> logout(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            throw new IllegalArgumentException("토큰이 존재하지 않습니다.");
        }
        String token = header.substring(7);

        Date expirationDate = jwtUtil.getExpiration(token);
        long now = System.currentTimeMillis();

        if (expirationDate.getTime() > now) {
            tokenBlacklistService.blacklistToken(token, expirationDate.getTime());
        }

        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS));
    }
}