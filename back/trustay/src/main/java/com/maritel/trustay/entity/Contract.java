package com.maritel.trustay.entity;

import com.maritel.trustay.constant.ContractStatus;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity
@Table(name = "TBL_CONTRACT")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Contract extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "contract_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "house_id", nullable = false)
    private Sharehouse sharehouse;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "landlord_id", nullable = false)
    private Member landlord; // 집주인

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tenant_id", nullable = false)
    private Member tenant; // 세입자

    @OneToOne(fetch = FetchType.LAZY) // 계약서 스캔본 1:1
    @JoinColumn(name = "image_id")
    private Image contractImage;

    @Lob
    private String ocrTextData; // OCR로 추출한 텍스트 데이터

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private ContractStatus status; // 작성중, 서명완료, 보관중, 만료됨

    private LocalDate contractStartDate;
    private LocalDate contractEndDate;

    @Builder
    public Contract(Sharehouse sharehouse, Member landlord, Member tenant, ContractStatus status) {
        this.sharehouse = sharehouse;
        this.landlord = landlord;
        this.tenant = tenant;
        this.status = status;
    }
}