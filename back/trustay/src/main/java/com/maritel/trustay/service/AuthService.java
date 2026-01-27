package com.maritel.trustay.service;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.maritel.trustay.dto.req.LoginReq;
import com.maritel.trustay.dto.req.OAuthLoginReq;
import com.maritel.trustay.entity.Member;
import com.maritel.trustay.repository.MemberRepository;
import com.maritel.trustay.util.JwtUtil; // JwtUtil 추가
import lombok.RequiredArgsConstructor; // 생성자 주입 간소화
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService {

    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil; // JwtUtil 주입 받기

    @Transactional
    public String login(LoginReq req) {
        // 1. 회원 조회
        Member member = memberRepository.findByEmail(req.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        log.info("Try login member: {}", member.getName());

        // 2. 비밀번호 검증
        if (!passwordEncoder.matches(req.getPasswd(), member.getPasswd())) {
            throw new RuntimeException("Invalid Password");
        }

        // 3. 토큰 생성 (JwtUtil 사용으로 중복 코드 제거)
        return jwtUtil.generateToken(member.getEmail());
    }

    @Transactional
    public String OAuthLogin(OAuthLoginReq req) {
        String userEmail; String userName;
        try {
            userEmail = FirebaseAuth.getInstance().verifyIdToken(req.getFirebaseToken()).getEmail();
            userName = FirebaseAuth.getInstance().verifyIdToken(req.getFirebaseToken()).getName();
            log.info("User name: {}", userName);
            log.info("User email: {}", userEmail);
        } catch (FirebaseAuthException e) {
            throw new RuntimeException("Invalid Firebase Token", e);
        }
        memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return jwtUtil.generateToken(userEmail);
    }
}