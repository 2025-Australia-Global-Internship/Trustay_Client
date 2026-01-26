package com.maritel.trustay.dto.res;

import com.maritel.trustay.entity.Post;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class PostRes {
    private Long id;
    private Long communityId;
    private Long sharehouseId;
    private String title;
    private String content;
    private Boolean isNotice;
    private Integer viewCount;
    private Integer likeCount;
    private String authorName;
    private String authorEmail;
    private String profileImageUrl;
    private List<String> imageUrls;
    private LocalDateTime regTime;
    private LocalDateTime modTime;

    public static PostRes from(Post post) {
        return PostRes.builder()
                .id(post.getId())
                .communityId(post.getCommunity() != null ? post.getCommunity().getId() : null)
                .sharehouseId(post.getSharehouseCommunity() != null ? post.getSharehouseCommunity().getSharehouse().getId() : null)
                .title(post.getTitle())
                .content(post.getContent())
                .isNotice(post.getIsNotice())
                .viewCount(post.getViewCount())
                .likeCount(post.getLikeCount())
                .authorName(post.getAuthor().getName())
                .authorEmail(post.getAuthor().getEmail())
                .profileImageUrl(post.getAuthor().getProfile() != null ? post.getAuthor().getProfile().getProfileImageUrl() : null)
                .regTime(post.getRegTime())
                .modTime(post.getModTime())
                .build();
    }

    public static PostRes from(Post post, List<String> imageUrls) {
        PostRes.PostResBuilder builder = PostRes.builder()
                .id(post.getId())
                .communityId(post.getCommunity() != null ? post.getCommunity().getId() : null)
                .sharehouseId(post.getSharehouseCommunity() != null ? post.getSharehouseCommunity().getSharehouse().getId() : null)
                .title(post.getTitle())
                .content(post.getContent())
                .isNotice(post.getIsNotice())
                .viewCount(post.getViewCount())
                .likeCount(post.getLikeCount())
                .authorName(post.getAuthor().getName())
                .authorEmail(post.getAuthor().getEmail())
                .profileImageUrl(post.getAuthor().getProfile() != null ? post.getAuthor().getProfile().getProfileImageUrl() : null)
                .regTime(post.getRegTime())
                .modTime(post.getModTime());

        if (imageUrls != null) {
            builder.imageUrls(imageUrls);
        }

        return builder.build();
    }
}
