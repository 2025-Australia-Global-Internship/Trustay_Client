package com.maritel.trustay.controller;

import com.maritel.trustay.dto.req.CommunityReq;
import com.maritel.trustay.dto.res.CommunityRes;
import com.maritel.trustay.dto.res.DataResponse;
import com.maritel.trustay.dto.res.PageResponse;
import com.maritel.trustay.service.CommunityService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;

import java.security.Principal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CommunityControllerTest {

    @Mock
    private CommunityService communityService;

    private CommunityController communityController;
    private final Principal principal = () -> "user@example.com";

    @BeforeEach
    void setUp() {
        communityController = new CommunityController(communityService);
    }

    @Test
    void createCommunity_returnsSuccess() {
        CommunityReq req = new CommunityReq();
        req.setName("Community A");
        when(communityService.createCommunity("user@example.com", req)).thenReturn(CommunityRes.builder().id(1L).name("Community A").build());

        ResponseEntity<DataResponse<CommunityRes>> response = communityController.createCommunity(principal, req);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals(1L, response.getBody().getData().getId());
    }

    @Test
    void getCommunityList_returnsPagedResponse() {
        when(communityService.getCommunityList("key", PageRequest.of(0, 10))).thenReturn(Page.empty());

        ResponseEntity<DataResponse<PageResponse<CommunityRes>>> response =
                communityController.getCommunityList("key", PageRequest.of(0, 10));

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
    }

    @Test
    void getTrendingCommunities_returnsPagedResponse() {
        when(communityService.getTrendingCommunities(PageRequest.of(0, 10))).thenReturn(Page.empty());

        ResponseEntity<DataResponse<PageResponse<CommunityRes>>> response =
                communityController.getTrendingCommunities(PageRequest.of(0, 10));

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
    }

    @Test
    void getMyCommunities_returnsList() {
        when(communityService.getMyCommunities("user@example.com")).thenReturn(List.of(CommunityRes.builder().id(1L).build()));

        ResponseEntity<DataResponse<List<CommunityRes>>> response = communityController.getMyCommunities(principal);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals(1, response.getBody().getData().size());
    }

    @Test
    void getJoinedCommunities_returnsList() {
        when(communityService.getJoinedCommunities("user@example.com")).thenReturn(List.of(CommunityRes.builder().id(2L).build()));

        ResponseEntity<DataResponse<List<CommunityRes>>> response = communityController.getJoinedCommunities(principal);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals(1, response.getBody().getData().size());
    }

    @Test
    void getCommunityDetail_returnsCommunity() {
        when(communityService.getCommunityDetail(1L)).thenReturn(CommunityRes.builder().id(1L).name("Detail").build());

        ResponseEntity<DataResponse<CommunityRes>> response = communityController.getCommunityDetail(1L);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals("Detail", response.getBody().getData().getName());
    }

    @Test
    void joinCommunity_returnsSuccess() {
        doNothing().when(communityService).joinCommunity("user@example.com", 1L);

        ResponseEntity<DataResponse<Void>> response = communityController.joinCommunity(principal, 1L);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        verify(communityService).joinCommunity("user@example.com", 1L);
    }

    @Test
    void leaveCommunity_returnsSuccess() {
        doNothing().when(communityService).leaveCommunity("user@example.com", 1L);

        ResponseEntity<DataResponse<Void>> response = communityController.leaveCommunity(principal, 1L);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        verify(communityService).leaveCommunity("user@example.com", 1L);
    }

    @Test
    void updateCommunity_returnsSuccess() {
        CommunityReq req = new CommunityReq();
        req.setName("Updated");
        doNothing().when(communityService).updateCommunity("user@example.com", 1L, req);

        ResponseEntity<DataResponse<Void>> response = communityController.updateCommunity(principal, 1L, req);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        verify(communityService).updateCommunity("user@example.com", 1L, req);
    }

    @Test
    void deleteCommunity_returnsSuccess() {
        doNothing().when(communityService).deleteCommunity("user@example.com", 1L);

        ResponseEntity<DataResponse<Void>> response = communityController.deleteCommunity(principal, 1L);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        verify(communityService).deleteCommunity("user@example.com", 1L);
    }
}
