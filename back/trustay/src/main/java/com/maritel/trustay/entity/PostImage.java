package com.maritel.trustay.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;

@Entity
@Table(name = "TBL_POST_IMAGE")
@Check(constraints = "display_order >= 0")
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

    // --- 수정한 필드: String imageUrl 대신 Image 엔티티 참조 ---
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "image_id", nullable = false)
    private Image image;

    @Column(nullable = false)
    private Integer displayOrder;

    @Builder
    public PostImage(Post post, Image image, Integer displayOrder) {
        this.post = post;
        this.image = image;
        this.displayOrder = displayOrder;
    }
}