package com.maritel.trustay.service;

import com.maritel.trustay.dto.req.CommunityReq;
import com.maritel.trustay.dto.res.CommunityRes;
import com.maritel.trustay.entity.Community;
import com.maritel.trustay.entity.CommunityMember;
import com.maritel.trustay.entity.Member;
import com.maritel.trustay.repository.CommunityMemberRepository;
import com.maritel.trustay.repository.CommunityRepository;
import com.maritel.trustay.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CommunityService {

    private final CommunityRepository communityRepository;
    private final CommunityMemberRepository communityMemberRepository;
    private final MemberRepository memberRepository;

    /**
     * 커뮤니티 생성
     */
    @Transactional
    public CommunityRes createCommunity(String userEmail, CommunityReq req) {
        Member member = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원 정보를 찾을 수 없습니다."));

        Community community = Community.builder()
                .owner(member)
                .name(req.getName())
                .description(req.getDescription())
                .imageUrl(req.getImageUrl())
                .build();

        Community savedCommunity = communityRepository.save(community);

        // 생성자는 자동으로 멤버로 추가
        CommunityMember communityMember = CommunityMember.builder()
                .community(savedCommunity)
                .member(member)
                .build();
        communityMemberRepository.save(communityMember);
        savedCommunity.increaseMemberCount();

        return CommunityRes.from(savedCommunity);
    }

    /**
     * 커뮤니티 목록 조회 (검색)
     */
    public Page<CommunityRes> getCommunityList(String keyword, Pageable pageable) {
        Page<Community> communities;
        if (keyword != null && !keyword.isBlank()) {
            communities = communityRepository.findByNameContainingIgnoreCase(keyword, pageable);
        } else {
            communities = communityRepository.findAll(pageable);
        }
        return communities.map(CommunityRes::from);
    }

    /**
     * 인기 커뮤니티 목록 조회
     */
    public Page<CommunityRes> getTrendingCommunities(Pageable pageable) {
        Page<Community> communities = communityRepository.findTrendingCommunities(pageable);
        return communities.map(CommunityRes::from);
    }

    /**
     * 내가 만든 커뮤니티 목록
     */
    public List<CommunityRes> getMyCommunities(String userEmail) {
        Member member = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원 정보를 찾을 수 없습니다."));

        List<Community> communities = communityRepository.findByOwnerId(member.getId());
        return communities.stream()
                .map(CommunityRes::from)
                .collect(Collectors.toList());
    }

    /**
     * 내가 가입한 커뮤니티 목록
     */
    public List<CommunityRes> getJoinedCommunities(String userEmail) {
        Member member = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원 정보를 찾을 수 없습니다."));

        List<CommunityMember> memberships = communityMemberRepository.findByMemberId(member.getId());
        return memberships.stream()
                .map(m -> CommunityRes.from(m.getCommunity()))
                .collect(Collectors.toList());
    }

    /**
     * 커뮤니티 상세 조회
     */
    public CommunityRes getCommunityDetail(Long communityId) {
        Community community = communityRepository.findById(communityId)
                .orElseThrow(() -> new IllegalArgumentException("커뮤니티를 찾을 수 없습니다."));
        return CommunityRes.from(community);
    }

    /**
     * 커뮤니티 가입
     */
    @Transactional
    public void joinCommunity(String userEmail, Long communityId) {
        Member member = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원 정보를 찾을 수 없습니다."));

        Community community = communityRepository.findById(communityId)
                .orElseThrow(() -> new IllegalArgumentException("커뮤니티를 찾을 수 없습니다."));

        // 이미 가입했는지 확인
        if (communityMemberRepository.findByCommunityIdAndMemberId(communityId, member.getId()).isPresent()) {
            throw new IllegalStateException("이미 가입한 커뮤니티입니다.");
        }

        CommunityMember communityMember = CommunityMember.builder()
                .community(community)
                .member(member)
                .build();
        communityMemberRepository.save(communityMember);
        community.increaseMemberCount();
    }

    /**
     * 커뮤니티 탈퇴
     */
    @Transactional
    public void leaveCommunity(String userEmail, Long communityId) {
        Member member = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원 정보를 찾을 수 없습니다."));

        Community community = communityRepository.findById(communityId)
                .orElseThrow(() -> new IllegalArgumentException("커뮤니티를 찾을 수 없습니다."));

        CommunityMember communityMember = communityMemberRepository
                .findByCommunityIdAndMemberId(communityId, member.getId())
                .orElseThrow(() -> new IllegalArgumentException("가입한 커뮤니티가 아닙니다."));

        // 소유자는 탈퇴 불가
        if (community.getOwner().getId().equals(member.getId())) {
            throw new IllegalStateException("커뮤니티 소유자는 탈퇴할 수 없습니다.");
        }

        communityMemberRepository.delete(communityMember);
        community.decreaseMemberCount();
    }

    /**
     * 커뮤니티 수정 (소유자만)
     */
    @Transactional
    public void updateCommunity(String userEmail, Long communityId, CommunityReq req) {
        Member member = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원 정보를 찾을 수 없습니다."));

        Community community = communityRepository.findById(communityId)
                .orElseThrow(() -> new IllegalArgumentException("커뮤니티를 찾을 수 없습니다."));

        // 소유자 확인
        if (!community.getOwner().getId().equals(member.getId())) {
            throw new IllegalStateException("수정 권한이 없습니다.");
        }

        community.updateCommunity(req.getName(), req.getDescription(), req.getImageUrl());
    }

    /**
     * 커뮤니티 삭제 (소유자만)
     */
    @Transactional
    public void deleteCommunity(String userEmail, Long communityId) {
        Member member = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원 정보를 찾을 수 없습니다."));

        Community community = communityRepository.findById(communityId)
                .orElseThrow(() -> new IllegalArgumentException("커뮤니티를 찾을 수 없습니다."));

        // 소유자 확인
        if (!community.getOwner().getId().equals(member.getId())) {
            throw new IllegalStateException("삭제 권한이 없습니다.");
        }

        communityRepository.delete(community);
    }
}
