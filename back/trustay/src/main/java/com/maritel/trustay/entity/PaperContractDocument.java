package com.maritel.trustay.entity;

import com.maritel.trustay.constant.PaperContractScanStatus;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "TBL_PAPER_CONTRACT_DOCUMENT")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PaperContractDocument extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "paper_contract_doc_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private ChatRoom chatRoom;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "house_id", nullable = false)
    private Sharehouse sharehouse;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "uploaded_by_id", nullable = false)
    private Member uploadedBy;

    /** 업로드한 원본 이미지 URL 목록 (JSON 배열 문자열) */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String sourceImageUrlsJson;

    @Column(length = 1000)
    private String pdfUrl;

    @Lob
    @Column(columnDefinition = "LONGTEXT")
    private String ocrText;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private PaperContractScanStatus status;

    @Column(length = 2000)
    private String errorMessage;

    @Builder
    public PaperContractDocument(ChatRoom chatRoom, Sharehouse sharehouse, Member uploadedBy,
                                   String sourceImageUrlsJson, String pdfUrl, String ocrText,
                                   PaperContractScanStatus status, String errorMessage) {
        this.chatRoom = chatRoom;
        this.sharehouse = sharehouse;
        this.uploadedBy = uploadedBy;
        this.sourceImageUrlsJson = sourceImageUrlsJson;
        this.pdfUrl = pdfUrl;
        this.ocrText = ocrText;
        this.status = status;
        this.errorMessage = errorMessage;
    }
}
