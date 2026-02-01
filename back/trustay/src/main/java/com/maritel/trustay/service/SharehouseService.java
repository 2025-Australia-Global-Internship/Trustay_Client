package com.maritel.trustay.service;

import com.maritel.trustay.constant.ApprovalStatus;
import com.maritel.trustay.constant.Role;
import com.maritel.trustay.dto.req.SharehouseReq;
import com.maritel.trustay.dto.req.SharehouseSearchReq;
import com.maritel.trustay.dto.req.SharehouseUpdateReq;
import com.maritel.trustay.dto.res.SharehouseRes;
import com.maritel.trustay.dto.res.SharehouseResultRes;
import com.maritel.trustay.entity.Member;
import com.maritel.trustay.entity.Sharehouse;
import com.maritel.trustay.repository.MemberRepository;
import com.maritel.trustay.repository.SharehouseRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.Map;


@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SharehouseService {

    private final SharehouseRepository sharehouseRepository;
    private final MemberRepository memberRepository;
    private final GeocodingService geocodingService; // 1. 주입 추가


    /**
     * 내 목록에서 쉐어하우스 상세 조회하기
     * @param houseId
     * @return
     */
    public SharehouseResultRes getMySharehouseDetail(@PathVariable Long houseId) {
        Sharehouse sharehouse = sharehouseRepository.findById(houseId)
                .orElseThrow(() -> new IllegalArgumentException("해당 쉐어하우스가 존재하지 않습니다."));

        return SharehouseResultRes.from(sharehouse);
    }

    /**
     * 내가 등록한 쉐어하우스 목록 조회
     */
    public Page<SharehouseRes> getMySharehouseList(String email, Pageable pageable) {
        // 1. 해당 이메일을 가진 호스트의 매물 조회
        Page<Sharehouse> sharehouses = sharehouseRepository.findByHostEmail(email, pageable);

        // 2. SharehouseRes로 변환하여 반환
        return sharehouses.map(SharehouseRes::from);
    }



    @Transactional
    public SharehouseRes registerSharehouse(String userEmail, SharehouseReq req) {
        Member host = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("사용자 정보를 찾을 수 없습니다."));

        // 2. 좌표 변환 로직 실행
        Map<String, Double> coords = geocodingService.getCoordinates(req.getAddress());

        Double latitude = (coords != null) ? coords.get("lat") : 0.0;
        Double longitude = (coords != null) ? coords.get("lon") : 0.0;

        String imageUrlsString = String.join(",", req.getImageUrls());
        String optionsString = (req.getOptions() != null) ? String.join(",", req.getOptions()) : "";

        // 3. 엔티티에 세팅 (기존 주석 해제)
        Sharehouse sharehouse = Sharehouse.builder()
                .host(host)
                .title(req.getTitle())
                .description(req.getDescription())
                .address(req.getAddress())
                .latitude(latitude)  // 좌표 입력
                .longitude(longitude) // 좌표 입력
                .houseType(req.getHouseType())
                .rentPrice(req.getRentPrice())
                .deposit(req.getDeposit())
                .roomCount(req.getRoomCount())
                .bathroomCount(req.getBathroomCount())
                .currentResidents(req.getCurrentResidents())
                .options(optionsString)
                .imageUrls(imageUrlsString)
                .approvalStatus(ApprovalStatus.PENDING)
                .build();

        sharehouseRepository.save(sharehouse);
        return SharehouseRes.from(sharehouse);
    }


    /**
     * 1. 쉐어하우스 수정
     * - 작성자 본인인지 확인 후 수정
     */
    @Transactional
    public void updateSharehouse(Long houseId, String email, SharehouseUpdateReq req) {
        Sharehouse sharehouse = sharehouseRepository.findById(houseId)
                .orElseThrow(() -> new IllegalArgumentException("해당 쉐어하우스가 존재하지 않습니다."));

        Member member = memberRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자 정보를 찾을 수 없습니다."));

        Boolean isAdmin = member.getProfile().getRoles().contains(Role.ADMIN);
        Boolean isHost = sharehouse.getHost().getEmail().equals(email);
        if (!isHost && !isAdmin) {
            throw new IllegalStateException("수정 권한이 없습니다.");
        }

        sharehouse.updateSharehouse(
                req.getTitle(), req.getDescription(), req.getRentPrice(),
                req.getDeposit(), req.getOptions(), req.getRoomCount(),
                req.getBathroomCount(), req.getCurrentResidents(), req.getHouseType()
        );
    }

    /**
     * 2. 쉐어하우스 삭제
     * - 작성자 본인인지 확인 후 삭제
     */
    @Transactional
    public void deleteSharehouse(Long houseId, String email) {
        Sharehouse sharehouse = sharehouseRepository.findById(houseId)
                .orElseThrow(() -> new IllegalArgumentException("해당 쉐어하우스가 존재하지 않습니다."));

        Member member = memberRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자 정보를 찾을 수 없습니다."));


        Boolean isAdmin = member.getProfile().getRoles().contains(Role.ADMIN);
        Boolean isHost = sharehouse.getHost().getEmail().equals(email);
        if (!isHost && !isAdmin) {
            throw new IllegalStateException("삭제 권한이 없습니다.");
        }

        sharehouseRepository.delete(sharehouse);
    }

    /**
     * 3. 쉐어하우스 승인/거절 (관리자용)
     */
    @Transactional
    public void approveSharehouse(Long houseId, ApprovalStatus status, String adminEmail) {

        // 1. 요청자(관리자) 조회
        Member admin = memberRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new IllegalArgumentException("사용자 정보를 찾을 수 없습니다."));

        // 2. 권한 확인 (Profile 테이블의 Role 확인)
        // Profile이 없거나, Role이 ADMIN이 아니면 예외 발생
        log.info(admin.getEmail());
        if (admin.getProfile() == null || !admin.getProfile().getRoles().contains(Role.ADMIN)) {
            throw new IllegalStateException("관리자 권한이 없습니다.");
        }

        // 3. 매물 조회 및 상태 변경
        Sharehouse sharehouse = sharehouseRepository.findById(houseId)
                .orElseThrow(() -> new IllegalArgumentException("해당 쉐어하우스가 존재하지 않습니다."));

        sharehouse.changeApprovalStatus(status);
    }

    /**
     * [수정] 쉐어하우스 상세 조회
     * - 조회 시 viewCount 증가
     * - 상세 정보인 SharehouseResultRes 반환
     */
    @Transactional
    public SharehouseResultRes getSharehouseDetail(Long houseId) {
        // 1. 조회수 증가
        sharehouseRepository.updateViewCount(houseId);

        // 2. 조회
        Sharehouse sharehouse = sharehouseRepository.findById(houseId)
                .orElseThrow(() -> new IllegalArgumentException("해당 쉐어하우스가 존재하지 않습니다."));

        return SharehouseResultRes.from(sharehouse);
    }

    /**
     * [수정] 쉐어하우스 목록 조회 (검색 + 페이징 + 정렬)
     */
    public Page<SharehouseResultRes> getSharehouseList(SharehouseSearchReq req, Pageable pageable) {
        // 1. QueryDSL로 만든 커스텀 메서드 호출
        Page<Sharehouse> resultPage = sharehouseRepository.search(req, pageable);

        // 2. DTO로 변환하여 반환
        return resultPage.map(SharehouseResultRes::from);
    }
}