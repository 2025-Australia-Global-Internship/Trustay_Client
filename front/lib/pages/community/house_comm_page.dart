import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

// [중요] MyPage처럼 AuthService와 모델을 import 합니다.
import 'package:front/services/auth_service.dart';
import 'package:front/models/user_model.dart';

import '../../models/chat_room_list_model.dart';
import '../../models/listing_model.dart';
import '../../models/post_model.dart';
import '../../models/sharehouse_model.dart';
import '../../services/chat_service.dart';
import '../../services/post_service.dart';
import '../../services/sharehouse_service.dart';
import 'chat_room_page.dart';
import 'notice_create_page.dart';
import 'notice_detail_page.dart';

/// Notice 탭 내부의 역할(role) 세그먼트.
/// - hosting : 내가 호스트로 등록한 매물의 공지 (글 작성 가능, FAB 노출)
/// - staying : 내가 게스트(세입자)로 거주중인 매물의 공지 (읽기 전용)
enum _NoticeRole { hosting, staying }

class HouseCommPage extends StatefulWidget {
  const HouseCommPage({super.key});

  @override
  State<HouseCommPage> createState() => _HouseCommPageState();
}

class _HouseCommPageState extends State<HouseCommPage> {
  int _houseSubTabIndex = 0; // 0: Notice, 1: Chat

  // ---------------------------------------------------------------------------
  // 공통
  // ---------------------------------------------------------------------------
  User? _currentUser;
  bool _bootstrapped = false; // 첫 로드(매물/거주지) 완료 여부

  // ---------------------------------------------------------------------------
  // Notice 탭
  // ---------------------------------------------------------------------------
  _NoticeRole _noticeRole = _NoticeRole.staying;

  // 호스트로서 — 내가 등록한 매물들
  List<MyListingItem> _hostingHouses = [];
  MyListingItem? _selectedHostingHouse;
  List<PostModel> _hostingNotices = [];
  bool _isHostingLoading = false;

  // 게스트로서 — 내가 거주중인 매물
  SharehouseModel? _stayingHouse;
  List<PostModel> _stayingNotices = [];
  bool _isStayingLoading = false;

  String? _noticeError;

  // 필터 (월/년) — 두 역할 공통
  int? _filterMonth;
  int? _filterYear;

  // ---------------------------------------------------------------------------
  // Chat 탭
  // ---------------------------------------------------------------------------
  List<ChatRoomListModel> _chatRooms = [];
  bool _isChatLoading = false;
  String? _chatError;

  // ---------------------------------------------------------------------------
  // 라이프사이클
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _bootstrapNoticeTab();
  }

  // ---------------------------------------------------------------------------
  // 시간 포맷팅
  // ---------------------------------------------------------------------------
  String _formatChatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '';
    try {
      final String utcString =
          timeString.endsWith('Z') ? timeString : '${timeString}Z';
      final DateTime localDate = DateTime.parse(utcString).toLocal();
      final DateTime now = DateTime.now();
      final bool isToday = localDate.year == now.year &&
          localDate.month == now.month &&
          localDate.day == now.day;
      return isToday
          ? DateFormat('hh:mm a').format(localDate)
          : DateFormat('MM/dd').format(localDate);
    } catch (_) {
      return timeString;
    }
  }

  String _formatNoticeDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final String raw = iso.endsWith('Z') ? iso : '${iso}Z';
      final DateTime time = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM, yyyy').format(time);
    } catch (_) {
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // Notice — bootstrap (매물 + 거주지 동시 로드)
  // ---------------------------------------------------------------------------
  Future<void> _bootstrapNoticeTab() async {
    try {
      _currentUser ??= await AuthService.fetchProfile();

      // 호스팅 매물 / 거주중 매물 병렬 로딩
      final results = await Future.wait([
        _safeFetchMyListings(),
        SharehouseService.fetchMyCurrentSharehouse(),
      ]);

      if (!mounted) return;

      final List<MyListingItem> hostings =
          results[0] as List<MyListingItem>;
      final SharehouseModel? staying = results[1] as SharehouseModel?;

      // Staying 탭은 "게스트로 머물고 있는" 매물 전용이다.
      // 본인이 host 인 매물은 Hosting 탭에서 이미 다루므로 Staying 에서 숨긴다.
      // (탭 버튼 자체는 항상 활성화되어 있고, 비어 있으면 "as a guest" 빈 화면 표시.)
      final bool stayingIsMine = staying != null &&
          staying.hostId != null &&
          _currentUser != null &&
          staying.hostId == _currentUser!.memberId;

      setState(() {
        _hostingHouses = hostings;
        _selectedHostingHouse = hostings.isNotEmpty ? hostings.first : null;
        _stayingHouse = stayingIsMine ? null : staying;
        // 호스팅 매물이 하나라도 있으면 Hosting 탭을 기본으로 보여준다.
        _noticeRole = hostings.isNotEmpty
            ? _NoticeRole.hosting
            : _NoticeRole.staying;
        _bootstrapped = true;
      });

      // 각 역할의 공지 로드 (현재 선택된 역할 우선)
      await _refreshCurrentRoleNotices();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bootstrapped = true;
        _noticeError = '공지를 불러오지 못했어요.';
      });
    }
  }

  Future<List<MyListingItem>> _safeFetchMyListings() async {
    try {
      return await SharehouseService.fetchMyListings();
    } catch (_) {
      return <MyListingItem>[];
    }
  }

  /// 현재 활성화된 역할(hosting/staying)의 공지만 새로고침한다.
  Future<void> _refreshCurrentRoleNotices() async {
    if (_noticeRole == _NoticeRole.hosting) {
      await _loadHostingNotices();
    } else {
      await _loadStayingNotices();
    }
  }

  Future<void> _loadHostingNotices() async {
    final house = _selectedHostingHouse;
    if (house == null) {
      setState(() {
        _hostingNotices = const [];
        _isHostingLoading = false;
      });
      return;
    }
    if (_isHostingLoading) return;
    setState(() {
      _isHostingLoading = true;
      _noticeError = null;
    });
    try {
      final posts =
          await PostService.getSharehousePosts(house.id, page: 0, size: 50);
      if (!mounted) return;
      setState(() {
        _hostingNotices = posts;
        _isHostingLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _noticeError = '공지를 불러오지 못했어요.';
        _isHostingLoading = false;
      });
    }
  }

  Future<void> _loadStayingNotices() async {
    final house = _stayingHouse;
    if (house == null) {
      setState(() {
        _stayingNotices = const [];
        _isStayingLoading = false;
      });
      return;
    }
    if (_isStayingLoading) return;
    setState(() {
      _isStayingLoading = true;
      _noticeError = null;
    });
    try {
      final posts =
          await PostService.getSharehousePosts(house.id, page: 0, size: 50);
      if (!mounted) return;
      setState(() {
        _stayingNotices = posts;
        _isStayingLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _noticeError = '공지를 불러오지 못했어요.';
        _isStayingLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Notice — getter
  // ---------------------------------------------------------------------------

  /// 현재 역할이 hosting 이고 선택된 매물이 있을 때만 글 작성 가능.
  bool get _canWriteNotice =>
      _noticeRole == _NoticeRole.hosting && _selectedHostingHouse != null;

  bool get _isCurrentRoleHosting => _noticeRole == _NoticeRole.hosting;

  bool get _isLoadingCurrentRole => _isCurrentRoleHosting
      ? _isHostingLoading
      : _isStayingLoading;

  List<PostModel> get _currentRoleNotices => _isCurrentRoleHosting
      ? _hostingNotices
      : _stayingNotices;

  /// 필터링된 공지 목록.
  List<PostModel> get _filteredNotices {
    final base = _currentRoleNotices;
    if (_filterMonth == null && _filterYear == null) return base;
    return base.where((p) {
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

  // ---------------------------------------------------------------------------
  // Chat 로드
  // ---------------------------------------------------------------------------
  Future<void> _loadChats() async {
    if (_isChatLoading) return;
    setState(() {
      _isChatLoading = true;
      _chatError = null;
    });

    try {
      final User user = _currentUser ?? await AuthService.fetchProfile();
      final rooms = await ChatService.getMyChatRooms(user.memberId);

      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _chatRooms = rooms;
        _isChatLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chatError = '채팅방을 불러오지 못했어요.';
        _isChatLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 화면 이동
  // ---------------------------------------------------------------------------
  Future<void> _openNoticeDetail(PostModel notice) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoticeDetailPage(
          postId: notice.id,
          currentUser: _currentUser,
          isHost: _isCurrentRoleHosting,
        ),
      ),
    );
    if (mounted) _refreshCurrentRoleNotices();
  }

  Future<void> _openNoticeCreate() async {
    final house = _selectedHostingHouse;
    if (house == null) return;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NoticeCreatePage(sharehouseId: house.id),
      ),
    );
    if (created == true && mounted) _loadHostingNotices();
  }

  Future<void> _onTapChatRoom(ChatRoomListModel item) async {
    final user = _currentUser ?? await AuthService.fetchProfile();
    if (!mounted) return;
    _currentUser = user;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(
          roomId: item.roomId,
          houseId: item.houseId,
          roomName: item.otherMemberName,
          myMemberId: _currentUser!.memberId,
          otherProfileImageUrl: item.profileImageUrl,
        ),
      ),
    );

    if (mounted) _loadChats();
  }

  // ---------------------------------------------------------------------------
  // 빌드
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [SliverToBoxAdapter(child: _buildHouseSubTabs())];
        },
        body: _buildContent(),
      ),
      floatingActionButton: (_houseSubTabIndex == 0 && _canWriteNotice)
          ? _buildFloatingButton()
          : null,
    );
  }

  Widget _buildHouseSubTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1.2),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHouseSubTab('Notice', 'assets/icons/notice.svg', 0),
            const SizedBox(width: 24),
            _buildHouseSubTab('Chat', 'assets/icons/chat.svg', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseSubTab(String label, String svgPath, int index) {
    final isSelected = _houseSubTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _houseSubTabIndex = index;
        });
        if (index == 0) {
          _refreshCurrentRoleNotices();
        } else {
          _loadChats();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SvgPicture.asset(
                  svgPath,
                  width: 18,
                  height: 18,
                  color: isSelected ? darkgreen : grey03,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? darkgreen : grey03,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1.2,
            width: 175,
            decoration: BoxDecoration(
              color: isSelected ? darkgreen : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return _houseSubTabIndex == 0 ? _buildNoticeContent() : _buildChatContent();
  }

  // ===========================================================================
  // Notice 탭
  // ===========================================================================
  Widget _buildNoticeContent() {
    return RefreshIndicator(
      color: green,
      onRefresh: _refreshCurrentRoleNotices,
      child: _buildNoticeListView(),
    );
  }

  Widget _buildNoticeListView() {
    // bootstrap 전 — 전체 로딩
    if (!_bootstrapped) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(child: CircularProgressIndicator(color: green)),
        ],
      );
    }

    final bool hasHosting = _hostingHouses.isNotEmpty;
    final bool hasStaying = _stayingHouse != null;

    // 두 역할 모두 비어있는 경우 — 첫 화면부터 안내
    if (!hasHosting && !hasStaying) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildRoleSegment(hasHosting: false, hasStaying: false),
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          _buildEmptyState(
            iconPath: 'assets/icons/house-pin.svg',
            title: 'No house yet',
            subtitle: 'List a house or move into one to use notices.',
          ),
        ],
      );
    }

    // 현재 역할에 매물이 없는 경우
    final bool currentRoleHasHouse =
        _isCurrentRoleHosting ? hasHosting : hasStaying;

    if (!currentRoleHasHouse) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildRoleSegment(
            hasHosting: hasHosting,
            hasStaying: hasStaying,
          ),
          if (_isCurrentRoleHosting && hasHosting) _buildHostingHousePicker(),
          SizedBox(height: MediaQuery.of(context).size.height * 0.16),
          _buildEmptyState(
            iconPath: 'assets/icons/house-pin.svg',
            title: _isCurrentRoleHosting
                ? 'No houses to manage'
                : 'No stays as a guest yet',
            subtitle: _isCurrentRoleHosting
                ? 'List a house to start posting notices.'
                : 'Houses you rent from others will appear here.',
          ),
        ],
      );
    }

    // 로딩 중 — 첫 진입
    if (_isLoadingCurrentRole && _currentRoleNotices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildRoleSegment(
            hasHosting: hasHosting,
            hasStaying: hasStaying,
          ),
          if (_isCurrentRoleHosting && hasHosting) _buildHostingHousePicker(),
          _buildNoticeFilterBar(),
          const SizedBox(height: 120),
          const Center(child: CircularProgressIndicator(color: green)),
        ],
      );
    }

    // 에러
    if (_noticeError != null && _currentRoleNotices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildRoleSegment(
            hasHosting: hasHosting,
            hasStaying: hasStaying,
          ),
          if (_isCurrentRoleHosting && hasHosting) _buildHostingHousePicker(),
          _buildNoticeFilterBar(),
          SizedBox(height: MediaQuery.of(context).size.height * 0.16),
          Center(
            child: Text(
              _noticeError!,
              style: const TextStyle(
                fontSize: 14,
                color: grey02,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      );
    }

    // 데이터 표시
    final List<PostModel> visible = _filteredNotices;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _buildRoleSegment(hasHosting: hasHosting, hasStaying: hasStaying),
        if (_isCurrentRoleHosting && hasHosting) _buildHostingHousePicker(),
        _buildNoticeFilterBar(),
        if (visible.isEmpty) ...[
          SizedBox(height: MediaQuery.of(context).size.height * 0.14),
          _buildEmptyState(
            iconPath: 'assets/icons/edit-note.svg',
            title: 'No notices yet',
            subtitle: _isCurrentRoleHosting
                ? 'Tap the pencil to post a notice.'
                : 'Check back later for updates',
          ),
        ] else ...[
          const SizedBox(height: 8),
          ...visible.map(_buildNoticeCard),
        ],
      ],
    );
  }

  Widget _buildEmptyState({
    required String iconPath,
    required String title,
    required String subtitle,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(iconPath, color: grey01, width: 72, height: 72),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: grey02,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: grey02,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Notice — 역할 세그먼트 (Hosting / Staying)
  // ---------------------------------------------------------------------------
  Widget _buildRoleSegment({
    required bool hasHosting,
    required bool hasStaying,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 두 탭 모두 항상 탭 가능하게 (비어있는 경우엔 안쪽에서 안내 표시)
            Expanded(
              child: _buildRolePill(
                role: _NoticeRole.hosting,
                label: 'Hosting',
                iconPath: 'assets/icons/house-user.svg',
                enabled: true,
              ),
            ),
            Expanded(
              child: _buildRolePill(
                role: _NoticeRole.staying,
                label: 'Staying',
                iconPath: 'assets/icons/bed.svg',
                enabled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolePill({
    required _NoticeRole role,
    required String label,
    required String iconPath,
    required bool enabled,
  }) {
    final bool selected = _noticeRole == role;
    return GestureDetector(
      onTap: !enabled
          ? null
          : () {
              if (_noticeRole == role) return;
              setState(() => _noticeRole = role);
              _refreshCurrentRoleNotices();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 16,
              height: 16,
              color: selected ? dark : (enabled ? grey03 : grey01),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? dark : (enabled ? grey03 : grey01),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notice — Hosting 매물 선택기 (다수 보유 시 가로 스크롤 칩)
  // ---------------------------------------------------------------------------
  Widget _buildHostingHousePicker() {
    if (_hostingHouses.length <= 1) {
      // 한 채만 호스팅 중이면 헤더 형태로 보여만 준다.
      final house = _selectedHostingHouse;
      if (house == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/house-user.svg',
              width: 16,
              height: 16,
              color: darkgreen,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                house.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: darkgreen,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _hostingHouses.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final h = _hostingHouses[index];
            final bool selected = _selectedHostingHouse?.id == h.id;
            return GestureDetector(
              onTap: () {
                if (selected) return;
                setState(() {
                  _selectedHostingHouse = h;
                  _hostingNotices = const [];
                });
                _loadHostingNotices();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? darkgreen : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: darkgreen, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    h.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : darkgreen,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notice — 필터 바 (Filter / Month / Year)
  // ---------------------------------------------------------------------------
  Widget _buildNoticeFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // TODO: 필터 BottomSheet
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/filter.svg',
                    width: 18,
                    height: 18,
                    color: darkgreen,
                  ),
                  const SizedBox(width: 6),
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
      ),
    );
  }

  List<int> _availableYears() {
    final now = DateTime.now().year;
    final dataYears = <int>{};
    for (final p in _currentRoleNotices) {
      final iso = p.regTime;
      if (iso == null || iso.isEmpty) continue;
      try {
        final raw = iso.endsWith('Z') ? iso : '${iso}Z';
        dataYears.add(DateTime.parse(raw).toLocal().year);
      } catch (_) {}
    }
    dataYears.add(now);
    final years = dataYears.toList()..sort((a, b) => b.compareTo(a));
    return years;
  }

  Widget _buildPillDropdown<T>({
    required String label,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: darkgreen, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isDense: true,
          icon: SvgPicture.asset(
            'assets/icons/arrow_down.svg',
            width: 12,
            height: 12,
            color: darkgreen,
          ),
          hint: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: darkgreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          selectedItemBuilder: (context) {
            return items
                .map(
                  (_) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: darkgreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList();
          },
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notice — 카드
  // ---------------------------------------------------------------------------
  Widget _buildNoticeCard(PostModel post) {
    final String? imageUrl =
        post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final bool hasAvatar =
        post.profileImageUrl != null && post.profileImageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openNoticeDetail(post),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.title.isNotEmpty) ...[
                Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                maxLines: hasImage ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: dark,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (hasImage) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: grey01,
                        child: const Center(
                          child: Icon(Icons.image, color: grey02),
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
                    radius: 12,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: hasAvatar
                        ? NetworkImage(post.profileImageUrl!) as ImageProvider
                        : const AssetImage('assets/icons/default.png'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    post.authorName.isEmpty ? 'Host' : post.authorName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: grey03,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SvgPicture.asset(
                    'assets/icons/calendar.svg',
                    width: 14,
                    height: 14,
                    color: grey03,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatNoticeDate(post.regTime),
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
      ),
    );
  }

  // ===========================================================================
  // Chat 탭 (기존 로직 그대로 유지)
  // ===========================================================================
  Widget _buildChatContent() {
    if (_isChatLoading && _chatRooms.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: green));
    }
    return RefreshIndicator(
      color: green,
      onRefresh: _loadChats,
      child: _buildChatList(),
    );
  }

  Widget _buildChatList() {
    if (_chatError != null && _chatRooms.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Text(
              _chatError!,
              style: const TextStyle(
                fontSize: 14,
                color: grey02,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Pull to refresh',
              style: TextStyle(
                fontSize: 12,
                color: grey03,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      );
    }

    if (_chatRooms.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          const Center(
            child: Text(
              'No active chats.',
              style: TextStyle(
                fontSize: 14,
                color: grey02,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _chatRooms.length,
      itemBuilder: (context, index) {
        final item = _chatRooms[index];
        final unreadCount = 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: InkWell(
            onTap: () => _onTapChatRoom(item),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: (item.profileImageUrl != null &&
                          item.profileImageUrl!.isNotEmpty)
                      ? NetworkImage(item.profileImageUrl!) as ImageProvider
                      : const AssetImage('assets/icons/default.png'),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.otherMemberName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _formatChatTime(item.lastMessageTime),
                            style: const TextStyle(
                              fontSize: 9,
                              color: grey02,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.lastMessage,
                              style: const TextStyle(
                                  fontSize: 12, color: grey04),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: green,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: yellow,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // FAB — Hosting 역할에서만 노출
  // ===========================================================================
  Widget _buildFloatingButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: _openNoticeCreate,
          backgroundColor: green,
          elevation: 4,
          child: SvgPicture.asset(
            'assets/icons/pencil.svg',
            width: 24,
            height: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
