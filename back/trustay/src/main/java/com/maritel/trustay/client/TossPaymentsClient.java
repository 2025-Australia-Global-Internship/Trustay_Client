package com.maritel.trustay.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.maritel.trustay.config.TossPaymentsProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.RestClient;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class TossPaymentsClient {

    private static final String BASE_URL = "https://api.tosspayments.com";

    private final TossPaymentsProperties props;

    /**
     * 토스 결제 승인 (테스트 키면 테스트 결제만 됩니다).
     *
     * @see <a href="https://docs.tosspayments.com/reference#confirm-payment">Toss API</a>
     */
    public JsonNode confirmPayment(String paymentKey, String orderId, long amount) {
        if (props.getSecretKey() == null || props.getSecretKey().isBlank()) {
            throw new IllegalStateException("toss.payments.secret-key 가 설정되지 않았습니다. application-local.yaml 을 확인하세요.");
        }
        String encoded = Base64.getEncoder().encodeToString(
                (props.getSecretKey() + ":").getBytes(StandardCharsets.UTF_8));

        RestClient client = RestClient.builder().baseUrl(BASE_URL).build();
        try {
            return client.post()
                    .uri("/v1/payments/confirm")
                    .header(HttpHeaders.AUTHORIZATION, "Basic " + encoded)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of(
                            "paymentKey", paymentKey,
                            "orderId", orderId,
                            "amount", amount
                    ))
                    .retrieve()
                    .body(JsonNode.class);
        } catch (RestClientResponseException e) {
            throw new TossPaymentsApiException(e.getStatusCode().value(), e.getResponseBodyAsString(StandardCharsets.UTF_8));
        }
    }
}
