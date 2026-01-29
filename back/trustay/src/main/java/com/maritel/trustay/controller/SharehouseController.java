package com.maritel.trustay.controller;

import lombok.Getter;
import org.springframework.web.bind.annotation.RequestBody;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.maritel.trustay.constant.ApprovalStatus;
import com.maritel.trustay.dto.req.SharehouseReq;
import com.maritel.trustay.dto.req.SharehouseSearchReq;
import com.maritel.trustay.dto.req.SharehouseUpdateReq;
import com.maritel.trustay.dto.res.*;
import com.maritel.trustay.service.FileService;
import com.maritel.trustay.service.SharehouseService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

// [중요] 여기 Import가 잘못되어 있었습니다. 아래 것으로 바꿔야 합니다.
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.security.Principal;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/trustay/sharehouses")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Sharehouse API", description = "쉐어하우스 매물 관리")
public class SharehouseController {

    private final SharehouseService sharehouseService;
    private final FileService fileService; // [추가] 컨트롤러에서 직접 파일 저장 호출

    @Operation(summary = "매물 이미지 업로드", description = "이미지를 서버에 업로드하고 URL 리스트를 반환합니다.")
    @PostMapping(value = "/images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<DataResponse<List<String>>> uploadSharehouseImages(
            @RequestPart("images") List<MultipartFile> images
    ) throws IOException {

        List<String> uploadedUrls = new ArrayList<>();
        for (MultipartFile image : images) {
            // FileService의 기존 메서드 활용
            String url = fileService.uploadFile(image);
            uploadedUrls.add(url);
        }
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, uploadedUrls));
    }

    @Operation(summary = "쉐어하우스 매물 등록", description = "이미지 업로드 후 받은 URL을 포함하여 매물 정보를 등록합니다.")
    @PostMapping("") // consumes 삭제 (이제 JSON만 받음)
    public ResponseEntity<DataResponse<SharehouseRes>> registerSharehouse(
            Principal principal,
            @Valid @RequestBody SharehouseReq req // [핵심] @RequestPart -> @RequestBody 변경
    ) {
        // ObjectMapper 변환 과정 삭제됨 -> 스프링이 알아서 해줌
        String userEmail = principal.getName();

        // 파일 없이 DTO만 넘김
        SharehouseRes response = sharehouseService.registerSharehouse(userEmail, req);

        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, response));
    }

    @Operation(summary = "쉐어하우스 정보 수정", description = "집주인이 본인의 매물 정보를 수정합니다.")
    @PutMapping("/{houseId}")
    public ResponseEntity<DataResponse<Void>> updateSharehouse(
            @PathVariable Long houseId,
            @RequestBody SharehouseUpdateReq req,
            Principal principal) {

        String email = principal.getName();
        sharehouseService.updateSharehouse(houseId, email, req);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS));
    }

    @Operation(summary = "쉐어하우스 삭제", description = "집주인이 본인의 매물을 삭제합니다.")
    @DeleteMapping("/{houseId}")
    public ResponseEntity<DataResponse<Void>> deleteSharehouse(
            @PathVariable Long houseId,
            Principal principal) {

        String email = principal.getName();
        sharehouseService.deleteSharehouse(houseId, email);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS));
    }

    @Operation(summary = "쉐어하우스 승인 상태 변경", description = "관리자가 매물을 승인(APPROVED)하거나 거절(REJECTED)합니다.")
    @PatchMapping("/{houseId}/approval")
    public ResponseEntity<DataResponse<Void>> approveSharehouse(
            @PathVariable Long houseId,
            @RequestParam ApprovalStatus status,
            Principal principal) { // Principal 추가

        // 로그인한 사용자(관리자 추정)의 이메일 추출
        String email = principal.getName();
        log.info(email);

        // 서비스에 이메일 전달하여 권한 체크 및 승인 수행
        sharehouseService.approveSharehouse(houseId, status, email);

        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS));
    }

    @Operation(summary = "내가 들록한 쉐어하우스 자세히 보기", description = "상세보기를 하되, 조회수는 안 올라가는 api")
    @GetMapping("/my/{houseId}")
    public ResponseEntity<DataResponse<SharehouseResultRes>> getMySharehouseDetail(@PathVariable Long houseId) {
        SharehouseResultRes response = sharehouseService.getMySharehouseDetail(houseId);

        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, response));
    }

    @Operation(summary = "내가 등록한 쉐어하우스 목록 조회", description = "로그인한 집주인이 본인이 등록한 매물 목록을 조회합니다.")
    @GetMapping("/my")
    public ResponseEntity<DataResponse<PageResponse<SharehouseRes>>> getMySharehouses(
            Principal principal,
            // sort를 "id"로 변경, 필요에 따라 direction(DESC/ASC)을 설정하세요.
            @PageableDefault(size = 10, sort = "viewCount", direction = Sort.Direction.DESC) Pageable pageable) {

        String email = principal.getName();

        // 서비스 호출 (SharehouseService의 메서드)
        Page<SharehouseRes> resultPage = sharehouseService.getMySharehouseList(email, pageable);

        // PageResponse로 변환하여 반환
        PageResponse<SharehouseRes> response = new PageResponse<>(resultPage);

        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, response));
    }

    @Operation(summary = "쉐어하우스 상세 조회", description = "매물 상세 정보를 조회합니다. (조회수 1 증가)")
    @GetMapping("/{houseId}")
    public ResponseEntity<DataResponse<SharehouseResultRes>> getSharehouseDetail(@PathVariable Long houseId) {
        SharehouseResultRes response = sharehouseService.getSharehouseDetail(houseId);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, response));
    }

    @Operation(summary = "쉐어하우스 목록 조회")
    @GetMapping
    public ResponseEntity<DataResponse<PageResponse<SharehouseResultRes>>> getSharehouseList(
            @ModelAttribute SharehouseSearchReq req,
            @PageableDefault(size = 10, sort = "viewCount", direction = Sort.Direction.DESC) Pageable pageable) {

        // 1. 서비스에서 Page 객체를 받아옴
        Page<SharehouseResultRes> resultPage = sharehouseService.getSharehouseList(req, pageable);

        // 2. 우리가 만든 깔끔한 PageResponse로 변환!
        PageResponse<SharehouseResultRes> response = new PageResponse<>(resultPage);

        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, response));
    }
}