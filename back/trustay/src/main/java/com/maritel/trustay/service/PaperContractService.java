package com.maritel.trustay.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.maritel.trustay.constant.PaperContractScanStatus;
import com.maritel.trustay.dto.res.ChatMessageRes;
import com.maritel.trustay.dto.res.PaperContractDocumentRes;
import com.maritel.trustay.dto.res.PaperContractScanRes;
import com.maritel.trustay.entity.ChatRoom;
import com.maritel.trustay.entity.Member;
import com.maritel.trustay.entity.PaperContractDocument;
import com.maritel.trustay.repository.ChatRoomRepository;
import com.maritel.trustay.repository.MemberRepository;
import com.maritel.trustay.repository.PaperContractDocumentRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.sourceforge.tess4j.TesseractException;
import org.apache.coyote.BadRequestException;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.CollectionUtils;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.net.MalformedURLException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class PaperContractService {

    private final PaperContractDocumentRepository paperContractDocumentRepository;
    private final ChatRoomRepository chatRoomRepository;
    private final MemberRepository memberRepository;
    private final FileService fileService;
    private final TesseractOcrService tesseractOcrService;
    private final ContractScanPdfService contractScanPdfService;
    private final ChatMessageService chatMessageService;
    private final ObjectMapper objectMapper;
    private final SimpMessagingTemplate messagingTemplate;

    /**
     * 스캔 이미지 업로드 → Tesseract OCR → 페이지별 이미지가 담긴 PDF 생성 → 저장 후 채팅 CONTRACT 메시지 브로드캐스트
     */
    public PaperContractScanRes scanAndStore(Long roomId, Long memberId, List<MultipartFile> images)
            throws BadRequestException {
        if (CollectionUtils.isEmpty(images)) {
            throw new BadRequestException("이미지가 1장 이상 필요합니다.");
        }

        ChatRoom room = chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("채팅방을 찾을 수 없습니다."));
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다."));

        if (!room.getSender().getId().equals(memberId) && !room.getReceiver().getId().equals(memberId)) {
            throw new IllegalArgumentException("해당 채팅방의 참여자가 아닙니다.");
        }

        List<BufferedImage> bufferedImages = new ArrayList<>();
        List<String> imageUrls = new ArrayList<>();

        for (MultipartFile file : images) {
            if (file == null || file.isEmpty()) {
                continue;
            }
            BufferedImage bi;
            try {
                bi = ImageIO.read(file.getInputStream());
            } catch (IOException e) {
                throw new IllegalStateException("이미지를 읽는 중 오류: " + file.getOriginalFilename(), e);
            }
            if (bi == null) {
                throw new BadRequestException("이미지를 읽을 수 없는 파일이 포함되어 있습니다: " + file.getOriginalFilename());
            }
            bufferedImages.add(bi);

            // [수정됨] MalformedURLException 예외 처리 추가
            try {
                imageUrls.add(fileService.uploadContractScanImage(file));
            } catch (MalformedURLException e) {
                log.error("URL 생성 오류", e);
                throw new IllegalStateException("파일 업로드 중 URL 생성 오류가 발생했습니다: " + file.getOriginalFilename(), e);
            }
        }

        if (bufferedImages.isEmpty()) {
            throw new BadRequestException("유효한 이미지가 없습니다.");
        }

        String ocrText;
        try {
            ocrText = tesseractOcrService.recognizeAll(bufferedImages);
        } catch (TesseractException e) {
            log.error("Tesseract OCR 실패", e);
            throw new IllegalStateException("OCR 처리에 실패했습니다. Tesseract 설치 및 pkg.ocr.tesseract-data-path, 언어 데이터(kor, eng)를 확인하세요.", e);
        }

        byte[] pdfBytes;
        try {
            pdfBytes = contractScanPdfService.buildPdfFromImages(bufferedImages);
        } catch (IOException e) {
            log.error("PDF 생성 실패", e);
            throw new IllegalStateException("PDF 생성에 실패했습니다.", e);
        }

        String pdfUrl = fileService.saveContractPdf(pdfBytes);

        String urlsJson;
        try {
            urlsJson = objectMapper.writeValueAsString(imageUrls);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("메타데이터 직렬화 실패", e);
        }

        PaperContractDocument doc = PaperContractDocument.builder()
                .chatRoom(room)
                .sharehouse(room.getSharehouse())
                .uploadedBy(member)
                .sourceImageUrlsJson(urlsJson)
                .pdfUrl(pdfUrl)
                .ocrText(ocrText)
                .status(PaperContractScanStatus.COMPLETED)
                .build();
        paperContractDocumentRepository.save(doc);

        ChatMessageRes chatRes = chatMessageService.saveContractScanMessage(roomId, memberId, pdfUrl, doc);
        messagingTemplate.convertAndSend("/sub/chat/room/" + roomId, chatRes);

        return PaperContractScanRes.builder()
                .paperContractDocumentId(doc.getId())
                .pdfUrl(pdfUrl)
                .ocrText(ocrText)
                .status(doc.getStatus())
                .build();
    }

    @Transactional(readOnly = true)
    public PaperContractDocumentRes getDocument(Long documentId, Long memberId) {
        PaperContractDocument doc = paperContractDocumentRepository.findById(documentId)
                .orElseThrow(() -> new EntityNotFoundException("문서를 찾을 수 없습니다."));
        ChatRoom room = doc.getChatRoom();
        if (!room.getSender().getId().equals(memberId) && !room.getReceiver().getId().equals(memberId)) {
            throw new IllegalArgumentException("이 문서를 조회할 권한이 없습니다.");
        }

        List<String> urls = parseSourceUrls(doc.getSourceImageUrlsJson());

        return PaperContractDocumentRes.builder()
                .id(doc.getId())
                .roomId(room.getId())
                .houseId(room.getSharehouse() != null ? room.getSharehouse().getId() : null)
                .pdfUrl(doc.getPdfUrl())
                .ocrText(doc.getOcrText())
                .sourceImageUrls(urls)
                .status(doc.getStatus())
                .regTime(doc.getRegTime())
                .build();
    }

    private List<String> parseSourceUrls(String json) {
        if (json == null || json.isBlank()) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<List<String>>() {
            });
        } catch (JsonProcessingException e) {
            log.warn("sourceImageUrlsJson 파싱 실패: {}", e.getMessage());
            return Collections.emptyList();
        }
    }
}