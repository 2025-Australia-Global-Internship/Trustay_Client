package com.maritel.trustay.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.maritel.trustay.client.TossPaymentsApiException;
import com.maritel.trustay.client.TossPaymentsClient;
import com.maritel.trustay.config.TossPaymentsProperties;
import com.maritel.trustay.constant.PaymentStatus;
import com.maritel.trustay.constant.PaymentType;
import com.maritel.trustay.dto.req.DutchPayCreateReq;
import com.maritel.trustay.dto.req.PaymentConfirmReq;
import com.maritel.trustay.dto.req.RentPaymentPrepareReq;
import com.maritel.trustay.dto.res.*;
import com.maritel.trustay.entity.Contract;
import com.maritel.trustay.entity.DutchPayGroup;
import com.maritel.trustay.entity.Member;
import com.maritel.trustay.entity.Payment;
import com.maritel.trustay.entity.Profile;
import com.maritel.trustay.repository.ContractRepository;
import com.maritel.trustay.repository.DutchPayGroupRepository;
import com.maritel.trustay.repository.MemberRepository;
import com.maritel.trustay.repository.PaymentRepository;
import com.maritel.trustay.util.AmountSplitUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PaymentService {

    public static final String SETTLEMENT_GUIDE_RENT =
            "토스는 테스트 결제만 수행합니다. 실제 월세·임대료는 표시된 집주인 계좌로 직접 이체해 주세요.";
    public static final String SETTLEMENT_GUIDE_DUTCH =
            "토스는 테스트 결제만 수행합니다. 실제 N빵 정산금은 표시된 수금인 계좌로 직접 이체해 주세요.";

    private static final String ACCOUNT_NOT_SET = "(계좌 미등록) 프로필에 정산 계좌를 입력해 주세요.";

    private final MemberRepository memberRepository;
    private final ContractRepository contractRepository;
    private final DutchPayGroupRepository dutchPayGroupRepository;
    private final PaymentRepository paymentRepository;
    private final TossPaymentsClient tossPaymentsClient;
    private final TossPaymentsProperties tossPaymentsProperties;

    public TossClientConfigRes getTossClientConfig() {
        if (!StringUtils.hasText(tossPaymentsProperties.getClientKey())) {
            throw new IllegalStateException("toss.payments.client-key 가 비어 있습니다.");
        }
        return TossClientConfigRes.builder()
                .clientKey(tossPaymentsProperties.getClientKey())
                .build();
    }

    @Transactional
    public PaymentPrepareRes prepareRentPayment(String memberEmail, RentPaymentPrepareReq req) {
        Member tenant = memberRepository.findByEmail(memberEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원을 찾을 수 없습니다."));
        Contract contract = contractRepository.findByIdForPayment(req.getContractId())
                .orElseThrow(() -> new IllegalArgumentException("계약을 찾을 수 없습니다."));
        if (!contract.getTenant().getId().equals(tenant.getId())) {
            throw new IllegalArgumentException("해당 계약의 세입자만 월세 결제를 준비할 수 있습니다.");
        }
        Profile landlordProfile = contract.getLandlord().getProfile();
        String targetAccount = resolveAccountDisplay(landlordProfile);

        String orderId = "TSY-R-" + UUID.randomUUID().toString().replace("-", "");
        Payment payment = Payment.builder()
                .member(tenant)
                .amount(req.getAmount())
                .targetAccount(targetAccount)
                .type(PaymentType.RENT)
                .contract(contract)
                .orderId(orderId)
                .dutchPayGroup(null)
                .build();
        paymentRepository.save(payment);

        return PaymentPrepareRes.builder()
                .paymentId(payment.getId())
                .orderId(orderId)
                .amount(req.getAmount())
                .paymentType(PaymentType.RENT)
                .targetAccount(targetAccount)
                .settlementGuide(SETTLEMENT_GUIDE_RENT)
                .build();
    }

    @Transactional
    public DutchPayCreateRes createDutchPay(String creatorEmail, DutchPayCreateReq req) {
        Member creator = memberRepository.findByEmail(creatorEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원을 찾을 수 없습니다."));

        List<Long> memberIds = req.getMemberIds();
        if (memberIds.size() < 2) {
            throw new IllegalArgumentException("N빵 참여자는 2명 이상이어야 합니다.");
        }
        if (new HashSet<>(memberIds).size() != memberIds.size()) {
            throw new IllegalArgumentException("memberIds 에 중복이 있습니다.");
        }
        if (!memberIds.contains(req.getPayeeMemberId())) {
            throw new IllegalArgumentException("payeeMemberId 는 memberIds 에 포함되어야 합니다.");
        }

        List<Member> members = memberRepository.findAllById(new HashSet<>(memberIds));
        if (members.size() != memberIds.size()) {
            throw new IllegalArgumentException("존재하지 않는 회원 ID 가 포함되어 있습니다.");
        }
        Map<Long, Member> byId = members.stream().collect(Collectors.toMap(Member::getId, m -> m));

        Member payee = byId.get(req.getPayeeMemberId());
        String targetAccount = resolveAccountDisplay(payee.getProfile());

        Contract contract = null;
        if (req.getContractId() != null) {
            contract = contractRepository.findById(req.getContractId())
                    .orElseThrow(() -> new IllegalArgumentException("계약을 찾을 수 없습니다."));
        }

        DutchPayGroup group = DutchPayGroup.builder()
                .createdBy(creator)
                .payee(payee)
                .contract(contract)
                .title(req.getTitle())
                .totalAmount(req.getTotalAmount())
                .build();
        dutchPayGroupRepository.save(group);

        long[] shares = AmountSplitUtils.splitEvenly(req.getTotalAmount(), memberIds.size());
        List<DutchPaySplitItemRes> splits = new ArrayList<>();

        for (int i = 0; i < memberIds.size(); i++) {
            Long mid = memberIds.get(i);
            Member member = byId.get(mid);
            String orderId = "TSY-D" + group.getId() + "-" + mid + "-" + UUID.randomUUID().toString().substring(0, 8);
            Payment payment = Payment.builder()
                    .member(member)
                    .amount(shares[i])
                    .targetAccount(targetAccount)
                    .type(PaymentType.DUTCH)
                    .contract(contract)
                    .orderId(orderId)
                    .dutchPayGroup(group)
                    .build();
            paymentRepository.save(payment);
            splits.add(DutchPaySplitItemRes.builder()
                    .paymentId(payment.getId())
                    .memberId(mid)
                    .amount(shares[i])
                    .orderId(orderId)
                    .targetAccount(targetAccount)
                    .build());
        }

        return DutchPayCreateRes.builder()
                .dutchPayGroupId(group.getId())
                .splits(splits)
                .settlementGuide(SETTLEMENT_GUIDE_DUTCH)
                .build();
    }

    @Transactional
    public PaymentConfirmRes confirmPayment(String memberEmail, PaymentConfirmReq req) {
        Member member = memberRepository.findByEmail(memberEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원을 찾을 수 없습니다."));
        Payment payment = paymentRepository.findByOrderId(req.getOrderId())
                .orElseThrow(() -> new IllegalArgumentException("결제 건을 찾을 수 없습니다."));
        if (!payment.getMember().getId().equals(member.getId())) {
            throw new IllegalArgumentException("본인 결제만 승인할 수 있습니다.");
        }
        if (!payment.getAmount().equals(req.getAmount())) {
            throw new IllegalArgumentException("금액이 일치하지 않습니다.");
        }
        if (payment.getStatus() != PaymentStatus.PENDING) {
            throw new IllegalArgumentException("이미 처리된 결제입니다.");
        }

        try {
            JsonNode tossBody = tossPaymentsClient.confirmPayment(
                    req.getPaymentKey(), req.getOrderId(), req.getAmount());
            payment.confirmToss(req.getPaymentKey());
            String tossStatus = tossBody != null && tossBody.has("status")
                    ? tossBody.get("status").asText()
                    : null;
            return PaymentConfirmRes.builder()
                    .paymentId(payment.getId())
                    .orderId(payment.getOrderId())
                    .status(payment.getStatus())
                    .paymentType(payment.getType())
                    .tossPaymentStatus(tossStatus)
                    .build();
        } catch (TossPaymentsApiException e) {
            // 승인 실패 시 트랜잭션 롤백 → 결제 건은 PENDING 유지(재시도 가능)
            throw e;
        }
    }

    public List<PendingPaymentRes> listMyPendingPayments(String memberEmail) {
        Member member = memberRepository.findByEmail(memberEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원을 찾을 수 없습니다."));
        return paymentRepository.findByMember_IdAndStatusOrderByRegTimeDesc(member.getId(), PaymentStatus.PENDING)
                .stream()
                .map(p -> PendingPaymentRes.builder()
                        .paymentId(p.getId())
                        .orderId(p.getOrderId())
                        .amount(p.getAmount())
                        .paymentType(p.getType())
                        .targetAccount(p.getTargetAccount())
                        .dutchPayGroupId(p.getDutchPayGroup() != null ? p.getDutchPayGroup().getId() : null)
                        .build())
                .toList();
    }

    private static String resolveAccountDisplay(Profile profile) {
        if (profile != null && StringUtils.hasText(profile.getAccountInfo())) {
            return profile.getAccountInfo().trim();
        }
        return ACCOUNT_NOT_SET;
    }
}
