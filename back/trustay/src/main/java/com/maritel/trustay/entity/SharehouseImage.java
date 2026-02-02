package com.maritel.trustay.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "TBL_SHAREHOUSE_IMAGE")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SharehouseImage extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "house_id")
    private Sharehouse sharehouse;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "image_id")
    private Image image;

    @Builder
    public SharehouseImage(Sharehouse sharehouse, Image image) {
        this.sharehouse = sharehouse;
        this.image = image;
    }
}