package com.maritel.trustay.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class GeocodingService {

    // 별도의 추가 디펜던시 없이 starter-web의 기본 기능 사용
    private final RestTemplate restTemplate = new RestTemplate();

    public Map<String, Double> getCoordinates(String address) {
        try {
            // 1. Nominatim API URL 구성
            String url = UriComponentsBuilder.fromHttpUrl("https://nominatim.openstreetmap.org/search")
                    .queryParam("q", address)
                    .queryParam("format", "json")
                    .queryParam("limit", 1)
                    .toUriString();

            // 2. 중요: User-Agent 헤더 추가 (OSM 운영 정책상 필수, 없으면 403 에러 발생 가능)
            HttpHeaders headers = new HttpHeaders();
            headers.set("User-Agent", "Trustay-App-Client");
            HttpEntity<String> entity = new HttpEntity<>(headers);

            // 3. API 호출 (List 형태로 응답 받음)
            ResponseEntity<List> response = restTemplate.exchange(url, HttpMethod.GET, entity, List.class);

            if (response.getBody() != null && !response.getBody().isEmpty()) {
                Map<String, Object> firstResult = (Map<String, Object>) response.getBody().get(0);

                // OSM은 좌표를 String으로 반환하므로 Double로 변환
                double lat = Double.parseDouble(firstResult.get("lat").toString());
                double lon = Double.parseDouble(firstResult.get("lon").toString());

                return Map.of("lat", lat, "lon", lon);
            }
        } catch (Exception e) {
            log.error("OSM Geocoding 에러 (주소: {}): {}", address, e.getMessage());
        }
        return null;
    }
}