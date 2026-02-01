package com.maritel.trustay.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.converter.MappingJackson2MessageConverter;
import org.springframework.messaging.converter.MessageConverter;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.util.List;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // EC2 환경이므로 모든 오리진 허용 혹은 특정 도메인 지정이 필요합니다.
        registry.addEndpoint("/ws-stomp")
                .setAllowedOriginPatterns("*")
                .withSockJS();
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // /sub로 시작하는 목적지로 메시지를 보내면 브로커가 가로채서 구독자들에게 전달
        registry.enableSimpleBroker("/sub");
        // /pub로 시작하는 메시지는 @MessageMapping 메서드로 라우팅
        registry.setApplicationDestinationPrefixes("/pub");
    }

    @Override
    public boolean configureMessageConverters(List<MessageConverter> messageConverters) {
        // 메시지 전송 시 JSON 형식을 사용하도록 설정
        MappingJackson2MessageConverter converter = new MappingJackson2MessageConverter();
        converter.setObjectMapper(new ObjectMapper());
        messageConverters.add(converter);
        return false;
    }
}