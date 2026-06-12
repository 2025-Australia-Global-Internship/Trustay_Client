import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:front/constants/colors.dart';
import 'package:front/models/community_model.dart';
import 'package:front/models/post_model.dart';
import 'package:front/services/community_service.dart';
import 'package:front/services/post_service.dart';

class SocialCommPage extends StatefulWidget {
  const SocialCommPage({super.key});

  @override
  State<SocialCommPage> createState() => _SocialCommPageState();
}

class _SocialCommPageState extends State<SocialCommPage> {
  // 내가 가입한 커뮤니티
  List<CommunityModel> _myCommunities = [];
  // 인기 커뮤니티 (Trending)
  List<CommunityModel> _trending = [];
  // 전체 피드 게시글 (Posts for you)
  List<PostModel> _feedPosts = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // 인기 커뮤니티/피드는 로그인 없이도 조회 가능.
      // 내가 가입한 커뮤니티는 토큰 필요. 미로그인 시 빈 리스트로 폴백.
      final results = await Future.wait([
        _safeJoined(),
        CommunityService.fetchTrending(page: 0, size: 10),
        PostService.getFeed(page: 0, size: 20),
      ]);

      if (!mounted) return;
      setState(() {
        _myCommunities = results[0] as List<CommunityModel>;
        _trending = results[1] as List<CommunityModel>;
        _feedPosts = results[2] as List<PostModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '데이터를 불러오지 못했어요.';
        _isLoading = false;
      });
    }
  }

  // 미로그인 등으로 실패 시 빈 리스트 반환
  Future<List<CommunityModel>> _safeJoined() async {
    try {
      return await CommunityService.fetchJoined();
    } catch (_) {
      return <CommunityModel>[];
    }
  }

  Future<void> _onTapLike(PostModel post) async {
    try {
      final result = await PostService.toggleLike(post.id);
      if (!mounted) return;
      setState(() {
        post.likedByMe = result.liked;
        post.likeCount = result.likeCount;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('좋아요 처리 실패')));
    }
  }

  /// ISO8601 → "8 hours ago" 형태로 변환
  String _timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final raw = iso.endsWith('Z') ? iso : '${iso}Z';
      final time = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(time);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return DateFormat('MM/dd').format(time);
    } catch (_) {
      return '';
    }
  }

  String _likesLabel(int count) {
    if (count >= 1000) {
      final k = (count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1);
      return '${k}k';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: green,
          onRefresh: _loadAll,
          child: _isLoading && _feedPosts.isEmpty
              ? const Center(child: CircularProgressIndicator(color: green))
              : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      children: [
        if (_errorMessage != null) ...[
          Center(
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 13, color: grey03),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // My community section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'My community',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(height: 100, child: _buildMyCommunityList()),
        const SizedBox(height: 24),

        // Trending section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trending',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'See all',
                style: TextStyle(
                  color: green,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(height: 180, child: _buildTrendingList()),

        const SizedBox(height: 36),

        // Posts for you
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Posts for you',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildFeedSection(),

        const SizedBox(height: 100),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // My community
  // ---------------------------------------------------------------------------
  Widget _buildMyCommunityList() {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _buildAddCommunity(),
        ..._myCommunities.map((c) => _buildCommunityItem(c.imageUrl, c.name)),
      ],
    );
  }

  Widget _buildAddCommunity() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 70,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: green, width: 1.2),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/plus.svg',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                color: green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityItem(String? imageUrl, String label) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 70,
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey[300],
            backgroundImage: hasImage
                ? NetworkImage(imageUrl) as ImageProvider
                : const AssetImage('assets/icons/default.png'),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkgreen,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Trending
  // ---------------------------------------------------------------------------
  Widget _buildTrendingList() {
    if (_trending.isEmpty) {
      return Center(
        child: Text(
          _isLoading ? '' : 'No trending communities',
          style: const TextStyle(
            fontSize: 13,
            color: grey03,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: _trending.length,
      itemBuilder: (context, index) {
        final c = _trending[index];
        return _buildTrendingCard(
          title: c.name,
          subtitle: _timeAgo(c.regTime).isEmpty
              ? '${c.memberCount} members'
              : 'Active ${_timeAgo(c.regTime)}',
          count: '${c.memberCount}',
          imageUrl: c.imageUrl,
        );
      },
    );
  }

  Widget _buildTrendingCard({
    required String title,
    required String subtitle,
    required String count,
    String? imageUrl,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 110,
                        errorBuilder: (_, __, ___) => Container(
                          height: 110,
                          color: grey01,
                          child: const Center(
                            child: Icon(Icons.image, color: grey02),
                          ),
                        ),
                      )
                    : Container(
                        height: 110,
                        color: grey01,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),

            Positioned(
              bottom: 69,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: yellow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/social.svg',
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 11,
              left: 13,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: grey03),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: grey03,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Posts for you (feed)
  // ---------------------------------------------------------------------------
  Widget _buildFeedSection() {
    if (_feedPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            _isLoading ? '' : 'No posts yet',
            style: const TextStyle(
              fontSize: 13,
              color: grey03,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return Column(children: _feedPosts.map(_buildPostCard).toList());
  }

  Widget _buildPostCard(PostModel post) {
    final imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasAvatar =
        post.profileImageUrl != null && post.profileImageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[300],
                backgroundImage: hasAvatar
                    ? NetworkImage(post.profileImageUrl!) as ImageProvider
                    : const AssetImage('assets/icons/default.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName.isEmpty ? 'Unknown' : post.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _timeAgo(post.regTime),
                      style: const TextStyle(fontSize: 12, color: grey03),
                    ),
                  ],
                ),
              ),
              Baseline(
                baseline: 8,
                baselineType: TextBaseline.alphabetic,
                child: SvgPicture.asset(
                  'assets/icons/dots-linear.svg',
                  width: 28,
                  height: 28,
                  color: dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (post.title.isNotEmpty) ...[
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: dark,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w400,
              color: dark,
            ),
          ),
          if (hasImage) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: grey01,
                    child: const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: () => _onTapLike(post),
                child: SvgPicture.asset(
                  'assets/icons/heart.svg',
                  color: post.likedByMe ? Colors.redAccent : null,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _likesLabel(post.likeCount),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 16),
              SvgPicture.asset(
                'assets/icons/community.svg',
                width: 21,
                height: 21,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.commentCount}',
                style: const TextStyle(fontSize: 14),
              ),
              const Spacer(),
              SvgPicture.asset(
                'assets/icons/bookmark.svg',
                width: 19,
                height: 19,
                color: dark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
