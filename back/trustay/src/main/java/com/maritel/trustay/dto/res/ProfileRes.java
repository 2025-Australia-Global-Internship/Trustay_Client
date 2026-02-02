package com.maritel.trustay.dto.res;

import com.maritel.trustay.constant.Role;
import com.maritel.trustay.entity.Member;
import com.maritel.trustay.entity.Profile;
import lombok.*;

import java.util.Set;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProfileRes {

    private Long memberId;
    private String email;
    private String name;

    // Profile 정보
    private String birth;
    private String phone;
    private Set<Role> roles;
    private String accountInfo;
    private String profileImageUrl;

    public static ProfileRes from(Member member) {
        Profile profile = member.getProfile();

        return ProfileRes.builder()
                .memberId(member.getId())
                .email(member.getEmail())
                .name(member.getName())
                .birth(profile != null ? profile.getBirth() : null)
                .phone(profile != null ? profile.getPhone() : null)
                .roles(profile != null ? profile.getRoles() : null)
                .accountInfo(profile != null ? profile.getAccountInfo() : null)
                .profileImageUrl(profile != null && profile.getProfileImage() != null
                        ? profile.getProfileImage().getImageUrl() : null)
                .build();
    }
}