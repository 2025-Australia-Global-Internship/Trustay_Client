package com.maritel.trustay.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.maritel.trustay.dto.req.PostReq;
import com.maritel.trustay.dto.req.PostUpdateReq;
import com.maritel.trustay.dto.res.PostRes;
import com.maritel.trustay.service.PostService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.PageImpl;
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

@WebMvcTest(PostController.class)
@AutoConfigureMockMvc(addFilters = false)
class PostControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockBean
    PostService postService;

    @MockBean
    com.maritel.trustay.config.CustomUserDetailsService customUserDetailsService;

    @Test
    @WithMockUser(username = "user@test.com")
    @DisplayName("POST /api/trustay/posts - 게시글 작성")
    void createPost_success() throws Exception {
        PostReq req = new PostReq();
        req.setCommunityId(1L);
        req.setTitle("제목");
        req.setContent("내용");
        PostRes res = PostRes.builder().id(1L).title(req.getTitle()).build();
        when(postService.createPost(eq("user@test.com"), any())).thenReturn(res);

        mockMvc.perform(post("/api/trustay/posts")
                        .principal((Principal) () -> "user@test.com")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.title").value("제목"));
    }

    @Test
    @DisplayName("GET /api/trustay/posts/1 - 게시글 상세")
    void getPostDetail_success() throws Exception {
        PostRes res = PostRes.builder().id(1L).title("제목").build();
        when(postService.getPostDetail(1L)).thenReturn(res);

        mockMvc.perform(get("/api/trustay/posts/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(1));
    }

    @Test
    @DisplayName("GET /api/trustay/posts/community/1 - 커뮤니티 게시글 목록")
    void getCommunityPosts_success() throws Exception {
        when(postService.getCommunityPosts(eq(1L), any())).thenReturn(new PageImpl<>(List.of()));

        mockMvc.perform(get("/api/trustay/posts/community/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").isArray());
    }

    @Test
    @DisplayName("GET /api/trustay/posts/feed - 전체 피드")
    void getAllPosts_success() throws Exception {
        when(postService.getAllPosts(any())).thenReturn(new PageImpl<>(List.of()));

        mockMvc.perform(get("/api/trustay/posts/feed"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").isArray());
    }

    @Test
    @WithMockUser(username = "user@test.com")
    @DisplayName("PUT /api/trustay/posts/1 - 게시글 수정")
    void updatePost_success() throws Exception {
        PostUpdateReq req = new PostUpdateReq();
        req.setTitle("수정 제목");
        req.setContent("수정 내용");

        mockMvc.perform(put("/api/trustay/posts/1")
                        .principal((Principal) () -> "user@test.com")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());
        verify(postService).updatePost(eq("user@test.com"), eq(1L), any());
    }

    @Test
    @WithMockUser(username = "user@test.com")
    @DisplayName("DELETE /api/trustay/posts/1 - 게시글 삭제")
    void deletePost_success() throws Exception {
        mockMvc.perform(delete("/api/trustay/posts/1")
                        .principal((Principal) () -> "user@test.com"))
                .andExpect(status().isOk());
        verify(postService).deletePost(eq("user@test.com"), eq(1L));
    }
}
