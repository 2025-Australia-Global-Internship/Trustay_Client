package com.maritel.trustay.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class GeocodingService {

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper(); // JSON 파싱용

    public Map<String, Double> getCoordinates(String address) {

        try {
            // [수정 1] String url -> URI uri 객체로 변경
            // build() 뒤에 .encode()를 붙이고 .toUri()로 URI 객체를 만듭니다.
            URI uri = UriComponentsBuilder.fromHttpUrl("https://nominatim.openstreetmap.org/search")
                    .queryParam("q", address)
                    .queryParam("format", "json")
                    .queryParam("limit", 1)
                    // .queryParam("email", "s2443@e-mirim.hs.kr") // 이메일은 파라미터보다 User-Agent 헤더가 더 중요함 (선택)
                    .build()
                    .encode() // 여기서 UTF-8 인코딩 수행
                    .toUri(); // String이 아닌 URI 객체 생성

            HttpHeaders headers = new HttpHeaders();
            // [중요] Nominatim은 User-Agent가 없거나 불량하면 차단합니다.
            // 형식을 "애플리케이션이름 (연락처이메일)"로 유지하세요.
            headers.set("User-Agent", "Trustay/1.0 (s2443@e-mirim.hs.kr)");
            headers.setAccept(List.of(MediaType.APPLICATION_JSON));

            HttpEntity<String> entity = new HttpEntity<>(headers);

            log.info("요청 URI: {}", uri);

            // [수정 2] exchange 메서드에 String url 대신 URI 객체 전달
            // RestTemplate은 String으로 주면 자체적으로 또 인코딩을 시도할 수 있어 이중 인코딩 발생 가능
            ResponseEntity<String> response = restTemplate.exchange(uri, HttpMethod.GET, entity, String.class);

            if (response.getBody() != null) {
                List<Map<String, Object>> results = objectMapper.readValue(response.getBody(), List.class);

                if (!results.isEmpty()) {
                    Map<String, Object> first = results.get(0);
                    double lat = Double.parseDouble(first.get("lat").toString());
                    double lon = Double.parseDouble(first.get("lon").toString());

                    log.info("좌표 추출 성공: lat={}, lon={}", lat, lon);
                    return Map.of("lat", lat, "lon", lon);
                } else {
                    log.warn("검색 결과가 비어있습니다. (주소: {})", address);
                }
            }

        } catch (HttpClientErrorException | HttpServerErrorException e) {
            // 403 Forbidden이 뜨면 User-Agent 문제일 수 있음
            log.error("HTTP 에러 발생: {} - 본문: {}", e.getStatusCode(), e.getResponseBodyAsString());
        } catch (Exception e) {
            log.error("알 수 없는 에러 발생: {}", e.getMessage(), e);
        }

        return null;
    }
}