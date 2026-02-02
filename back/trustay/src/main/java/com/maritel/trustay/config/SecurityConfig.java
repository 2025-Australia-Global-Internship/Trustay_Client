package com.maritel.trustay.config;

import com.maritel.trustay.filter.JwtFilter;
import com.maritel.trustay.util.JwtUtil;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityCustomizer;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.Collections;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(securedEnabled = true, prePostEnabled = true) //API 권한 확인 로직 추가, 우선 보안 모두 풀었음
public class SecurityConfig {

    //    @Autowired
    private final JwtUtil jwtUtil;

    private final CustomUserDetailsService userDetailsService;


    public SecurityConfig(JwtUtil jwtUtil, CustomUserDetailsService userDetailsService) {
        this.jwtUtil = jwtUtil;
        this.userDetailsService = userDetailsService;
    }

//    @Bean
//    public WebSecurityCustomizer webSecurityCustomizer() {
//        return web -> web.ignoring().requestMatchers(
//                "/swagger-ui/**", "/api-docs/**", "/**"
//        );
//    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        JwtFilter jwtFilter = new JwtFilter(jwtUtil, userDetailsService);
        http
                .cors(Customizer.withDefaults())
                .csrf(AbstractHttpConfigurer::disable) // ✅ 변경된 방식
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/api/members/signup",
                                "/api/naver/book",
                                "/swagger-ui/**",
                                "/swagger-ui.html",
                                "/v3/api-docs/**",
                                "/swagger-resources/**",
                                "/webjars/**",
                                "/api/**",
                                "/api/auth/**",
                                "/static/**",
                                "/images/**"
                        ).permitAll()
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtFilter, org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(Arrays.asList("*",
                "http://172.20.10.3:8080",
                "http://trustay.digitalbasis.com",
                "https://trustay.digitalbasis.com",
                "http://localhost:3000"));
        //configuration.addAllowedHeader("*");
        //configuration.setAllowedMethods(Arrays.asList("*"));
        configuration.setAllowedOriginPatterns(Collections.singletonList("*")); // 모든 도메인 허용
        configuration.setAllowedMethods(Collections.singletonList("*")); // 모든 HTTP 메서드 허용
        configuration.setAllowedHeaders(Collections.singletonList("*")); // 모든 헤더 허용

        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/v3/**", configuration);
        source.registerCorsConfiguration("/v1/**", configuration);
        source.registerCorsConfiguration("/v2/**", configuration);
        source.registerCorsConfiguration("/admin/**", configuration);
        source.registerCorsConfiguration("/gateway/**", configuration);
        source.registerCorsConfiguration("/thru/**", configuration);
        source.registerCorsConfiguration("/enoma/**", configuration);
        source.registerCorsConfiguration("/**", configuration); // 모든 경로에 대해 CORS 설정 적용
        return source;
    }

    @Bean
    public WebSecurityCustomizer webSecurityCustomizer() {
        return web -> web.ignoring().requestMatchers(
                "/images/**",
                "/static/**",
                "/favicon.ico",
                "/ws-stomp/**", // 웹소켓 핸드쉐이크 허용
                "/chat-test.html" // 테스트용 페이지 허용
        );
    }
}