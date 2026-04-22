package com.maritel.trustay.controller;

import com.maritel.trustay.dto.res.DataResponse;
import com.maritel.trustay.dto.res.PaperContractDocumentRes;
import com.maritel.trustay.dto.res.PaperContractScanRes;
import com.maritel.trustay.service.PaperContractService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PaperContractControllerTest {

    @Mock
    private PaperContractService paperContractService;

    private PaperContractController paperContractController;

    @BeforeEach
    void setUp() {
        paperContractController = new PaperContractController(paperContractService);
    }

    @Test
    void scan_returnsSuccess() throws Exception {
        MockMultipartFile image1 = new MockMultipartFile("images", "1.jpg", "image/jpeg", "a".getBytes());
        when(paperContractService.scanAndStore(1L, 10L, List.of(image1)))
                .thenReturn(PaperContractScanRes.builder().paperContractDocumentId(99L).pdfUrl("https://pdf/99.pdf").build());

        ResponseEntity<DataResponse<PaperContractScanRes>> response = paperContractController.scan(1L, 10L, List.of(image1));

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals(99L, response.getBody().getData().getPaperContractDocumentId());
    }

    @Test
    void getDocument_returnsSuccess() {
        when(paperContractService.getDocument(99L, 10L))
                .thenReturn(PaperContractDocumentRes.builder().id(99L).pdfUrl("https://pdf/99.pdf").build());

        ResponseEntity<DataResponse<PaperContractDocumentRes>> response = paperContractController.getDocument(99L, 10L);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals(99L, response.getBody().getData().getId());
    }
}
