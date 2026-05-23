package com.maritel.trustay.controller;

import com.maritel.trustay.dto.res.DataResponse;
import com.maritel.trustay.dto.res.PaperContractDocumentRes;
import com.maritel.trustay.dto.res.PaperContractScanRes;
import com.maritel.trustay.dto.res.ResponseCode;
import com.maritel.trustay.service.PaperContractService;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.coyote.BadRequestException;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/paper-contracts")
@RequiredArgsConstructor
@Slf4j
public class PaperContractController {

    private final PaperContractService paperContractService;

    /**
     * 종이 계약서 사진들을 업로드하면 OCR 후 PDF로 합쳐 저장하고, 해당 채팅방에 CONTRACT 메시지를 보냅니다.
     *
     * @param roomId   채팅방 ID
     * @param memberId 업로드하는 회원 ID (채팅 참여자여야 함)
     * @param images   multipart 이름 {@code images} — 여러 장 가능
     */
    @Operation(summary = "종이 계약서 스캔 업로드")
    @PostMapping(value = "/scan", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<DataResponse<PaperContractScanRes>> scan(
            @RequestParam Long roomId,
            @RequestParam Long memberId,
            @RequestPart("images") List<MultipartFile> images
    ) throws BadRequestException {
        PaperContractScanRes res = paperContractService.scanAndStore(roomId, memberId, images);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, res));
    }

    @Operation(summary = "종이 계약서 문서 조회")
    @GetMapping("/{documentId}")
    public ResponseEntity<DataResponse<PaperContractDocumentRes>> getDocument(
            @PathVariable Long documentId,
            @RequestParam Long memberId
    ) {
        PaperContractDocumentRes res = paperContractService.getDocument(documentId, memberId);
        return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, res));
    }
}
