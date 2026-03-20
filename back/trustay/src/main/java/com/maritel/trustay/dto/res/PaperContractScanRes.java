package com.maritel.trustay.dto.res;

import com.maritel.trustay.constant.PaperContractScanStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaperContractScanRes {

    private Long paperContractDocumentId;
    private String pdfUrl;
    private String ocrText;
    private PaperContractScanStatus status;
}
