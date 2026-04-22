package com.maritel.trustay.controller;

import com.maritel.trustay.constant.ApprovalStatus;
import com.maritel.trustay.dto.req.SharehouseReq;
import com.maritel.trustay.dto.req.SharehouseSearchReq;
import com.maritel.trustay.dto.req.SharehouseUpdateReq;
import com.maritel.trustay.dto.res.DataResponse;
import com.maritel.trustay.dto.res.PageResponse;
import com.maritel.trustay.dto.res.SharehouseRes;
import com.maritel.trustay.dto.res.SharehouseResultRes;
import com.maritel.trustay.dto.res.WishToggleRes;
import com.maritel.trustay.service.FileService;
import com.maritel.trustay.service.SharehouseService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;

import java.io.IOException;
import java.security.Principal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SharehouseControllerTest {

    @Mock
    private SharehouseService sharehouseService;

    @Mock
    private FileService fileService;

    private SharehouseController sharehouseController;
    private final Principal principal = () -> "host@example.com";

    @BeforeEach
    void setUp() {
        sharehouseController = new SharehouseController(sharehouseService, fileService);
    }

    @Test
    void uploadSharehouseImages_returnsUploadedUrls() throws IOException {
        MockMultipartFile image1 = new MockMultipartFile("images", "1.jpg", "image/jpeg", "a".getBytes());
        MockMultipartFile image2 = new MockMultipartFile("images", "2.jpg", "image/jpeg", "b".getBytes());
        when(fileService.uploadFile(image1)).thenReturn("https://img/1.jpg");
        when(fileService.uploadFile(image2)).thenReturn("https://img/2.jpg");

        ResponseEntity<DataResponse<List<String>>> response = sharehouseController.uploadSharehouseImages(List.of(image1, image2));

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals(2, response.getBody().getData().size());
    }

    @Test
    void registerSharehouse_returnsSuccess() {
        SharehouseReq req = new SharehouseReq();
        req.setTitle("House");
        req.setDescription("desc");
        req.setAddress("addr");
        req.setImageUrls(List.of("https://img/1.jpg"));
        when(sharehouseService.registerSharehouse("host@example.com", req)).thenReturn(SharehouseRes.builder().id(1L).title("House").build());

        ResponseEntity<DataResponse<SharehouseRes>> response = sharehouseController.registerSharehouse(principal, req);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals(1L, response.getBody().getData().getId());
    }

    @Test
    void updateSharehouse_returnsSuccess() {
        SharehouseUpdateReq req = new SharehouseUpdateReq();
        req.setTitle("new title");
        doNothing().when(sharehouseService).updateSharehouse(1L, "host@example.com", req);

        ResponseEntity<DataResponse<Void>> response = sharehouseController.updateSharehouse(1L, req, principal);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        verify(sharehouseService).updateSharehouse(1L, "host@example.com", req);
    }

    @Test
    void deleteSharehouse_returnsSuccess() {
        doNothing().when(sharehouseService).deleteSharehouse(1L, "host@example.com");

        ResponseEntity<DataResponse<Void>> response = sharehouseController.deleteSharehouse(1L, principal);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        verify(sharehouseService).deleteSharehouse(1L, "host@example.com");
    }

    @Test
    void approveSharehouse_returnsSuccess() {
        doNothing().when(sharehouseService).approveSharehouse(1L, ApprovalStatus.ACTIVE, "host@example.com");

        ResponseEntity<DataResponse<Void>> response = sharehouseController.approveSharehouse(1L, ApprovalStatus.ACTIVE, principal);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        verify(sharehouseService).approveSharehouse(1L, ApprovalStatus.ACTIVE, "host@example.com");
    }

    @Test
    void getMySharehouseDetail_returnsSuccess() {
        when(sharehouseService.getMySharehouseDetail(1L)).thenReturn(SharehouseResultRes.builder().id(1L).title("Mine").build());

        ResponseEntity<DataResponse<SharehouseResultRes>> response = sharehouseController.getMySharehouseDetail(1L);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals(1L, response.getBody().getData().getId());
    }

    @Test
    void getMySharehouses_returnsPageResponse() {
        when(sharehouseService.getMySharehouseList("host@example.com", PageRequest.of(0, 10))).thenReturn(Page.empty());

        ResponseEntity<DataResponse<PageResponse<SharehouseRes>>> response = sharehouseController.getMySharehouses(principal, PageRequest.of(0, 10));

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
    }

    @Test
    void getSharehouseDetail_returnsSuccess() {
        when(sharehouseService.getSharehouseDetail(1L)).thenReturn(SharehouseResultRes.builder().id(1L).title("Public").build());

        ResponseEntity<DataResponse<SharehouseResultRes>> response = sharehouseController.getSharehouseDetail(1L);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals("Public", response.getBody().getData().getTitle());
    }

    @Test
    void toggleWish_returnsSuccess() {
        when(sharehouseService.toggleWish("host@example.com", 1L)).thenReturn(WishToggleRes.builder().sharehouseId(1L).wished(true).build());

        ResponseEntity<DataResponse<WishToggleRes>> response = sharehouseController.toggleWish(principal, 1L);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals(true, response.getBody().getData().isWished());
    }

    @Test
    void getMyWishlist_returnsPageResponse() {
        when(sharehouseService.getMyWishlist("host@example.com", PageRequest.of(0, 10))).thenReturn(Page.empty());

        ResponseEntity<DataResponse<PageResponse<SharehouseRes>>> response = sharehouseController.getMyWishlist(principal, PageRequest.of(0, 10));

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
    }

    @Test
    void getSharehouseList_returnsPageResponse() {
        SharehouseSearchReq req = new SharehouseSearchReq();
        when(sharehouseService.getSharehouseList(req, PageRequest.of(0, 10))).thenReturn(Page.empty());

        ResponseEntity<DataResponse<PageResponse<SharehouseRes>>> response = sharehouseController.getSharehouseList(req, PageRequest.of(0, 10));

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
    }
}
