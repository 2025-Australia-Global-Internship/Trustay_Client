package com.maritel.trustay.controller;

import com.maritel.trustay.dto.req.PostReq;
import com.maritel.trustay.dto.req.PostUpdateReq;
import com.maritel.trustay.dto.res.DataResponse;
import com.maritel.trustay.dto.res.PageResponse;
import com.maritel.trustay.dto.res.PostRes;
import com.maritel.trustay.service.PostService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;

import java.security.Principal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PostControllerTest {

    @Mock
    private PostService postService;

    private PostController postController;
    private final Principal principal = () -> "user@example.com";

    @BeforeEach
    void setUp() {
        postController = new PostController(postService);
    }

    @Test
    void createPost_returnsSuccess() {
        PostReq req = new PostReq();
        req.setTitle("Title");
        req.setContent("Content");
        when(postService.createPost("user@example.com", req)).thenReturn(PostRes.builder().id(1L).title("Title").build());

        ResponseEntity<DataResponse<PostRes>> response = postController.createPost(principal, req);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals(1L, response.getBody().getData().getId());
    }

    @Test
    void getPostDetail_returnsSuccess() {
        when(postService.getPostDetail(1L)).thenReturn(PostRes.builder().id(1L).title("Detail").build());

        ResponseEntity<DataResponse<PostRes>> response = postController.getPostDetail(1L);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals("Detail", response.getBody().getData().getTitle());
    }

    @Test
    void getCommunityPosts_returnsPageResponse() {
        when(postService.getCommunityPosts(1L, PageRequest.of(0, 10))).thenReturn(Page.empty());

        ResponseEntity<DataResponse<PageResponse<PostRes>>> response = postController.getCommunityPosts(1L, PageRequest.of(0, 10));

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
    }

    @Test
    void getSharehouseCommunityPosts_returnsPageResponse() {
        when(postService.getSharehouseCommunityPosts(1L, PageRequest.of(0, 10))).thenReturn(Page.empty());

        ResponseEntity<DataResponse<PageResponse<PostRes>>> response = postController.getSharehouseCommunityPosts(1L, PageRequest.of(0, 10));

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
    }

    @Test
    void getAllPosts_returnsPageResponse() {
        when(postService.getAllPosts(PageRequest.of(0, 10))).thenReturn(Page.empty());

        ResponseEntity<DataResponse<PageResponse<PostRes>>> response = postController.getAllPosts(PageRequest.of(0, 10));

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
    }

    @Test
    void updatePost_returnsSuccess() {
        PostUpdateReq req = new PostUpdateReq();
        req.setTitle("Updated");
        doNothing().when(postService).updatePost("user@example.com", 1L, req);

        ResponseEntity<DataResponse<Void>> response = postController.updatePost(principal, 1L, req);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        verify(postService).updatePost("user@example.com", 1L, req);
    }

    @Test
    void deletePost_returnsSuccess() {
        doNothing().when(postService).deletePost("user@example.com", 1L);

        ResponseEntity<DataResponse<Void>> response = postController.deletePost(principal, 1L);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        verify(postService).deletePost("user@example.com", 1L);
    }
}
