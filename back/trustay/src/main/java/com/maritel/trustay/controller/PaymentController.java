package com.maritel.trustay.controller;

import com.maritel.trustay.client.TossPaymentsApiException;
import com.maritel.trustay.dto.req.DutchPayCreateReq;
import com.maritel.trustay.dto.req.PaymentConfirmReq;
import com.maritel.trustay.dto.req.RentPaymentPrepareReq;
import com.maritel.trustay.dto.res.*;
import com.maritel.trustay.service.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/trustay/payments")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Payment API", description = "토스 테스트 결제, 월세 준비, N빵(더치페이)")
public class PaymentController {

    private final PaymentService paymentService;

    @Operation(summary = "토스 결제위젯용 클라이언트 키 조회")
    @GetMapping("/toss/client-config")
    public ResponseEntity<DataResponse<TossClientConfigRes>> tossClientConfig() {
        try {
            TossClientConfigRes res = paymentService.getTossClientConfig();
            return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, res));
        } catch (IllegalStateException e) {
            return ResponseEntity.ok(DataResponse.of(ResponseCode.NOT_VALID.getCode(), e.getMessage(), null));
        }
    }

    @Operation(summary = "월세 결제 준비 (orderId 발급, 집주인 계좌 안내)")
    @PostMapping("/rent/prepare")
    public ResponseEntity<DataResponse<PaymentPrepareRes>> prepareRent(
            Principal principal,
            @Valid @RequestBody RentPaymentPrepareReq req) {
        try {
            PaymentPrepareRes res = paymentService.prepareRentPayment(principal.getName(), req);
            return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, res));
        } catch (IllegalArgumentException e) {
            return badRequest(e.getMessage());
        }
    }

    @Operation(summary = "N빵 생성 (참여자별 금액·orderId 분배)")
    @PostMapping("/dutch")
    public ResponseEntity<DataResponse<DutchPayCreateRes>> createDutch(
            Principal principal,
            @Valid @RequestBody DutchPayCreateReq req) {
        try {
            DutchPayCreateRes res = paymentService.createDutchPay(principal.getName(), req);
            return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, res));
        } catch (IllegalArgumentException e) {
            return badRequest(e.getMessage());
        }
    }

    @Operation(summary = "토스 결제 승인 (테스트 키면 테스트만)")
    @PostMapping("/confirm")
    public ResponseEntity<DataResponse<PaymentConfirmRes>> confirm(
            Principal principal,
            @Valid @RequestBody PaymentConfirmReq req) {
        try {
            PaymentConfirmRes res = paymentService.confirmPayment(principal.getName(), req);
            return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, res));
        } catch (IllegalArgumentException e) {
            return badRequest(e.getMessage());
        } catch (TossPaymentsApiException e) {
            log.warn("Toss confirm failed: {}", e.getResponseBody());
            return ResponseEntity.ok(DataResponse.of(ResponseCode.TOSS_PAYMENT_FAILED.getCode(),
                    ResponseCode.TOSS_PAYMENT_FAILED.getMessage() + " " + e.getResponseBody(), null));
        }
    }

    @Operation(summary = "내 미완료(PENDING) 결제 목록")
    @GetMapping("/me/pending")
    public ResponseEntity<DataResponse<List<PendingPaymentRes>>> myPending(Principal principal) {
        try {
            List<PendingPaymentRes> list = paymentService.listMyPendingPayments(principal.getName());
            return ResponseEntity.ok(DataResponse.of(ResponseCode.SUCCESS, list));
        } catch (IllegalArgumentException e) {
            return badRequest(e.getMessage());
        }
    }

    private static <T> ResponseEntity<DataResponse<T>> badRequest(String message) {
        return ResponseEntity.ok(DataResponse.of(ResponseCode.NOT_VALID.getCode(), message, null));
    }
}
