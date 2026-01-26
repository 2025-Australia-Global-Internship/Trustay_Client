package com.maritel.trustay.repository;

import com.maritel.trustay.entity.Post;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PostRepository extends JpaRepository<Post, Long> {

    // 일반 커뮤니티 게시글 목록 (공지 먼저, 최신순)
    @Query("SELECT p FROM Post p WHERE p.community.id = :communityId ORDER BY p.isNotice DESC, p.regTime DESC")
    Page<Post> findByCommunityIdOrderByNoticeAndRegTimeDesc(@Param("communityId") Long communityId, Pageable pageable);

    // 쉐어하우스 커뮤니티 게시글 목록 (공지 먼저, 최신순)
    @Query("SELECT p FROM Post p WHERE p.sharehouseCommunity.id = :sharehouseCommunityId ORDER BY p.isNotice DESC, p.regTime DESC")
    Page<Post> findBySharehouseCommunityIdOrderByNoticeAndRegTimeDesc(@Param("sharehouseCommunityId") Long sharehouseCommunityId, Pageable pageable);

    // 전체 게시글 피드 (최신순)
    @Query("SELECT p FROM Post p WHERE p.community IS NOT NULL ORDER BY p.regTime DESC")
    Page<Post> findAllCommunityPosts(Pageable pageable);

    // 조회수 증가
    @Modifying
    @Query("UPDATE Post p SET p.viewCount = p.viewCount + 1 WHERE p.id = :postId")
    void increaseViewCount(@Param("postId") Long postId);

    // 작성자의 게시글 목록
    List<Post> findByAuthorId(Long authorId);
}
