package com.maritel.trustay.entity;

import com.maritel.trustay.constant.PaymentStatus;
import com.maritel.trustay.constant.PaymentType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;

import java.time.LocalDateTime;

@Entity
@Table(name = "TBL_PAYMENT", uniqueConstraints = {
        @UniqueConstraint(name = "uk_payment_order_id", columnNames = "order_id")
})
@Check(constraints = "amount > 0")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Payment extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "payment_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member; // 돈을 낸 사람

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "contract_id")
    private Contract contract;

    @Column(nullable = false)
    private Long amount;

    /** 집주인/정산 담당 등 실제 이체 대상 계좌 안내 문자열 */
    @Column(nullable = false, length = 100)
    private String targetAccount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private PaymentType type;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private PaymentStatus status = PaymentStatus.PENDING;

    @Column(name = "order_id", nullable = false, length = 100)
    private String orderId;

    @Column(name = "payment_key", length = 200)
    private String paymentKey;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "dutch_pay_group_id")
    private DutchPayGroup dutchPayGroup;

    @Column(nullable = false)
    private LocalDateTime transactionDate;

    @Column(nullable = false)
    private boolean isAutoTransfer = false;

    @Builder
    public Payment(Member member, Long amount, String targetAccount, PaymentType type, Contract contract,
                   String orderId, DutchPayGroup dutchPayGroup) {
        this.member = member;
        this.amount = amount;
        this.targetAccount = targetAccount;
        this.type = type;
        this.contract = contract;
        this.orderId = orderId;
        this.dutchPayGroup = dutchPayGroup;
        this.status = PaymentStatus.PENDING;
        this.transactionDate = LocalDateTime.now();
    }

    public void confirmToss(String paymentKey) {
        this.paymentKey = paymentKey;
        this.status = PaymentStatus.CONFIRMED;
        this.transactionDate = LocalDateTime.now();
    }

    public void markFailed() {
        this.status = PaymentStatus.FAILED;
    }
}
