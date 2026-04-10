package com.maritel.trustay.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "toss.payments")
public class TossPaymentsProperties {

    /**
     * 토스페이먼츠 시크릿 키 (테스트: test_sk_...). 서버에서만 사용합니다.
     */
    private String secretKey = "";

    /**
     * 결제위젯 연동용 클라이언트 키 (테스트: test_ck_...). 프론트에 내려줘도 됩니다.
     */
    private String clientKey = "";
}
