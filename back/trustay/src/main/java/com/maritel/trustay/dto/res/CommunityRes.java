package com.maritel.trustay.dto.res;

import com.maritel.trustay.entity.Community;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class CommunityRes {
    private Long id;
    private String name;
    private String description;
    private String imageUrl;
    private Integer memberCount;
    private String ownerName;
    private LocalDateTime regTime;

    public static CommunityRes from(Community community) {
        return CommunityRes.builder()
                .id(community.getId())
                .name(community.getName())
                .description(community.getDescription())
                .imageUrl(community.getImageUrl())
                .memberCount(community.getMemberCount())
                .ownerName(community.getOwner().getName())
                .regTime(community.getRegTime())
                .build();
    }
}
