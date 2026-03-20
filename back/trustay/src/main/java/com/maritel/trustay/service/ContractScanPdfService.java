package com.maritel.trustay.service;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.graphics.image.LosslessFactory;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;
import org.springframework.stereotype.Service;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;

/**
 * 스캔 이미지들을 A4 페이지에 맞춰 한 권의 PDF로 합칩니다. (이미지 기반 PDF)
 */
@Service
public class ContractScanPdfService {

    public byte[] buildPdfFromImages(List<BufferedImage> images) throws IOException {
        try (PDDocument document = new PDDocument();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            for (BufferedImage image : images) {
                BufferedImage rgb = toRgb(image);
                PDRectangle media = PDRectangle.A4;
                PDPage page = new PDPage(media);
                document.addPage(page);

                PDImageXObject pdImage = LosslessFactory.createFromImage(document, rgb);
                try (PDPageContentStream cs = new PDPageContentStream(document, page)) {
                    float pw = page.getMediaBox().getWidth();
                    float ph = page.getMediaBox().getHeight();
                    float iw = rgb.getWidth();
                    float ih = rgb.getHeight();
                    float scale = Math.min(pw / iw, ph / ih);
                    float dw = iw * scale;
                    float dh = ih * scale;
                    float x = (pw - dw) / 2;
                    float y = (ph - dh) / 2;
                    cs.drawImage(pdImage, x, y, dw, dh);
                }
            }
            document.save(out);
            return out.toByteArray();
        }
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
