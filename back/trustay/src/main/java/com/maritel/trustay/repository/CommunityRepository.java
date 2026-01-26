package com.maritel.trustay.repository;

import com.maritel.trustay.entity.Community;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CommunityRepository extends JpaRepository<Community, Long> {

    // 내가 만든 커뮤니티 목록
    List<Community> findByOwnerId(Long ownerId);

    // 이름으로 검색
    Page<Community> findByNameContainingIgnoreCase(String keyword, Pageable pageable);

    // 인기 커뮤니티 (멤버 수 기준)
    @Query("SELECT c FROM Community c ORDER BY c.memberCount DESC")
    Page<Community> findTrendingCommunities(Pageable pageable);
}
