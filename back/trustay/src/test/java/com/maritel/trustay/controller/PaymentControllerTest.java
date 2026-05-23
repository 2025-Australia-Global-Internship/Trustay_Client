package com.maritel.trustay.controller;

import com.maritel.trustay.client.TossPaymentsApiException;
import com.maritel.trustay.dto.req.DutchPayCreateReq;
import com.maritel.trustay.dto.req.PaymentConfirmReq;
import com.maritel.trustay.dto.req.RentPaymentPrepareReq;
import com.maritel.trustay.dto.res.*;
import com.maritel.trustay.service.PaymentService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;

import java.security.Principal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PaymentControllerTest {

    @Mock
    private PaymentService paymentService;

    private PaymentController paymentController;
    private final Principal principal = () -> "user@example.com";

    @BeforeEach
    void setUp() {
        paymentController = new PaymentController(paymentService);
    }

    @Test
    void tossClientConfig_returnsSuccess() {
        when(paymentService.getTossClientConfig()).thenReturn(TossClientConfigRes.builder().clientKey("test_ck").build());

        ResponseEntity<DataResponse<TossClientConfigRes>> response = paymentController.tossClientConfig();

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals("test_ck", response.getBody().getData().getClientKey());
    }

    @Test
    void prepareRent_returnsSuccess() {
        RentPaymentPrepareReq req = new RentPaymentPrepareReq();
        req.setContractId(1L);
        req.setAmount(10000L);
        when(paymentService.prepareRentPayment("user@example.com", req)).thenReturn(PaymentPrepareRes.builder().paymentId(1L).orderId("order-1").build());

        ResponseEntity<DataResponse<PaymentPrepareRes>> response = paymentController.prepareRent(principal, req);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals("order-1", response.getBody().getData().getOrderId());
    }

    @Test
    void createDutch_returnsSuccess() {
        DutchPayCreateReq req = new DutchPayCreateReq();
        req.setTotalAmount(3000L);
        req.setMemberIds(List.of(1L, 2L, 3L));
        req.setPayeeMemberId(1L);
        when(paymentService.createDutchPay("user@example.com", req)).thenReturn(DutchPayCreateRes.builder().dutchPayGroupId(1L).build());

        ResponseEntity<DataResponse<DutchPayCreateRes>> response = paymentController.createDutch(principal, req);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals(1L, response.getBody().getData().getDutchPayGroupId());
    }

    @Test
    void confirm_whenTossError_returnsTossFailedCode() {
        PaymentConfirmReq req = new PaymentConfirmReq();
        req.setPaymentKey("pk");
        req.setOrderId("order-1");
        req.setAmount(1000L);
        when(paymentService.confirmPayment("user@example.com", req)).thenThrow(new TossPaymentsApiException(400, "bad request"));

        ResponseEntity<DataResponse<PaymentConfirmRes>> response = paymentController.confirm(principal, req);

        assertNotNull(response.getBody());
        assertEquals(5001, response.getBody().getCode());
    }

    @Test
    void myPending_returnsSuccess() {
        when(paymentService.listMyPendingPayments("user@example.com"))
                .thenReturn(List.of(PendingPaymentRes.builder().paymentId(1L).orderId("order-1").amount(1000L).build()));

        ResponseEntity<DataResponse<List<PendingPaymentRes>>> response = paymentController.myPending(principal);

        assertNotNull(response.getBody());
        assertEquals(200, response.getBody().getCode());
        assertEquals(1, response.getBody().getData().size());
    }
}
