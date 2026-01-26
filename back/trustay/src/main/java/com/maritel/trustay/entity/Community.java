package com.maritel.trustay.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnDefault;

@Entity
@Table(name = "TBL_COMMUNITY")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Community extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "community_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    private Member owner; // 커뮤니티 생성자

    @Column(nullable = false, length = 100)
    private String name; // 커뮤니티 이름

    @Lob
    private String description; // 커뮤니티 설명

    @Column(length = 500)
    private String imageUrl; // 커뮤니티 대표 이미지

    @ColumnDefault("0")
    private Integer memberCount = 0; // 멤버 수

    @Builder
    public Community(Member owner, String name, String description, String imageUrl) {
        this.owner = owner;
        this.name = name;
        this.description = description;
        this.imageUrl = imageUrl;
        this.memberCount = 0;
    }

    public void updateCommunity(String name, String description, String imageUrl) {
        this.name = name;
        this.description = description;
        this.imageUrl = imageUrl;
    }

    public void increaseMemberCount() {
        this.memberCount++;
    }

    public void decreaseMemberCount() {
        if (this.memberCount > 0) {
            this.memberCount--;
        }
    }
}
