package com.maritel.trustay.entity;

import com.maritel.trustay.constant.Role;
import jakarta.persistence.*;
import lombok.*;

import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "TBL_PROFILE")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Profile {

    @Id
    private Long memberId;

    @MapsId // Member의 ID를 PK이자 FK로 사용
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id")
    private Member member;

    @Column(length = 25)
    private String birth;

    @Column(length = 25)
    private String phone;

    @Column(length = 25)
    private String gender;

    @Column(length = 255)
    private String address;

    // --- Member에서 이동된 필드 ---
    @ElementCollection(targetClass = Role.class, fetch = FetchType.EAGER)
    @CollectionTable(name = "TBL_PROFILE_ROLES", joinColumns = @JoinColumn(name = "member_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "role") // 테이블 내 컬럼명
    private Set<Role> roles = new HashSet<>();

    @Column(length = 50)
    private String accountInfo; // 정산용 계좌 정보

    // --- 추가된 필드 ---
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "image_id")
    private Image profileImage;

    @Builder
    public Profile(Member member, String birth, String phone, Set<Role> roles, String accountInfo, Image profileImage) {
        this.member = member;
        this.birth = birth;
        this.phone = phone;
        this.roles = roles != null ? roles : new HashSet<>(); // null 방지
        this.accountInfo = accountInfo;
        this.profileImage = profileImage;
    }

    public void updateProfile(String phone, String birth) {
        this.phone = phone;
        this.birth = birth;
    }

    public void updateAccountInfo(String accountInfo) {
        this.accountInfo = accountInfo;
    }

    public void updateProfileImage(Image profileImage) {
        this.profileImage = profileImage;
    }

    public void addRole(Role role) {
        this.roles.add(role);
    }
}