package com.maritel.trustay.controller;

import com.maritel.trustay.dto.req.ProfileUpdateReq;
import com.maritel.trustay.dto.req.SignupReq;
import com.maritel.trustay.dto.res.DataResponse;
import com.maritel.trustay.dto.res.ProfileRes;
import com.maritel.trustay.service.MemberService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;

import java.security.Principal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MemberControllerTest {

    @Mock
    private MemberService memberService;

    private MemberController memberController;

    private final Principal principal = () -> "user@example.com";

    @BeforeEach
    void setUp() {
        memberController = new MemberController(memberService);
    }

    @Test
    void signup_success_returnsSuccessCode() {
        SignupReq req = SignupReq.builder()
                .name("Tester")
                .email("user@example.com")
                .passwd("Password1!")
                .build();

        ResponseEntity<DataResponse<Void>> response = memberController.signup(req);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        verify(memberService).signup(req);
    }

    @Test
    void signup_duplicateEmail_returnsAlreadyExistsCode() {
        SignupReq req = SignupReq.builder()
                .name("Tester")
                .email("user@example.com")
                .passwd("Password1!")
                .build();
        doThrow(new IllegalStateException("duplicate")).when(memberService).signup(req);

        ResponseEntity<DataResponse<Void>> response = memberController.signup(req);

        assertNotNull(response.getBody());
        assertEquals(1001, response.getBody().getCode());
    }

    @Test
    void getProfile_returnsProfilePayload() {
        ProfileRes profile = new ProfileRes();
        profile.setEmail("user@example.com");
        when(memberService.getProfile("user@example.com")).thenReturn(profile);

        ResponseEntity<DataResponse<ProfileRes>> response = memberController.getProfile(principal);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals("user@example.com", response.getBody().getData().getEmail());
    }

    @Test
    void updateProfile_callsServiceAndReturnsSuccess() {
        ProfileUpdateReq req = new ProfileUpdateReq("2000-01-01", "01012345678", "123-456-789");
        doNothing().when(memberService).updateProfileInfo("user@example.com", req);

        ResponseEntity<DataResponse<Void>> response = memberController.updateProfile(principal, req);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        verify(memberService).updateProfileInfo("user@example.com", req);
    }

    @Test
    void updateProfileImage_callsServiceAndReturnsSuccess() {
        MockMultipartFile file = new MockMultipartFile("profileImage", "profile.jpg", "image/jpeg", "img".getBytes());
        doNothing().when(memberService).updateProfileImage("user@example.com", file);

        ResponseEntity<DataResponse<Void>> response = memberController.updateProfileImage(principal, file);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        verify(memberService).updateProfileImage("user@example.com", file);
    }
}
