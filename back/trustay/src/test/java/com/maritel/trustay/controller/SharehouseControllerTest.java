package com.maritel.trustay.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.maritel.trustay.constant.ApprovalStatus;
import com.maritel.trustay.constant.HouseType;
import com.maritel.trustay.dto.req.SharehouseReq;
import com.maritel.trustay.dto.res.SharehouseRes;
import com.maritel.trustay.dto.res.SharehouseResultRes;
import com.maritel.trustay.dto.res.WishToggleRes;
import com.maritel.trustay.service.FileService;
import com.maritel.trustay.service.SharehouseService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.security.Principal;
import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(SharehouseController.class)
@AutoConfigureMockMvc(addFilters = false)
class SharehouseControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockBean
    SharehouseService sharehouseService;

    @MockBean
    FileService fileService;

    @MockBean
    com.maritel.trustay.config.CustomUserDetailsService customUserDetailsService;

    @Test
    @WithMockUser(username = "host@test.com")
    @DisplayName("POST /api/trustay/sharehouses - 매물 등록")
    void registerSharehouse_success() throws Exception {
        SharehouseReq req = new SharehouseReq();
        req.setTitle("테스트 쉐어하우스");
        req.setDescription("설명");
        req.setAddress("서울시 강남구");
        req.setHouseType(HouseType.APARTMENT);
        req.setRentPrice(500000);
        req.setDeposit(1000000);
        req.setImageUrls(List.of("https://example.com/img.jpg"));
        SharehouseRes res = SharehouseRes.builder()
                .id(1L)
                .title(req.getTitle())
                .build();
        when(sharehouseService.registerSharehouse(eq("host@test.com"), any())).thenReturn(res);

        mockMvc.perform(post("/api/trustay/sharehouses")
                        .principal((Principal) () -> "host@test.com")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.title").value("테스트 쉐어하우스"));
    }

    @Test
    @DisplayName("GET /api/trustay/sharehouses - 매물 목록 조회")
    void getSharehouseList_success() throws Exception {
        when(sharehouseService.getSharehouseList(any(), any())).thenReturn(new PageImpl<>(List.of()));

        mockMvc.perform(get("/api/trustay/sharehouses"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").isArray());
    }

    @Test
    @DisplayName("GET /api/trustay/sharehouses/1 - 매물 상세 조회")
    void getSharehouseDetail_success() throws Exception {
        SharehouseResultRes res = SharehouseResultRes.builder()
                .id(1L)
                .title("테스트")
                .build();
        when(sharehouseService.getSharehouseDetail(1L)).thenReturn(res);

        mockMvc.perform(get("/api/trustay/sharehouses/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(1));
    }

    @Test
    @WithMockUser(username = "user@test.com")
    @DisplayName("POST /api/trustay/sharehouses/1/wish - 찜하기 토글")
    void toggleWish_success() throws Exception {
        when(sharehouseService.toggleWish(eq("user@test.com"), eq(1L)))
                .thenReturn(WishToggleRes.builder().sharehouseId(1L).wished(true).build());

        mockMvc.perform(post("/api/trustay/sharehouses/1/wish")
                        .principal((Principal) () -> "user@test.com"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.sharehouseId").value(1))
                .andExpect(jsonPath("$.data.wished").value(true));
    }

    @Test
    @WithMockUser(username = "user@test.com")
    @DisplayName("GET /api/trustay/sharehouses/wishlist - 내 찜 목록")
    void getMyWishlist_success() throws Exception {
        when(sharehouseService.getMyWishlist(eq("user@test.com"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of()));

        mockMvc.perform(get("/api/trustay/sharehouses/wishlist")
                        .principal((Principal) () -> "user@test.com"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").isArray());
    }

    @Test
    @WithMockUser(username = "host@test.com")
    @DisplayName("PUT /api/trustay/sharehouses/1 - 매물 수정")
    void updateSharehouse_success() throws Exception {
        var req = new com.maritel.trustay.dto.req.SharehouseUpdateReq();
        req.setTitle("수정된 제목");

        mockMvc.perform(put("/api/trustay/sharehouses/1")
                        .principal((Principal) () -> "host@test.com")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());
        verify(sharehouseService).updateSharehouse(eq(1L), eq("host@test.com"), any());
    }

    @Test
    @WithMockUser(username = "admin@test.com")
    @DisplayName("PATCH /api/trustay/sharehouses/1/approval - 승인 상태 변경")
    void approveSharehouse_success() throws Exception {
        mockMvc.perform(patch("/api/trustay/sharehouses/1/approval")
                        .principal((Principal) () -> "admin@test.com")
                        .param("status", ApprovalStatus.ACTIVE.name()))
                .andExpect(status().isOk());
        verify(sharehouseService).approveSharehouse(eq(1L), eq(ApprovalStatus.ACTIVE), eq("admin@test.com"));
    }
}
