package com.maritel.trustay.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "TBL_SHAREHOUSE_COMMUNITY")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SharehouseCommunity extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "sharehouse_community_id")
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "house_id", nullable = false, unique = true)
    private Sharehouse sharehouse; // 쉐어하우스와 1:1 관계

    @Builder
    public SharehouseCommunity(Sharehouse sharehouse) {
        this.sharehouse = sharehouse;
    }
}
