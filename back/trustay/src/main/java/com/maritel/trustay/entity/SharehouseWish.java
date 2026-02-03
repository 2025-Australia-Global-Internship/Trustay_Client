package com.maritel.trustay.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "TBL_SHAREHOUSE_WISH", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"member_id", "house_id"})
})
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SharehouseWish extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "sharehouse_wish_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "house_id", nullable = false)
    private Sharehouse sharehouse;

    @Builder
    public SharehouseWish(Member member, Sharehouse sharehouse) {
        this.member = member;
        this.sharehouse = sharehouse;
    }
}
