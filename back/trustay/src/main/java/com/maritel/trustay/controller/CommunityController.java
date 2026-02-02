package com.maritel.trustay.controller;

import com.maritel.trustay.dto.req.CommunityReq;
import com.maritel.trustay.dto.res.*;
import com.maritel.trustay.service.CommunityService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/trustay/communities")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Community API", description = "커뮤니티 관리")
public class CommunityController {

    private final CommunityService communityService;

    @Operation(summary = "커뮤니티 생성", description = "사용자가 새로운 커뮤니티를 생성합니다.")
    @PostMapping
    public ResponseEntity<DataResponse<CommunityRes>> createCommunity(
            Principal principal,
            @Valid @RequestBody CommunityReq req) {

        String userEmail = principal.getName();
        CommunityRes response = communityService.createCommunity(userEmail, req);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, response));
    }

    @Operation(summary = "커뮤니티 목록 조회", description = "커뮤니티 목록을 조회합니다. 키워드로 검색 가능합니다.")
    @GetMapping
    public ResponseEntity<DataResponse<PageResponse<CommunityRes>>> getCommunityList(
            @RequestParam(required = false) String keyword,
            @PageableDefault(size = 10, sort = "regTime", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<CommunityRes> resultPage = communityService.getCommunityList(keyword, pageable);
        PageResponse<CommunityRes> response = new PageResponse<>(resultPage);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, response));
    }

    @Operation(summary = "인기 커뮤니티 목록 조회", description = "멤버 수 기준으로 인기 커뮤니티를 조회합니다.")
    @GetMapping("/trending")
    public ResponseEntity<DataResponse<PageResponse<CommunityRes>>> getTrendingCommunities(
            @PageableDefault(size = 10) Pageable pageable) {

        Page<CommunityRes> resultPage = communityService.getTrendingCommunities(pageable);
        PageResponse<CommunityRes> response = new PageResponse<>(resultPage);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, response));
    }

    @Operation(summary = "내가 만든 커뮤니티 목록", description = "로그인한 사용자가 생성한 커뮤니티 목록을 조회합니다.")
    @GetMapping("/created")
    public ResponseEntity<DataResponse<List<CommunityRes>>> getMyCommunities(Principal principal) {
        String userEmail = principal.getName();
        List<CommunityRes> response = communityService.getMyCommunities(userEmail);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, response));
    }

    @Operation(summary = "내가 가입한 커뮤니티 목록", description = "로그인한 사용자가 가입한 커뮤니티 목록을 조회합니다.")
    @GetMapping("/joined")
    public ResponseEntity<DataResponse<List<CommunityRes>>> getJoinedCommunities(Principal principal) {
        String userEmail = principal.getName();
        List<CommunityRes> response = communityService.getJoinedCommunities(userEmail);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, response));
    }

    @Operation(summary = "커뮤니티 상세 조회", description = "커뮤니티 상세 정보를 조회합니다.")
    @GetMapping("/{communityId}")
    public ResponseEntity<DataResponse<CommunityRes>> getCommunityDetail(@PathVariable Long communityId) {
        CommunityRes response = communityService.getCommunityDetail(communityId);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, response));
    }

    @Operation(summary = "커뮤니티 가입", description = "커뮤니티에 가입합니다.")
    @PostMapping("/{communityId}/join")
    public ResponseEntity<DataResponse<Void>> joinCommunity(
            Principal principal,
            @PathVariable Long communityId) {

        String userEmail = principal.getName();
        communityService.joinCommunity(userEmail, communityId);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS));
    }

    @Operation(summary = "커뮤니티 탈퇴", description = "커뮤니티에서 탈퇴합니다.")
    @PostMapping("/{communityId}/leave")
    public ResponseEntity<DataResponse<Void>> leaveCommunity(
            Principal principal,
            @PathVariable Long communityId) {

        String userEmail = principal.getName();
        communityService.leaveCommunity(userEmail, communityId);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS));
    }

    @Operation(summary = "커뮤니티 수정", description = "커뮤니티 소유자가 커뮤니티 정보를 수정합니다.")
    @PutMapping("/{communityId}")
    public ResponseEntity<DataResponse<Void>> updateCommunity(
            Principal principal,
            @PathVariable Long communityId,
            @Valid @RequestBody CommunityReq req) {

        String userEmail = principal.getName();
        communityService.updateCommunity(userEmail, communityId, req);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS));
    }

    @Operation(summary = "커뮤니티 삭제", description = "커뮤니티 소유자가 커뮤니티를 삭제합니다.")
    @DeleteMapping("/{communityId}")
    public ResponseEntity<DataResponse<Void>> deleteCommunity(
            Principal principal,
            @PathVariable Long communityId) {

        String userEmail = principal.getName();
        communityService.deleteCommunity(userEmail, communityId);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS));
    }
}
