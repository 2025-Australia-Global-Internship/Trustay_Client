package com.maritel.trustay.repository;

import com.maritel.trustay.entity.CommunityMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CommunityMemberRepository extends JpaRepository<CommunityMember, Long> {

    // 커뮤니티에 가입한 멤버 목록
    List<CommunityMember> findByCommunityId(Long communityId);

    // 사용자가 가입한 커뮤니티 목록
    List<CommunityMember> findByMemberId(Long memberId);

    // 특정 사용자가 특정 커뮤니티에 가입했는지 확인
    Optional<CommunityMember> findByCommunityIdAndMemberId(Long communityId, Long memberId);

    // 커뮤니티 멤버 수 조회
    long countByCommunityId(Long communityId);
}
