import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:front/constants/colors.dart';
import 'package:front/main.dart' show routeObserver;
import 'package:front/models/community_member_model.dart';
import 'package:front/models/community_model.dart';
import 'package:front/models/post_model.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/services/community_service.dart';
import 'package:front/services/post_service.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/confirm_dialog.dart';
import 'package:front/widgets/gradient_layout.dart';

import 'community_post_create_page.dart';

/// 단일 커뮤니티 상세 화면.
///
/// 디자인:
/// - 헤더: 뒤로가기 / 더보기(...) 버튼.
/// - 상단 큰 원형 커뮤니티 아바타.
/// - 이름 / "Category | N Member(s)".
/// - 멤버가 없으면 작은 + 버튼만, 있으면 멤버 아바타 4개 + invite "+".
/// - 탭: Discussions / Albums.
/// - Discussions: 필터 바 (Filter / Month / Year) + 게시글 카드 무한 스크롤.
/// - Albums: 모든 게시글의 이미지를 모아 그리드로.
/// - 우하단 펜 FAB → 새 글 작성.
class CommunityDetailPage extends StatefulWidget {
  final int communityId;

  /// 빠른 첫 페인트를 위한 초기 모델 (옵션).
  final CommunityModel? initial;

  const CommunityDetailPage({
    super.key,
    required this.communityId,
    this.initial,
  });

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage>
    with SingleTickerProviderStateMixin, RouteAware {
  // ---------------------------------------------------------------------------
  // 데이터 상태
  // ---------------------------------------------------------------------------
  CommunityModel? _community;
  List<CommunityMemberModel> _members = [];

  // 게시글 페이징 (Discussions 탭)
  static const int _postPageSize = 10;
  final List<PostModel> _posts = [];
  int _postNextPage = 0;
  bool _postHasMore = true;
  bool _isLoadingPosts = false;
  bool _isLoadingMorePosts = false;
  String? _postError;

  // 앨범 페이징 (Albums 탭, 사진만)
  // - Discussions 와 동일한 게시글 API 를 쓰지만 size 가 다르다(15).
  // - 첫 진입(=Albums 탭 첫 활성화) 시 lazy 로 로드한다.
  static const int _albumPageSize = 15;
  final List<PostModel> _albumPosts = [];
  int _albumNextPage = 0;
  bool _albumHasMore = true;
  bool _isLoadingAlbums = false;
  bool _isLoadingMoreAlbums = false;
  bool _albumsInitialized = false;

  // 필터
  int? _filterMonth;
  int? _filterYear;

  // 탭 컨트롤러 (Discussions / Albums)
  late final TabController _tabController;

  // 무한 스크롤
  final ScrollController _scrollController = ScrollController();

  // 커뮤니티 이미지 변경 (오너 전용)
  final ImagePicker _picker = ImagePicker();
  bool _isUpdatingImage = false;

  // 가입(+) 버튼 진행 중 상태. 더블탭 방지용.
  bool _isJoining = false;

  /// 글 작성 페이지에서 돌아오는 흐름은 [_onTapWritePost] 가 직접 갱신을 처리한다.
  /// 그래서 그 한 번의 [didPopNext] 자동 갱신은 건너뛰어, 작성한 글이 두 번
  /// 표시되지 않도록 한다 (insert + refetch 중복 방지).
  bool _skipNextDidPopNextRefresh = false;

  @override
  void initState() {
    super.initState();
    _community = widget.initial;
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// 글쓰기 / 멤버 시트 / 이미지 변경 등 push 된 화면에서 돌아오면
  /// 헤더 + 현재 탭의 첫 페이지를 다시 받는다.
  ///
  /// 단, 글 작성 흐름은 [_onTapWritePost] 가 자체적으로 optimistic insert +
  /// 헤더/앨범 갱신을 모두 처리하므로 한 번 건너뛴다.
  @override
  void didPopNext() {
    if (!mounted) return;
    if (_skipNextDidPopNextRefresh) {
      _skipNextDidPopNextRefresh = false;
      return;
    }
    _loadHeader();
    if (_tabController.index == 0) {
      _loadFirstPostPage();
    } else {
      _albumsInitialized = false;
      _albumPosts.clear();
      _loadFirstAlbumPage();
    }
  }

  void _onTabChanged() {
    // 탭 인디케이터 색을 갱신하기 위해 setState.
    if (mounted) setState(() {});
    // Albums 탭에 처음 진입한 경우에 한해서만 lazy 로드.
    if (_tabController.index == 1 && !_albumsInitialized) {
      _loadFirstAlbumPage();
    }
  }

  /// 활성 탭 기준으로 무한 스크롤 분기.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      if (_tabController.index == 0) {
        _loadMorePosts();
      } else {
        _loadMoreAlbums();
      }
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadHeader(), _loadFirstPostPage()]);
  }

  Future<void> _loadHeader() async {
    try {
      final results = await Future.wait([
        CommunityService.fetchCommunity(widget.communityId),
        CommunityService.fetchMembers(widget.communityId, page: 0, size: 10),
      ]);
      if (!mounted) return;
      setState(() {
        _community = results[0] as CommunityModel;
        _members = results[1] as List<CommunityMemberModel>;
      });
    } catch (_) {
      // 헤더 로드 실패해도 게시글은 따로 보여줄 수 있도록 silent.
    }
  }

  Future<void> _loadFirstPostPage() async {
    setState(() {
      _isLoadingPosts = true;
      _postError = null;
      _postNextPage = 0;
      _postHasMore = true;
      _posts.clear();
    });
    try {
      final list = await PostService.getCommunityPosts(
        widget.communityId,
        page: 0,
        size: _postPageSize,
      );
      if (!mounted) return;
      setState(() {
        _posts.addAll(list);
        _postNextPage = 1;
        _postHasMore = list.length >= _postPageSize;
        _isLoadingPosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postError = '게시글을 불러오지 못했어요.';
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMorePosts || !_postHasMore || _isLoadingPosts) return;
    setState(() => _isLoadingMorePosts = true);
    try {
      final list = await PostService.getCommunityPosts(
        widget.communityId,
        page: _postNextPage,
        size: _postPageSize,
      );
      if (!mounted) return;
      setState(() {
        _posts.addAll(list);
        _postNextPage += 1;
        _postHasMore = list.length >= _postPageSize;
        _isLoadingMorePosts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMorePosts = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Albums 페이징
  // ---------------------------------------------------------------------------
  Future<void> _loadFirstAlbumPage() async {
    setState(() {
      _isLoadingAlbums = true;
      _albumPosts.clear();
      _albumNextPage = 0;
      _albumHasMore = true;
    });
    try {
      final list = await PostService.getCommunityPosts(
        widget.communityId,
        page: 0,
        size: _albumPageSize,
      );
      if (!mounted) return;
      setState(() {
        _albumPosts.addAll(list);
        _albumNextPage = 1;
        _albumHasMore = list.length >= _albumPageSize;
        _isLoadingAlbums = false;
        _albumsInitialized = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingAlbums = false;
        _albumsInitialized = true;
      });
    }
  }

  Future<void> _loadMoreAlbums() async {
    if (_isLoadingMoreAlbums || !_albumHasMore || _isLoadingAlbums) return;
    setState(() => _isLoadingMoreAlbums = true);
    try {
      final list = await PostService.getCommunityPosts(
        widget.communityId,
        page: _albumNextPage,
        size: _albumPageSize,
      );
      if (!mounted) return;
      setState(() {
        _albumPosts.addAll(list);
        _albumNextPage += 1;
        _albumHasMore = list.length >= _albumPageSize;
        _isLoadingMoreAlbums = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMoreAlbums = false);
    }
  }

  Future<void> _refresh() async {
    // 풀 투 리프레시 시 두 탭 모두 무효화하고 현재 탭 데이터를 다시 불러온다.
    _albumsInitialized = false;
    _albumPosts.clear();
    await _loadAll();
    if (_tabController.index == 1) {
      await _loadFirstAlbumPage();
    }
  }

  Future<void> _onTapWritePost() async {
    // pop 시 호출되는 didPopNext 의 자동 갱신을 한 번 건너뛰도록 미리 표식.
    // (push 결과가 await 로 돌아오기 전에 didPopNext 가 먼저 호출될 수 있으므로
    //  반드시 push 호출 전에 세팅해야 한다.)
    _skipNextDidPopNextRefresh = true;
    final created = await Navigator.of(context).push<PostModel>(
      MaterialPageRoute(
        builder: (_) =>
            CommunityPostCreatePage(communityId: widget.communityId),
      ),
    );
    if (!mounted) return;
    if (created != null) {
      // 새 글이 만들어지면 Discussions 목록 맨 앞에 끼워 넣고,
      // Albums 캐시는 무효화해 다음 진입 시 새 사진까지 반영되도록 한다.
      setState(() {
        _posts.insert(0, created);
        _albumsInitialized = false;
        _albumPosts.clear();
      });
      _loadHeader();
      // 사용자가 이미 Albums 탭을 보고 있다면 즉시 재로드.
      if (_tabController.index == 1) {
        _loadFirstAlbumPage();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 빌드
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFFFAFAFA),
      body: GradientLayout(
        child: SizedBox.expand(
          child: RefreshIndicator(
            color: green,
            onRefresh: _refresh,
            child: NestedScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(child: _buildTopBar()),
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildTabBar()),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [_buildDiscussionsTab(), _buildAlbumsTab()],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildPencilFab(),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar (back / more)
  // ---------------------------------------------------------------------------
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleIconButton(
            asset: 'assets/icons/arrow_back.svg',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          _circleIconButton(
            iconWidget: const Icon(Icons.more_horiz, size: 22, color: dark),
            onTap: _onTapMore,
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    String? asset,
    Widget? iconWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child:
              iconWidget ??
              SvgPicture.asset(asset!, width: 18, height: 18, color: dark),
        ),
      ),
    );
  }

  /// 현재 사용자가 이 커뮤니티의 오너인지.
  bool get _isOwner {
    final me = AuthService.currentUserNotifier.value?.memberId;
    final ownerId = _community?.ownerMemberId;
    return me != null && ownerId != null && me == ownerId;
  }

  /// 현재 사용자가 이 커뮤니티의 멤버(=가입자)인지.
  ///
  /// 서버 [CommunityRes.joinedByMe] 가 1차 출처이고, 오너는 항상 멤버이므로 true.
  /// 미로그인이면 false.
  bool get _isMember {
    if (AuthService.currentUserNotifier.value?.memberId == null) return false;
    if (_isOwner) return true;
    return _community?.joinedByMe ?? false;
  }

  /// "+ 가입" FAB 탭 → 서버에 가입 요청 후 헤더 갱신.
  Future<void> _onTapJoin() async {
    if (_isJoining) return;
    if (AuthService.currentUserNotifier.value?.memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to join a community.')),
      );
      return;
    }
    setState(() => _isJoining = true);
    try {
      await CommunityService.join(widget.communityId);
      if (!mounted) return;
      // 가입 직후엔 캐시된 _community.joinedByMe 가 false 이므로
      // 즉시 정정해 FAB 가 펜슬로 바뀌도록 한다. 멤버 카운트도 +1.
      final cached = _community;
      if (cached != null) {
        _community = CommunityModel(
          id: cached.id,
          name: cached.name,
          description: cached.description,
          imageUrl: cached.imageUrl,
          category: cached.category,
          memberCount: cached.memberCount + 1,
          ownerMemberId: cached.ownerMemberId,
          ownerName: cached.ownerName,
          regTime: cached.regTime,
          joinedByMe: true,
        );
      }
      setState(() {});
      // 서버에서 다시 정확한 값(멤버 수, 본인 포함된 멤버 목록 등)을 받아온다.
      await _loadHeader();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Joined the community.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Join failed: $e')));
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _onTapMore() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: grey01,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.group_outlined, color: dark),
                title: const Text(
                  'Members',
                  style: TextStyle(fontWeight: FontWeight.w700, color: dark),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openMembersSheet();
                },
              ),
              // 비멤버는 가입할 게 아니라면 '나갈' 것도 없으니 leave 옵션을 감춘다.
              // 오너는 항상 멤버이므로 _isMember 가 true → 옵션이 노출된다.
              if (_isMember)
                ListTile(
                  leading: Icon(
                    _isOwner ? Icons.delete_outline : Icons.exit_to_app,
                    color: _isOwner ? Colors.redAccent : dark,
                  ),
                  title: Text(
                    _isOwner ? 'Delete community' : 'Leave community',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _isOwner ? Colors.redAccent : dark,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _confirmAndLeave();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndLeave() async {
    // 오너인지 / 마지막 멤버인지에 따라 메시지를 다르게.
    final memberCount = _community?.memberCount ?? 0;
    final isOwner = _isOwner;
    String title;
    String body;
    String confirmLabel;
    if (isOwner) {
      if (memberCount > 1) {
        // 서버가 거절하지만 클라이언트에서도 미리 안내.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Remove all other members before deleting this community.',
            ),
          ),
        );
        return;
      }
      title = 'Delete community?';
      body =
          "You're the only member left. The community will be deleted permanently.";
      confirmLabel = 'Delete';
    } else {
      title = 'Leave community?';
      body = 'You can join again later.';
      confirmLabel = 'Leave';
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CommunityService.leave(widget.communityId);
      if (!mounted) return;
      Navigator.of(context).pop<bool>(true); // 호출 측에서 목록 갱신할 수 있게 true.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 멤버 시트 (오너는 강퇴 버튼 표시)
  // ---------------------------------------------------------------------------
  Future<void> _openMembersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _MembersSheet(
          communityId: widget.communityId,
          ownerMemberId: _community?.ownerMemberId,
          isOwnerViewing: _isOwner,
          initialMembers: _members,
          onKicked: (kickedMemberId) async {
            // 부모 화면도 갱신.
            await _loadHeader();
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 헤더 (아바타 / 이름 / 카테고리 · 멤버 수 / 멤버 아바타 행)
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    final c = _community;
    final name = c?.name ?? widget.initial?.name ?? '';
    final categoryLabel = c?.category.label ?? '';
    final memberCount = c?.memberCount ?? widget.initial?.memberCount ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        children: [
          _buildCommunityAvatarWithEdit(c?.imageUrl),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
          const SizedBox(height: 13),
          _buildCategoryAndCount(categoryLabel, memberCount),
          const SizedBox(height: 14),
          _buildMembersRow(memberCount),
        ],
      ),
    );
  }

  Widget _buildCommunityAvatar(String? url) {
    final hasImage = url != null && url.isNotEmpty;
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE8E8E8),
        image: hasImage
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: hasImage
          ? null
          : const Center(
              child: Icon(
                Icons.photo_camera_rounded,
                color: Color(0xFFB7B7B7),
                size: 30,
              ),
            ),
    );
  }

  /// 아바타 + (오너에게만 보이는) 우하단 편집 배지.
  /// 이미지 업로드/저장 중에는 배지 자리에 작은 스피너를 띄운다.
  Widget _buildCommunityAvatarWithEdit(String? url) {
    return Stack(
      children: [
        _buildCommunityAvatar(url),
        if (_isOwner)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _isUpdatingImage ? null : _onTapEditCommunityImage,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _isUpdatingImage
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
      ],
    );
  }

  /// 오너가 편집 배지를 탭했을 때.
  /// 갤러리에서 이미지 선택 → 업로드 → updateCommunity 호출 → 헤더 재로드.
  Future<void> _onTapEditCommunityImage() async {
    final c = _community;
    if (c == null) return;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return;

      setState(() => _isUpdatingImage = true);

      // 1) 이미지 업로드 → URL 확보
      final urls = await SharehouseService.uploadImages([File(picked.path)]);
      if (urls.isEmpty) {
        throw Exception('Failed to upload image.');
      }

      // 2) 커뮤니티 정보 업데이트.
      //    name 은 필수이므로 현재 값을 그대로 다시 보내고, 새 imageUrl 만 갱신.
      await CommunityService.updateCommunity(
        communityId: c.id,
        name: c.name,
        description: c.description,
        category: c.category,
        imageUrl: urls.first,
      );

      // 3) 서버에서 최신 상태를 다시 받아 화면 갱신.
      await _loadHeader();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingImage = false);
    }
  }

  Widget _buildCategoryAndCount(String category, int memberCount) {
    final memberLabel = memberCount == 1 ? '1 Member' : '$memberCount Members';
    final hasCategory = category.isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasCategory) ...[
          Text(
            category,
            style: const TextStyle(
              fontSize: 13,
              color: grey03,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 12, color: grey01),
          const SizedBox(width: 8),
        ],
        Text(
          memberLabel,
          style: const TextStyle(
            fontSize: 13,
            color: grey03,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 멤버 아바타 행.
  /// - 본인이 항상 멤버에 포함되어 있으므로(생성/가입 시 자동 추가) 멤버 1명일 때도
  ///   본인 아바타가 노출된다.
  /// - 최대 4명까지 보여주고, 더 많으면 마지막에 "+N" 칩.
  /// - 행 전체를 탭하면 전체 멤버 시트가 열린다.
  Widget _buildMembersRow(int memberCount) {
    if (_members.isEmpty) {
      // 헤더 데이터 도착 전 placeholder.
      return const SizedBox(height: 36);
    }
    const int maxAvatars = 4;
    final visible = _members.take(maxAvatars).toList();
    final overflow = memberCount - visible.length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openMembersSheet,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...visible.map(_buildMemberAvatar),
          if (overflow > 0) ...[
            const SizedBox(width: 4),
            _buildOverflowChip(overflow),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberAvatar(CommunityMemberModel m) {
    final has = m.profileImageUrl != null && m.profileImageUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey[300],
        backgroundImage: has
            ? NetworkImage(m.profileImageUrl!) as ImageProvider
            : const AssetImage('assets/icons/default.png'),
      ),
    );
  }

  Widget _buildOverflowChip(int overflow) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE3E3E3), width: 1),
      ),
      child: Center(
        child: Text(
          '+$overflow',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: dark,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 탭 바
  // ---------------------------------------------------------------------------
  Widget _buildTabBar() {
    return SizedBox(
      height: _TabBarDelegate.extent,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 1.2, color: Colors.grey[200]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildDetailTab(
                    label: 'Discussions',
                    svgPath: 'assets/icons/discussion.svg',
                    index: 0,
                    iconSize: 17,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailTab(
                    label: 'Albums',
                    svgPath: 'assets/icons/image.svg',
                    index: 1,
                    iconSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTab({
    required String label,
    required String svgPath,
    required int index,
    required double iconSize,
  }) {
    final isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 아이콘 + 텍스트
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      svgPath,
                      width: iconSize,
                      height: iconSize,
                      colorFilter: ColorFilter.mode(
                        isSelected ? darkgreen : grey03,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? darkgreen : grey03,
                      ),
                    ),
                  ],
                ),
              ),

              // 초록 선택 라인 (항상 맨 아래)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  width: 40,
                  height: 1.2,
                  decoration: BoxDecoration(
                    color: isSelected ? darkgreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Discussions 탭
  // ---------------------------------------------------------------------------
  Widget _buildDiscussionsTab() {
    if (_isLoadingPosts && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: green));
    }

    final visible = _filteredPosts;

    return ListView(
      // NestedScrollView 안의 inner ListView 는 자체 스크롤 컨트롤러를 따로 두지 않는다.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        _buildFilterBar(),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Center(
              child: Text(
                _postError ?? 'No posts yet',
                style: const TextStyle(
                  fontSize: 13,
                  color: grey03,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          ...visible.map(_buildPostCard),
        if (_isLoadingMorePosts)
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
      ],
    );
  }

  /// 클라이언트 측 월/년 필터.
  List<PostModel> get _filteredPosts {
    if (_filterMonth == null && _filterYear == null) return _posts;
    return _posts.where((p) {
      final iso = p.regTime;
      if (iso == null || iso.isEmpty) return false;
      try {
        final raw = iso.endsWith('Z') ? iso : '${iso}Z';
        final dt = DateTime.parse(raw).toLocal();
        if (_filterMonth != null && dt.month != _filterMonth) return false;
        if (_filterYear != null && dt.year != _filterYear) return false;
        return true;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/filter.svg',
                  width: 18,
                  height: 18,
                  color: darkgreen,
                ),
                const SizedBox(width: 8), // 간격을 6에서 8로 살짝 넓혀 가독성 확보
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        _buildPillDropdown<int>(
          width: 115, // Month 필터 너비 지정 (글자 길이에 맞춰 적절히 조절 가능)
          label: _filterMonth == null
              ? 'Month'
              : DateFormat('MMM').format(DateTime(2000, _filterMonth!)),
          items: [
            const DropdownMenuItem<int>(value: null, child: Text('All')),
            ...List.generate(12, (i) {
              final m = i + 1;
              return DropdownMenuItem<int>(
                value: m,
                child: Text(DateFormat('MMMM').format(DateTime(2000, m))),
              );
            }),
          ],
          onChanged: (v) => setState(() => _filterMonth = v),
        ),
        const SizedBox(width: 8),
        _buildPillDropdown<int>(
          width: 75, // Year 필터 너비 지정
          label: _filterYear == null ? 'Year' : _filterYear.toString(),
          items: [
            const DropdownMenuItem<int>(value: null, child: Text('All')),
            ..._availableYears().map(
              (y) => DropdownMenuItem<int>(value: y, child: Text('$y')),
            ),
          ],
          onChanged: (v) => setState(() => _filterYear = v),
        ),
      ],
    );
  }

  List<int> _availableYears() {
    final now = DateTime.now().year;
    final years = <int>{now};
    for (final p in _posts) {
      final iso = p.regTime;
      if (iso == null || iso.isEmpty) continue;
      try {
        final raw = iso.endsWith('Z') ? iso : '${iso}Z';
        years.add(DateTime.parse(raw).toLocal().year);
      } catch (_) {}
    }
    final list = years.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  Widget _buildPillDropdown<T>({
    required String label,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    double? width,
  }) {
    return Container(
      width: width,
      height: 32,
      // 정중앙 정렬을 위해 Container 내부에 Alignment 추가
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green, width: 1.1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isDense: true,
          isExpanded: false,
          icon: const SizedBox.shrink(), // 기본 아이콘 제거
          // 1. 힌트(기본) 상태 중앙 정렬
          hint: Row(
            mainAxisSize: MainAxisSize.min, // 필요한 만큼만 크기 차지
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5), // 텍스트와 화살표 아이콘 사이 간격
              SizedBox(
                width: 11,
                height: 11,
                child: SvgPicture.asset(
                  'assets/icons/arrow_down.svg',
                  colorFilter: const ColorFilter.mode(green, BlendMode.srcIn),
                ),
              ),
            ],
          ),

          // 2. 선택된(Selected) 상태 중앙 정렬
          selectedItemBuilder: (context) {
            return items.map((_) {
              return Row(
                mainAxisSize: MainAxisSize.min, // 필요한 만큼만 크기 차지
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: darkgreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  SizedBox(
                    width: 11,
                    height: 11,
                    child: SvgPicture.asset(
                      'assets/icons/arrow_down.svg',
                      colorFilter: const ColorFilter.mode(
                        green,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// 현재 로그인 사용자가 [p] 게시글에 대한 삭제 권한이 있는지.
  ///
  /// 서버 정책과 동일하게:
  ///   1) 작성자 본인 (authorEmail == 내 이메일)
  ///   2) 커뮤니티 오너 (community.ownerMemberId == 내 memberId)
  /// 둘 중 하나면 true.
  bool _canDeletePost(PostModel p) {
    final me = AuthService.currentUserNotifier.value;
    if (me == null) return false;
    final isAuthor = p.authorEmail != null &&
        p.authorEmail!.isNotEmpty &&
        p.authorEmail == me.email;
    final isOwner = _community?.ownerMemberId != null &&
        _community!.ownerMemberId == me.memberId;
    return isAuthor || isOwner;
  }

  Future<void> _confirmAndDeletePost(PostModel p) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Delete post',
      message: 'This post will be permanently removed. Continue?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await PostService.deletePost(p.id);
      if (!mounted) return;
      setState(() {
        _posts.removeWhere((e) => e.id == p.id);
        // 앨범 캐시도 함께 무효화 (사진이 빠지면 다시 채워줘야 하므로).
        _albumPosts.removeWhere((e) => e.id == p.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  /// 작성자 / 커뮤니티 오너 전용 더보기 메뉴.
  /// 피드 카드와 동일한 dots-linear SVG 아이콘을 트리거로 사용해 톤을 통일.
  Widget _buildPostMoreMenu(PostModel p) {
    return SizedBox(
      width: 32,
      height: 24,
      child: PopupMenuButton<String>(
        tooltip: 'More',
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 6,
        icon: SvgPicture.asset(
          'assets/icons/dots-linear.svg',
          width: 20,
          height: 20,
          color: dark,
        ),
        onSelected: (value) {
          if (value == 'delete') _confirmAndDeletePost(p);
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

  Widget _buildPostCard(PostModel p) {
    final hasImage = p.imageUrls.isNotEmpty;
    final hasAvatar =
        p.profileImageUrl != null && p.profileImageUrl!.isNotEmpty;
    final canDelete = _canDeletePost(p);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 본문 + (권한 있을 때) 더보기 메뉴.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    p.content,
                    maxLines: hasImage ? 2 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: dark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (canDelete) _buildPostMoreMenu(p),
              ],
            ),
            if (hasImage) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.network(
                    p.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFEFEFEF),
                      child: const Center(
                        child: Icon(Icons.broken_image, color: grey02),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: hasAvatar
                      ? NetworkImage(p.profileImageUrl!) as ImageProvider
                      : const AssetImage('assets/icons/default.png'),
                ),
                const SizedBox(width: 9),
                Text(
                  p.authorName.isEmpty ? 'Member' : p.authorName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: grey03,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 14),
                SvgPicture.asset(
                  'assets/icons/calendar.svg',
                  width: 13,
                  height: 13,
                  color: grey03,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(p.regTime),
                  style: const TextStyle(
                    fontSize: 12,
                    color: grey03,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final raw = iso.endsWith('Z') ? iso : '${iso}Z';
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM, yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // Albums 탭 (Discussions 게시글의 사진을 모아 3열 그리드, 페이지 15)
  // ---------------------------------------------------------------------------
  Widget _buildAlbumsTab() {
    if (!_albumsInitialized || (_isLoadingAlbums && _albumPosts.isEmpty)) {
      return const Center(child: CircularProgressIndicator(color: green));
    }

    // 게시글 페이지에서 imageUrls 만 평탄화. (한 게시글이 여러 장일 수 있음)
    final urls = <String>[for (final p in _albumPosts) ...p.imageUrls];

    if (urls.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No photos yet',
              style: TextStyle(
                fontSize: 13,
                color: grey03,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    urls[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFEFEFEF),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: grey02,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              childCount: urls.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildAlbumFooter()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildAlbumFooter() {
    if (_isLoadingMoreAlbums) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: green),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ---------------------------------------------------------------------------
  // FAB
  //
  // 가입 상태에 따라 우하단 FAB 가 두 가지로 분기된다.
  // - 멤버(_isMember == true)  : 펜슬 아이콘 → 새 글 작성
  // - 비멤버                  : "+" 아이콘 → 가입(_onTapJoin), 가입 후엔 펜슬로 자동 전환
  // ---------------------------------------------------------------------------
  Widget _buildPencilFab() {
    final isMember = _isMember;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          backgroundColor: green,
          elevation: 4,
          shape: const CircleBorder(),
          onPressed: _isJoining
              ? null
              : (isMember ? _onTapWritePost : _onTapJoin),
          child: _isJoining
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : (isMember
                    ? SvgPicture.asset(
                        'assets/icons/pencil.svg',
                        width: 22,
                        height: 22,
                        color: Colors.white,
                      )
                    : const Icon(Icons.add, size: 28, color: Colors.white)),
        ),
      ),
    );
  }
}

/// 탭 바를 NestedScrollView 의 sliver 헤더로 pin 시키기 위한 delegate.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  static const double extent = 60;

  final Widget child;
  _TabBarDelegate({required this.child});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.transparent,
      elevation: overlapsContent ? 1 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.child != child;
}

// =============================================================================
// 멤버 목록 + 강퇴 시트
// =============================================================================
class _MembersSheet extends StatefulWidget {
  final int communityId;
  final int? ownerMemberId;
  final bool isOwnerViewing;
  final List<CommunityMemberModel> initialMembers;

  /// 강퇴 성공 시 부모로 알림.
  final Future<void> Function(int memberId)? onKicked;

  const _MembersSheet({
    required this.communityId,
    required this.ownerMemberId,
    required this.isOwnerViewing,
    required this.initialMembers,
    this.onKicked,
  });

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  static const int _pageSize = 10;
  late List<CommunityMemberModel> _members;
  int _nextPage = 1; // 부모가 이미 page 0 의 일부를 들고 있다고 가정.
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _busyForMemberId; // 강퇴 진행 중인 멤버 표시용

  final ScrollController _ctrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _members = [...widget.initialMembers];
    // 부모가 이미 첫 페이지를 들고 있으니, 그 길이가 페이지 사이즈 미만이면 종결.
    _hasMore = _members.length >= _pageSize;
    _ctrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_ctrl.hasClients) return;
    final pos = _ctrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 120) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final list = await CommunityService.fetchMembers(
        widget.communityId,
        page: _nextPage,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _members.addAll(list);
        _nextPage += 1;
        _hasMore = list.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onKickPressed(CommunityMemberModel m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('${m.name} will lose access to this community.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busyForMemberId = m.memberId.toString());
    try {
      await CommunityService.kickMember(widget.communityId, m.memberId);
      if (!mounted) return;
      setState(() {
        _members.removeWhere((x) => x.memberId == m.memberId);
        _busyForMemberId = null;
      });
      await widget.onKicked?.call(m.memberId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyForMemberId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaH = MediaQuery.of(context).size.height;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaH * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: grey01,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Members',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEFEFEF)),
            Flexible(
              child: ListView.separated(
                controller: _ctrl,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _members.length + (_isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF3F3F3)),
                itemBuilder: (_, i) {
                  if (i >= _members.length) {
                    return const Padding(
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
                    );
                  }
                  return _buildRow(_members[i]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(CommunityMemberModel m) {
    final has = m.profileImageUrl != null && m.profileImageUrl!.isNotEmpty;
    final isOwner =
        widget.ownerMemberId != null && m.memberId == widget.ownerMemberId;
    final canKick = widget.isOwnerViewing && !isOwner;
    final isBusy = _busyForMemberId == m.memberId.toString();

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[300],
        backgroundImage: has
            ? NetworkImage(m.profileImageUrl!) as ImageProvider
            : const AssetImage('assets/icons/default.png'),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              m.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
          ),
          if (isOwner) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: yellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Owner',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: canKick
          ? (isBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.redAccent,
                    ),
                  )
                : IconButton(
                    tooltip: 'Remove',
                    onPressed: () => _onKickPressed(m),
                    icon: const Icon(
                      Icons.person_remove_alt_1_outlined,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ))
          : null,
    );
  }
}
