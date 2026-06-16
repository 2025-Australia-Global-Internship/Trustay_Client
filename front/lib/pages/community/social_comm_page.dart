import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:front/constants/colors.dart';
import 'package:front/main.dart' show routeObserver;
import 'package:front/models/community_model.dart';
import 'package:front/models/post_model.dart';
import 'package:front/pages/community/community_detail_page.dart';
import 'package:front/pages/community/create_community_page.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/services/community_service.dart';
import 'package:front/services/post_service.dart';
import 'package:front/widgets/confirm_dialog.dart';

class SocialCommPage extends StatefulWidget {
  const SocialCommPage({super.key});

  @override
  State<SocialCommPage> createState() => _SocialCommPageState();
}

class _SocialCommPageState extends State<SocialCommPage> with RouteAware {
  // 내가 가입한 커뮤니티
  List<CommunityModel> _myCommunities = [];
  // 인기 커뮤니티 (Trending)
  List<CommunityModel> _trending = [];
  // Posts for you 피드 게시글
  List<PostModel> _feedPosts = [];

  bool _isLoading = true;
  String? _errorMessage;

  // -------- Posts for you 페이징 상태 --------
  static const int _feedPageSize = 10;
  int _feedNextPage = 0; // 다음에 받아올 페이지 인덱스
  bool _feedHasMore = true; // 마지막 페이지에 도달했는지
  bool _isLoadingMoreFeed = false; // 추가 로드 중인지

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 라우트 옵저버에 구독해 둔다.
    // - 디테일/생성/검색 등 push 되었다가 pop 되어 돌아오면 didPopNext 가 호출된다.
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 스택에 push 된 화면이 pop 되어 이 화면이 다시 보이게 됐을 때 호출.
  ///
  /// 커뮤니티 디테일/생성 화면에서 어떤 변경(가입, 탈퇴, 글 작성, 이미지 변경 등)이
  /// 일어났는지 굳이 결과로 받지 않고, 일괄 새로고침으로 단순화한다.
  @override
  void didPopNext() {
    if (!mounted) return;
    _loadAll();
  }

  /// 바닥에 가까워지면 다음 페이지를 미리 가져온다.
  /// (마지막 ~300px 안쪽으로 들어오면 prefetch)
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMoreFeed();
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _feedNextPage = 0;
      _feedHasMore = true;
    });
    try {
      // 인기 커뮤니티/피드는 로그인 없이도 조회 가능.
      // 내가 가입한 커뮤니티는 토큰 필요. 미로그인 시 빈 리스트로 폴백.
      final results = await Future.wait([
        _safeJoined(),
        CommunityService.fetchTrending(page: 0, size: 10),
        PostService.getFeed(page: 0, size: _feedPageSize),
      ]);

      if (!mounted) return;
      final feed = results[2] as List<PostModel>;
      setState(() {
        _myCommunities = results[0] as List<CommunityModel>;
        _trending = results[1] as List<CommunityModel>;
        _feedPosts = feed;
        _feedNextPage = 1;
        _feedHasMore = feed.length >= _feedPageSize;
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

  /// Posts for you 다음 페이지 가져오기.
  /// - 이미 로딩 중이거나 더 이상 가져올 페이지가 없으면 무시.
  /// - 응답 개수가 페이지 크기 미만이면 마지막 페이지로 마킹.
  Future<void> _loadMoreFeed() async {
    if (_isLoadingMoreFeed || !_feedHasMore || _isLoading) return;
    setState(() => _isLoadingMoreFeed = true);
    try {
      final next = await PostService.getFeed(
        page: _feedNextPage,
        size: _feedPageSize,
      );
      if (!mounted) return;
      setState(() {
        _feedPosts.addAll(next);
        _feedNextPage += 1;
        _feedHasMore = next.length >= _feedPageSize;
        _isLoadingMoreFeed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMoreFeed = false);
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

  /// 현재 로그인 사용자가 [post] 에 대한 삭제 권한이 있는지.
  ///
  /// 서버 정책과 동일하게:
  ///   1) 작성자 본인 (authorEmail == 내 이메일)
  ///   2) 글이 속한 커뮤니티의 오너 (community.ownerMemberId == 내 memberId)
  ///
  /// 피드는 "내가 가입한 커뮤니티"의 글만 내려주므로 [_myCommunities] 에서 매칭이
  /// 가능하다. 오너지만 가입하지 않은 케이스는 없다(오너는 자동 멤버).
  bool _canDeletePost(PostModel post) {
    final me = AuthService.currentUserNotifier.value;
    if (me == null) return false;
    final isAuthor =
        post.authorEmail != null &&
        post.authorEmail!.isNotEmpty &&
        post.authorEmail == me.email;
    bool isOwner = false;
    if (post.communityId != null) {
      for (final c in _myCommunities) {
        if (c.id == post.communityId) {
          isOwner = c.ownerMemberId != null && c.ownerMemberId == me.memberId;
          break;
        }
      }
    }
    return isAuthor || isOwner;
  }

  Future<void> _confirmAndDeletePost(PostModel post) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Delete post',
      message: 'This post will be permanently removed. Continue?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await PostService.deletePost(post.id);
      if (!mounted) return;
      setState(() {
        _feedPosts.removeWhere((e) => e.id == post.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
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
      controller: _scrollController,
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
          ],
        ),
        const SizedBox(height: 18),
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
        const SizedBox(height: 18),

        _buildFeedSection(),

        // 추가 페이지를 가져오는 동안 표시되는 인디케이터.
        // 마지막 페이지에 도달했고 글도 비어있지 않으면 "End of feed" 안내.
        if (_isLoadingMoreFeed)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: green,
                ),
              ),
            ),
          ),

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
        ..._myCommunities.map(
          (c) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openCommunityDetail(c),
            child: _buildCommunityItem(c.imageUrl, c.name),
          ),
        ),
      ],
    );
  }

  /// 커뮤니티 디테일 진입.
  ///
  /// 새로고침은 [didPopNext] 에서 일괄 처리하므로 여기서는 push 만 한다.
  Future<void> _openCommunityDetail(CommunityModel c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommunityDetailPage(communityId: c.id, initial: c),
      ),
    );
  }

  Widget _buildAddCommunity() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openCreateCommunity,
      child: Container(
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
      ),
    );
  }

  /// + 버튼 탭 → CreateCommunityPage 진입.
  ///
  /// 새로고침은 [didPopNext] 에서 일괄 처리하므로 여기서는 push 만 한다.
  Future<void> _openCreateCommunity() async {
    await Navigator.of(context).push<CommunityModel>(
      MaterialPageRoute(builder: (_) => const CreateCommunityPage()),
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
      // Trending = "아직 가입하지 않은 커뮤니티" 중 멤버 수가 많은 순.
      // 비어 있다는 건 보여줄 미가입 커뮤니티가 더 없거나 아직 커뮤니티가 없다는 뜻.
      return Center(
        child: Text(
          _isLoading ? '' : "You've joined every community!",
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
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openCommunityDetail(c),
          child: _buildTrendingCard(
            title: c.name,
            subtitle: _timeAgo(c.regTime).isEmpty
                ? '${c.memberCount} members'
                : 'Active ${_timeAgo(c.regTime)}',
            count: '${c.memberCount}',
            imageUrl: c.imageUrl,
          ),
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
      width: 180,
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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 17, color: grey03),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: grey03,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
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
      // Posts for you = "내가 가입한 커뮤니티"의 게시글만 노출.
      // 가입한 커뮤니티가 아예 없으면 다른 메시지를 보여준다.
      final emptyText = _myCommunities.isEmpty
          ? 'Join a community to see posts here'
          : 'No posts in your communities yet';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            _isLoading ? '' : emptyText,
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

  /// 작성자 / 커뮤니티 오너 전용 더보기 메뉴.
  /// `community_detail_page` 와 동일한 톤을 유지해 일관된 UX 를 제공.
  Widget _buildPostMoreMenu(PostModel post) {
    return SizedBox(
      width: 36,
      height: 28,
      child: PopupMenuButton<String>(
        tooltip: 'More',
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
        icon: SvgPicture.asset(
          'assets/icons/dots-linear.svg',
          width: 24,
          height: 24,
          color: dark,
        ),
        onSelected: (value) {
          if (value == 'delete') _confirmAndDeletePost(post);
        },
        itemBuilder: (_) => const [
          PopupMenuItem<String>(
            value: 'delete',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Color(0xFFE74C3C)),
                SizedBox(width: 10),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _timeAgo(post.regTime),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: grey03,
                      ),
                    ),
                  ],
                ),
              ),
              if (_canDeletePost(post)) _buildPostMoreMenu(post),
            ],
          ),
          const SizedBox(height: 12),
          // 본문만 표시 (타이틀은 노출하지 않는다).
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: dark,
            ),
          ),
          if (hasImage) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 170,
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
                  color: post.likedByMe ? green : dark,
                  width: 16,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _likesLabel(post.likeCount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              SvgPicture.asset('assets/icons/community.svg', width: 16),
              const SizedBox(width: 4),
              Text(
                '${post.commentCount}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
