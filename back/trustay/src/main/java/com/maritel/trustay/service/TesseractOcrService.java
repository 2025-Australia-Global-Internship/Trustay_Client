package com.maritel.trustay.service;

import com.maritel.trustay.config.OcrProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.sourceforge.tess4j.ITesseract;
import net.sourceforge.tess4j.Tesseract;
import net.sourceforge.tess4j.TesseractException;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class TesseractOcrService {

    private final OcrProperties ocrProperties;

    public String recognize(BufferedImage image) throws TesseractException {
        if (!StringUtils.hasText(ocrProperties.getTesseractDataPath())) {
            throw new IllegalStateException(
                    "pkg.ocr.tesseract-data-path 가 설정되지 않았습니다. Tesseract 설치 경로( tessdata 의 상위 폴더 )를 application yaml에 지정하세요.");
        }

        BufferedImage rgb = toRgb(image);
        ITesseract tesseract = new Tesseract();
        tesseract.setDatapath(ocrProperties.getTesseractDataPath());
        tesseract.setLanguage(ocrProperties.getLanguage());
        tesseract.setOcrEngineMode(1);
        tesseract.setPageSegMode(1);
        return tesseract.doOCR(rgb);
    }

    /**
     * 여러 페이지 OCR 결과를 이어붙입니다.
     */
    public String recognizeAll(List<BufferedImage> pages) throws TesseractException {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < pages.size(); i++) {
            sb.append("--- page ").append(i + 1).append(" ---\n");
            sb.append(recognize(pages.get(i))).append('\n');
        }
        return sb.toString();
    }

    private static BufferedImage toRgb(BufferedImage src) {
        if (src.getType() == BufferedImage.TYPE_INT_RGB) {
            return src;
        }
        BufferedImage rgb = new BufferedImage(src.getWidth(), src.getHeight(), BufferedImage.TYPE_INT_RGB);
        Graphics2D g = rgb.createGraphics();
        try {
            g.setColor(Color.WHITE);
            g.fillRect(0, 0, rgb.getWidth(), rgb.getHeight());
            g.drawImage(src, 0, 0, null);
        } finally {
            g.dispose();
        }
        return rgb;
    }
}
