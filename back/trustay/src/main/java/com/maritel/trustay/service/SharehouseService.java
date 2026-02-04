package com.maritel.trustay.service;

import com.maritel.trustay.constant.ApprovalStatus;
import com.maritel.trustay.constant.Role;
import com.maritel.trustay.dto.req.SharehouseReq;
import com.maritel.trustay.dto.req.SharehouseSearchReq;
import com.maritel.trustay.dto.req.SharehouseUpdateReq;
import com.maritel.trustay.dto.res.SharehouseRes;
import com.maritel.trustay.dto.res.SharehouseResultRes;
import com.maritel.trustay.dto.res.WishToggleRes;
import com.maritel.trustay.entity.Image;
import com.maritel.trustay.entity.Member;
import com.maritel.trustay.entity.Sharehouse;
import com.maritel.trustay.entity.SharehouseImage;
import com.maritel.trustay.entity.SharehouseWish;
import com.maritel.trustay.repository.ImageRepository;
import com.maritel.trustay.repository.MemberRepository;
import com.maritel.trustay.repository.SharehouseImageRepository;
import com.maritel.trustay.repository.SharehouseRepository;
import com.maritel.trustay.repository.SharehouseWishRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.List;
import java.util.Map;


@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SharehouseService {

    private final SharehouseRepository sharehouseRepository;
    private final MemberRepository memberRepository;
    private final GeocodingService geocodingService; // 1. 주입 추가
    private final ImageRepository imageRepository;
    private final SharehouseImageRepository sharehouseImageRepository;
    private final SharehouseWishRepository sharehouseWishRepository;


    /**
     * 내 목록에서 쉐어하우스 상세 조회하기
     */
    public SharehouseResultRes getMySharehouseDetail(@PathVariable Long houseId) {
        Sharehouse sharehouse = sharehouseRepository.findById(houseId)
                .orElseThrow(() -> new IllegalArgumentException("해당 쉐어하우스가 존재하지 않습니다."));

        // [수정] 이미지 리스트 조회 후 함께 전달
        List<SharehouseImage> images = sharehouseImageRepository.findBySharehouseId(houseId);
        return SharehouseResultRes.from(sharehouse, images);
    }

    /**
     * 내가 등록한 쉐어하우스 목록 조회
     */
    public Page<SharehouseRes> getMySharehouseList(String email, Pageable pageable) {
        Page<Sharehouse> sharehouses = sharehouseRepository.findByHostEmail(email, pageable);

        // [수정] 각 항목마다 이미지를 조회하여 from 메서드에 전달
        return sharehouses.map(sharehouse -> {
            List<SharehouseImage> images = sharehouseImageRepository.findBySharehouseId(sharehouse.getId());
            return SharehouseRes.from(sharehouse, images);
        });
    }



    @Transactional
    public SharehouseRes registerSharehouse(String userEmail, SharehouseReq req) {
        Member host = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("사용자 정보를 찾을 수 없습니다."));

        Map<String, Double> coords = geocodingService.getCoordinates(req.getAddress());
        Double latitude = (coords != null) ? coords.get("lat") : 0.0;
        Double longitude = (coords != null) ? coords.get("lon") : 0.0;

        // [변경] 더 이상 String imageUrls를 쓰지 않음
        String homeRulesString = (req.getHomeRules() != null) ? String.join(",", req.getHomeRules()) : "";
        String featuresString = (req.getFeatures() != null) ? String.join(",", req.getFeatures()) : "";

        Sharehouse sharehouse = Sharehouse.builder()
                .host(host)
                .title(req.getTitle())
                .description(req.getDescription())
                .address(req.getAddress())
                .latitude(latitude)
                .longitude(longitude)
                .houseType(req.getHouseType())
                .rentPrice(req.getRentPrice())
                .roomCount(req.getRoomCount())
                .bathroomCount(req.getBathroomCount())
                .currentResidents(req.getCurrentResidents())
                .homeRules(homeRulesString)
                .features(featuresString)
                .billsIncluded(req.getBillsIncluded())
                .roomType(req.getRoomType())
                .bondType(req.getBondType())
                .minimumStay(req.getMinimumStay())
                .gender(req.getGender())
                .age(req.getAge())
                .religion(req.getReligion())
                .dietaryPreference(req.getDietaryPreference())
                .approvalStatus(ApprovalStatus.PENDING)
                .build();

        Sharehouse savedHouse = sharehouseRepository.save(sharehouse);
        List<SharehouseImage> savedImages = new java.util.ArrayList<>();

        if (req.getImageUrls() != null) {
            for (String url : req.getImageUrls()) {
                Image image = imageRepository.save(Image.builder().imageUrl(url).build());

                SharehouseImage si = sharehouseImageRepository.save(SharehouseImage.builder()
                        .sharehouse(savedHouse)
                        .image(image)
                        .build());
                savedImages.add(si); // 저장된 이미지 객체들을 리스트에 담음
            }
        }

        return SharehouseRes.from(savedHouse, savedImages);
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

        if (!sharehouse.getHost().getEmail().equals(email) && !isAdmin(member)) {
            throw new IllegalStateException("수정 권한이 없습니다.");
        }

        sharehouse.updateSharehouse(
                req.getTitle(), req.getDescription(), req.getRentPrice(), req.getHomeRules(),req.getFeatures(), req.getRoomCount(),
                 req.getBathroomCount(), req.getCurrentResidents(), req.getHouseType(),
                req.getBillsIncluded(), req.getRoomType(), req.getBondType(), req.getMinimumStay(),
                req.getGender(), req.getAge(), req.getReligion(), req.getDietaryPreference()
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

        if (!sharehouse.getHost().getEmail().equals(email) && !this.isAdmin(member)) {
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
        if (admin.getProfile() == null || !isAdmin(admin)) {
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
        sharehouseRepository.updateViewCount(houseId);

        Sharehouse sharehouse = sharehouseRepository.findById(houseId)
                .orElseThrow(() -> new IllegalArgumentException("해당 쉐어하우스가 존재하지 않습니다."));

        // [추가] 해당 쉐어하우스의 이미지 리스트 조회
        List<SharehouseImage> images = sharehouseImageRepository.findBySharehouseId(houseId);

        // [수정] sharehouse와 images를 함께 전달
        return SharehouseResultRes.from(sharehouse, images);
    }

    /**
     * [수정] 쉐어하우스 목록 조회 (검색 + 페이징 + 정렬)
     */
    public Page<SharehouseRes> getSharehouseList(SharehouseSearchReq req, Pageable pageable) {
        Page<Sharehouse> sharehousePage = sharehouseRepository.searchSharehouses(req, pageable);

        return sharehousePage.map(sharehouse -> {
            // [추가] 각 쉐어하우스의 이미지 리스트 조회
            List<SharehouseImage> images = sharehouseImageRepository.findBySharehouseId(sharehouse.getId());

            // [수정] 파라미터 2개 전달
            return SharehouseRes.from(sharehouse, images);
        });
    }

    /**
     * 쉐어하우스 찜하기/찜 해제 (토글)
     */
    @Transactional
    public WishToggleRes toggleWish(String userEmail, Long houseId) {
        Member member = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("사용자 정보를 찾을 수 없습니다."));
        Sharehouse sharehouse = sharehouseRepository.findById(houseId)
                .orElseThrow(() -> new IllegalArgumentException("해당 쉐어하우스가 존재하지 않습니다."));

        var existing = sharehouseWishRepository.findByMember_IdAndSharehouse_Id(member.getId(), sharehouse.getId());
        if (existing.isPresent()) {
            sharehouseWishRepository.delete(existing.get());
            sharehouse.decreaseWishCount();
            sharehouseRepository.save(sharehouse);
            return WishToggleRes.builder().sharehouseId(houseId).wished(false).build();
        } else {
            sharehouseWishRepository.save(SharehouseWish.builder()
                    .member(member)
                    .sharehouse(sharehouse)
                    .build());
            sharehouse.increaseWishCount();
            sharehouseRepository.save(sharehouse);
            return WishToggleRes.builder().sharehouseId(houseId).wished(true).build();
        }
    }

    /**
     * 내가 찜한 쉐어하우스 목록 조회
     */
    @Transactional(readOnly = true)
    public Page<SharehouseRes> getMyWishlist(String userEmail, Pageable pageable) {
        Member member = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("사용자 정보를 찾을 수 없습니다."));
        Page<SharehouseWish> wishes = sharehouseWishRepository.findByMember_IdOrderByRegTimeDesc(member.getId(), pageable);
        return wishes.map(w -> {
            Sharehouse sh = w.getSharehouse();
            List<SharehouseImage> images = sharehouseImageRepository.findBySharehouseId(sh.getId());
            return SharehouseRes.from(sh, images, true);
        });
    }

    private boolean isAdmin(Member member) {
        return (member.getProfile().getRoles().contains(Role.ADMIN)); // 또는 member.getRole() == Role.ADMIN
    }
}