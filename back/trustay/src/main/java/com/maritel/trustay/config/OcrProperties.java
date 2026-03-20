package com.maritel.trustay.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Tesseract tessdata의 <strong>상위 디렉터리</strong>를 지정합니다.
 * (예: Windows {@code C:\Program Files\Tesseract-OCR} — 그 안에 {@code tessdata} 폴더가 있어야 함)
 */
@Getter
@Setter
@ConfigurationProperties(prefix = "pkg.ocr")
public class OcrProperties {

    /**
     * tessdata 폴더의 부모 경로 (절대 경로 권장)
     */
    private String tesseractDataPath = "";

    /**
     * 학습 데이터 언어 (예: kor+eng)
     */
    private String language = "kor+eng";
}
