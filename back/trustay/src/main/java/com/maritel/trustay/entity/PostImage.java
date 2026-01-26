package com.maritel.trustay.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "TBL_POST_IMAGE")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PostImage extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "post_image_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", nullable = false)
    private Post post;

    @Column(nullable = false, length = 500)
    private String imageUrl; // 이미지 URL

    @Column(nullable = false)
    private Integer displayOrder; // 이미지 순서

    @Builder
    public PostImage(Post post, String imageUrl, Integer displayOrder) {
        this.post = post;
        this.imageUrl = imageUrl;
        this.displayOrder = displayOrder;
    }
}
