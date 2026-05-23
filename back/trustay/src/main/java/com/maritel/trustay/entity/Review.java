package com.maritel.trustay.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;

@Entity
@Table(name = "TBL_REVIEW")
@Check(constraints = "rating BETWEEN 1 AND 5")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Review extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "review_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id", nullable = false)
    private Member author; // 작성자

    // 리뷰 대상이 '집'일 수도 있고 '사람'일 수도 있음
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "target_house_id", nullable = true)
    private Sharehouse targetHouse;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "target_member_id", nullable = true)
    private Member targetMember;

    @Column(nullable = false)
    private Integer rating; // 1~5점

    @Column(columnDefinition = "TEXT")
    private String content;

    @Builder
    public Review(Member author, Sharehouse targetHouse, Integer rating, String content) {
        this.author = author;
        this.targetHouse = targetHouse;
        this.rating = rating;
        this.content = content;
    }
}