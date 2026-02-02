package com.maritel.trustay.service;

import com.maritel.trustay.dto.req.PostReq;
import com.maritel.trustay.dto.req.PostUpdateReq;
import com.maritel.trustay.dto.res.PostRes;
import com.maritel.trustay.entity.*;
import com.maritel.trustay.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PostService {

    private final PostRepository postRepository;
    private final PostImageRepository postImageRepository;
    private final CommunityRepository communityRepository;
    private final SharehouseCommunityRepository sharehouseCommunityRepository;
    private final SharehouseRepository sharehouseRepository;
    private final MemberRepository memberRepository;
    private final ImageRepository imageRepository;

    /**
     * 게시글 작성
     */
    @Transactional
    public PostRes createPost(String userEmail, PostReq req) {
        Member member = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원 정보를 찾을 수 없습니다."));

        Community community = null;
        SharehouseCommunity sharehouseCommunity = null;

        // 일반 커뮤니티 게시글
        if (req.getCommunityId() != null) {
            community = communityRepository.findById(req.getCommunityId())
                    .orElseThrow(() -> new IllegalArgumentException("커뮤니티를 찾을 수 없습니다."));
        }
        // 쉐어하우스 커뮤니티 게시글
        else if (req.getSharehouseId() != null) {
            Sharehouse sharehouse = sharehouseRepository.findById(req.getSharehouseId())
                    .orElseThrow(() -> new IllegalArgumentException("쉐어하우스를 찾을 수 없습니다."));

            // 쉐어하우스 커뮤니티가 없으면 생성
            sharehouseCommunity = sharehouseCommunityRepository.findBySharehouseId(req.getSharehouseId())
                    .orElseGet(() -> {
                        SharehouseCommunity newSharehouseCommunity = SharehouseCommunity.builder()
                                .sharehouse(sharehouse)
                                .build();
                        return sharehouseCommunityRepository.save(newSharehouseCommunity);
                    });

            // 쉐어하우스 게시글은 집주인만 작성 가능
            if (!sharehouse.getHost().getId().equals(member.getId())) {
                throw new IllegalStateException("쉐어하우스 게시글은 집주인만 작성할 수 있습니다.");
            }
        } else {
            throw new IllegalArgumentException("커뮤니티 ID 또는 쉐어하우스 ID가 필요합니다.");
        }

        Post post = Post.builder()
                .community(community)
                .sharehouseCommunity(sharehouseCommunity)
                .author(member)
                .title(req.getTitle())
                .content(req.getContent())
                .isNotice(req.getIsNotice())
                .build();

        Post savedPost = postRepository.save(post);

        // 이미지 저장
        if (req.getImageUrls() != null && !req.getImageUrls().isEmpty()) {
            List<PostImage> postImages = new ArrayList<>();
            for (int i = 0; i < req.getImageUrls().size(); i++) {
                String url = req.getImageUrls().get(i);

                // 1. 통합 이미지 테이블에 저장
                Image image = imageRepository.save(Image.builder()
                        .imageUrl(url)
                        .build());

                // 2. 연결 테이블(PostImage)에 저장
                PostImage postImage = PostImage.builder()
                        .post(post)
                        .image(image) // URL 대신 Image 객체 참조
                        .displayOrder(i)
                        .build();
                postImages.add(postImage);
            }
            postImageRepository.saveAll(postImages);
        }

        List<String> imageUrls = postImageRepository.findByPostIdOrderByDisplayOrderAsc(savedPost.getId())
                .stream()
                .map(postImage -> postImage.getImage().getImageUrl())
                .collect(Collectors.toList());

        return PostRes.from(savedPost, imageUrls);
    }

    /**
     * 게시글 상세 조회
     */
    @Transactional
    public PostRes getPostDetail(Long postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

        // 조회수 증가
        postRepository.increaseViewCount(postId);
        post.increaseViewCount(); // 엔티티도 업데이트

        List<String> imageUrls = postImageRepository.findByPostIdOrderByDisplayOrderAsc(postId)
                .stream()
                .map(postImage -> postImage.getImage().getImageUrl())
                .collect(Collectors.toList());

        return PostRes.from(post, imageUrls);
    }

    /**
     * 일반 커뮤니티 게시글 목록 조회
     */
    public Page<PostRes> getCommunityPosts(Long communityId, Pageable pageable) {
        Page<Post> posts = postRepository.findByCommunityIdOrderByNoticeAndRegTimeDesc(communityId, pageable);
        return posts.map(post -> {
            List<String> imageUrls = postImageRepository.findByPostIdOrderByDisplayOrderAsc(post.getId())
                    .stream()
                    .map(postImage -> postImage.getImage().getImageUrl())
                    .collect(Collectors.toList());
            return PostRes.from(post, imageUrls);
        });
    }

    /**
     * 쉐어하우스 커뮤니티 게시글 목록 조회
     */
    public Page<PostRes> getSharehouseCommunityPosts(Long sharehouseId, Pageable pageable) {
        // 쉐어하우스 존재 확인
        sharehouseRepository.findById(sharehouseId)
                .orElseThrow(() -> new IllegalArgumentException("쉐어하우스를 찾을 수 없습니다."));

        // 쉐어하우스 커뮤니티가 없으면 빈 페이지 반환
        SharehouseCommunity sharehouseCommunity = sharehouseCommunityRepository.findBySharehouseId(sharehouseId)
                .orElse(null);

        if (sharehouseCommunity == null) {
            return Page.empty(pageable);
        }

        Page<Post> posts = postRepository.findBySharehouseCommunityIdOrderByNoticeAndRegTimeDesc(
                sharehouseCommunity.getId(), pageable);
        return posts.map(post -> {
            List<String> imageUrls = postImageRepository.findByPostIdOrderByDisplayOrderAsc(post.getId())
                    .stream()
                    .map(postImage -> postImage.getImage().getImageUrl())
                    .collect(Collectors.toList());
            return PostRes.from(post, imageUrls);
        });
    }

    /**
     * 전체 게시글 피드 (Posts for you)
     */
    public Page<PostRes> getAllPosts(Pageable pageable) {
        Page<Post> posts = postRepository.findAllCommunityPosts(pageable);
        return posts.map(post -> {
            List<String> imageUrls = postImageRepository.findByPostIdOrderByDisplayOrderAsc(post.getId())
                    .stream()
                    .map(postImage -> postImage.getImage().getImageUrl())
                    .collect(Collectors.toList());
            return PostRes.from(post, imageUrls);
        });
    }

    /**
     * 게시글 수정
     */
    @Transactional
    public void updatePost(String userEmail, Long postId, PostUpdateReq req) {
        Member member = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원 정보를 찾을 수 없습니다."));

        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

        // 권한 확인 로직 (기존과 동일)
        boolean hasPermission = false;
        if (post.getCommunity() != null) {
            hasPermission = post.getAuthor().getId().equals(member.getId());
        } else if (post.getSharehouseCommunity() != null) {
            Sharehouse sharehouse = post.getSharehouseCommunity().getSharehouse();
            hasPermission = sharehouse.getHost().getId().equals(member.getId());
        }

        if (!hasPermission) {
            throw new IllegalStateException("수정 권한이 없습니다.");
        }

        // 1. 게시글 본문 수정
        post.updatePost(req.getTitle(), req.getContent(), req.getIsNotice());

        // 2. 기존 이미지 연결 삭제
        postImageRepository.deleteByPostId(postId);

        // 3. 새 이미지 저장 (수정된 부분)
        if (req.getImageUrls() != null && !req.getImageUrls().isEmpty()) {
            List<PostImage> postImages = new ArrayList<>();

            for (int i = 0; i < req.getImageUrls().size(); i++) {
                String url = req.getImageUrls().get(i);

                // [핵심] 3-1. 공통 이미지 테이블(TBL_IMAGE)에 먼저 저장
                Image imageEntity = imageRepository.save(Image.builder()
                        .imageUrl(url)
                        .build());

                // [핵심] 3-2. 연결 테이블(PostImage)에 Image 객체 전달
                PostImage postImage = PostImage.builder()
                        .post(post)
                        .image(imageEntity) // .imageUrl(url) 대신 .image(imageEntity)
                        .displayOrder(i)
                        .build();

                postImages.add(postImage);
            }
            postImageRepository.saveAll(postImages);
        }
    }

    /**
     * 게시글 삭제
     */
    @Transactional
    public void deletePost(String userEmail, Long postId) {
        Member member = memberRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("회원 정보를 찾을 수 없습니다."));

        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

        // 권한 확인
        boolean hasPermission = false;

        // 일반 커뮤니티: 작성자만 삭제 가능
        if (post.getCommunity() != null) {
            hasPermission = post.getAuthor().getId().equals(member.getId());
        }
        // 쉐어하우스 커뮤니티: 집주인만 삭제 가능
        else if (post.getSharehouseCommunity() != null) {
            Sharehouse sharehouse = post.getSharehouseCommunity().getSharehouse();
            hasPermission = sharehouse.getHost().getId().equals(member.getId());
        }

        if (!hasPermission) {
            throw new IllegalStateException("삭제 권한이 없습니다.");
        }

        // 이미지 삭제
        postImageRepository.deleteByPostId(postId);

        // 게시글 삭제
        postRepository.delete(post);
    }
}
