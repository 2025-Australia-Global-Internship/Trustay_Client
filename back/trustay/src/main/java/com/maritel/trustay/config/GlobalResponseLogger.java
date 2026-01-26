package com.maritel.trustay.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.MethodParameter;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyAdvice;

@ControllerAdvice
public class GlobalResponseLogger implements ResponseBodyAdvice<Object> {
    private static final Logger logger = LoggerFactory.getLogger(GlobalResponseLogger.class);

    @Override
    public boolean supports(MethodParameter returnType, Class converterType) {
        // 모든 응답을 로깅하려면 true 반환
        return true;
    }

    @Override
    public Object beforeBodyWrite(Object body, MethodParameter returnType, MediaType selectedContentType,
                                  Class selectedConverterType, org.springframework.http.server.ServerHttpRequest request,
                                  org.springframework.http.server.ServerHttpResponse response) {

        // 1. 요청 URL 가져오기
        String requestUri = "Unknown";
        if (request instanceof ServletServerHttpRequest servletRequest) {
            requestUri = servletRequest.getServletRequest().getRequestURI();
        }

        // 2. Swagger 및 정적 리소스 로깅 제외 (가장 중요)
        // 이 경로들은 응답이 매우 길거나 바이트 형태라 로그를 더럽힙니다.
        if (requestUri.contains("/v3/api-docs") || 
            requestUri.contains("/swagger-ui") || 
            requestUri.contains("/webjars")) {
            return body; 
        }

        // 3. Body 타입에 따른 로깅 처리
        if (body == null) {
            // body가 null인 경우
             logger.info("✅ Response [{}]: [Empty Body]", requestUri);
        } else if (body instanceof byte[]) {
            // 바이트 배열(이미지, 파일, Raw JSON 등)인 경우 숫자 배열 대신 요약 정보 출력
            logger.info("✅ Response [{}]: [Binary/Byte Data - Size: {} bytes]", requestUri, ((byte[]) body).length);
        } else if (body instanceof Resource) {
            // 파일 다운로드 객체인 경우
            logger.info("✅ Response [{}]: [Resource File]", requestUri);
        } else {
            // 일반 JSON 객체(DTO 등)인 경우 정상 출력
            logger.info("✅ Response [{}]: {}", requestUri, body);
        }

        return body; // 원래 응답을 그대로 반환
    }
}