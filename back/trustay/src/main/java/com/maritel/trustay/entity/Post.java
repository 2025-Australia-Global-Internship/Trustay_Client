package com.maritel.trustay.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnDefault;

@Entity
@Table(name = "TBL_POST")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Post extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "post_id")
    private Long id;

    // 일반 커뮤니티 게시글 (nullable)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "community_id")
    private Community community;

    // 쉐어하우스 커뮤니티 게시글 (nullable)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sharehouse_community_id")
    private SharehouseCommunity sharehouseCommunity;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id", nullable = false)
    private Member author; // 작성자

    @Column(nullable = false, length = 200)
    private String title; // 제목

    @Lob
    private String content; // 내용

    @ColumnDefault("false")
    private Boolean isNotice = false; // 공지 여부

    @ColumnDefault("0")
    private Integer viewCount = 0; // 조회수

    @ColumnDefault("0")
    private Integer likeCount = 0; // 좋아요 수

    @Builder
    public Post(Community community, SharehouseCommunity sharehouseCommunity,
                Member author, String title, String content, Boolean isNotice) {
        this.community = community;
        this.sharehouseCommunity = sharehouseCommunity;
        this.author = author;
        this.title = title;
        this.content = content;
        this.isNotice = isNotice != null ? isNotice : false;
        this.viewCount = 0;
        this.likeCount = 0;
    }

    public void updatePost(String title, String content, Boolean isNotice) {
        this.title = title;
        this.content = content;
        if (isNotice != null) {
            this.isNotice = isNotice;
        }
    }

    public void increaseViewCount() {
        this.viewCount++;
    }

    public void increaseLikeCount() {
        this.likeCount++;
    }

    public void decreaseLikeCount() {
        if (this.likeCount > 0) {
            this.likeCount--;
        }
    }
}
