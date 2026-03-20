package com.maritel.trustay.dto.res;

import com.maritel.trustay.constant.PaperContractScanStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaperContractDocumentRes {

    private Long id;
    private Long roomId;
    private Long houseId;
    private String pdfUrl;
    private String ocrText;
    private List<String> sourceImageUrls;
    private PaperContractScanStatus status;
    private LocalDateTime regTime;
}
