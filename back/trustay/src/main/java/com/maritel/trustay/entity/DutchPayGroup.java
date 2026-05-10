package com.maritel.trustay.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;

@Entity
@Table(name = "TBL_DUTCH_PAY_GROUP")
@Check(constraints = "total_amount > 0")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class DutchPayGroup extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "dutch_pay_group_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_member_id", nullable = false)
    private Member createdBy;

    /** 실제로 모인 돈을 받는 사람(동료들이 이 계좌로 보냄) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payee_member_id", nullable = false)
    private Member payee;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "contract_id")
    private Contract contract;

    @Column(length = 200)
    private String title;

    @Column(nullable = false)
    private Long totalAmount;

    @Builder
    public DutchPayGroup(Member createdBy, Member payee, Contract contract, String title, Long totalAmount) {
        this.createdBy = createdBy;
        this.payee = payee;
        this.contract = contract;
        this.title = title;
        this.totalAmount = totalAmount;
    }
}
