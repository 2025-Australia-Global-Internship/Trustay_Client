package com.maritel.trustay.service;

import com.maritel.trustay.constant.Role;
import com.maritel.trustay.dto.req.SignupReq;
import com.maritel.trustay.dto.req.ProfileUpdateReq;
import com.maritel.trustay.dto.res.ProfileRes;
import com.maritel.trustay.entity.Member;
import com.maritel.trustay.entity.Profile;
import com.maritel.trustay.repository.MemberRepository;
import com.maritel.trustay.repository.ProfileRepository;
import com.maritel.trustay.service.FileService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashSet;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MemberService {

    private final MemberRepository memberRepository;
    private final ProfileRepository profileRepository;
    private final PasswordEncoder passwordEncoder;
    private final FileService fileService;

    /**
     * 1. 회원가입 (이름, 이메일, 비밀번호만)
     */
    @Transactional
    public void signup(SignupReq dto) {
        // 1. 이메일 중복 검사
        if (memberRepository.findByEmail(dto.getEmail()).isPresent()) {
            throw new IllegalStateException("이미 존재하는 이메일입니다.");
        }

        // 2. Member 저장
        Member member = Member.builder()
                .email(dto.getEmail())
                .passwd(passwordEncoder.encode(dto.getPasswd()))
                .name(dto.getName())
                .build();

        memberRepository.save(member);

        // 3. Profile 자동 생성 (기본 권한: TENANT)
        Set<Role> roles = new HashSet<>();
        roles.add(Role.TENANT); // 기본은 세입자

        Profile profile = Profile.builder()
                .member(member)
                .roles(roles) // Set 전달
                .build();

        profileRepository.save(profile);
    }

    /**
     * 2. 프로필 조회
     */
    public ProfileRes getProfile(String email) {
        Member member = memberRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("회원을 찾을 수 없습니다."));

        return ProfileRes.from(member);
    }

    /**
     * 3-1. 프로필 정보 수정 (전화번호, 생일, 계좌)
     */
    @Transactional
    public void updateProfileInfo(String email, ProfileUpdateReq dto) {
        Member member = memberRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("회원을 찾을 수 없습니다."));

        Profile profile = member.getProfile();

        if (profile == null) {
            // 방어 코드: 프로필이 없는 경우 새로 생성
            profile = Profile.builder()
                    .member(member)
                    .build();
            profileRepository.save(profile);
        }

        // 전화번호, 생일 수정
        if (dto.getPhone() != null || dto.getBirth() != null) {
            profile.updateProfile(dto.getPhone(), dto.getBirth());
        }

        // 계좌 정보 수정
        if (dto.getAccountInfo() != null) {
            profile.updateAccountInfo(dto.getAccountInfo());
        }

        log.info("프로필 정보 수정 완료: {}", email);
    }

    /**
     * 3-2. 프로필 이미지 업로드
     */
    @Transactional
    public void updateProfileImage(String email, MultipartFile profileImage) {
        Member member = memberRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("회원을 찾을 수 없습니다."));

        Profile profile = member.getProfile();

        if (profile == null) {
            // 방어 코드: 프로필이 없는 경우 새로 생성
            profile = Profile.builder()
                    .member(member)
                    .build();
            profileRepository.save(profile);
        }

        // 프로필 이미지 업로드 처리
        if (profileImage == null || profileImage.isEmpty()) {
            throw new IllegalArgumentException("프로필 이미지가 제공되지 않았습니다.");
        }

        try {
            String uploadedUrl = fileService.uploadFile(profileImage);
            if (uploadedUrl == null) {
                throw new RuntimeException("지원하지 않는 파일 형식입니다. (jpg, jpeg, png만 가능)");
            }
            profile.updateProfileImage(uploadedUrl);
            log.info("프로필 이미지 업로드 완료: {}", uploadedUrl);
        } catch (Exception e) {
            log.error("프로필 이미지 업로드 실패", e);
            throw new RuntimeException("프로필 이미지 업로드에 실패했습니다: " + e.getMessage());
        }
    }
}