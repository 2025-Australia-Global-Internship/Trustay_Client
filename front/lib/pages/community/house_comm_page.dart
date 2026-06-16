import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

import 'package:front/main.dart' show routeObserver;
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

enum _NoticeRole { hosting, staying }

class HouseCommPage extends StatefulWidget {
  const HouseCommPage({super.key});

  @override
  State<HouseCommPage> createState() => _HouseCommPageState();
}

class _HouseCommPageState extends State<HouseCommPage> with RouteAware {
  int _houseSubTabIndex = 0; // 0: Notice, 1: Chat

  User? _currentUser;
  bool _bootstrapped = false;

  _NoticeRole _noticeRole = _NoticeRole.staying;

  List<MyListingItem> _hostingHouses = [];
  MyListingItem? _selectedHostingHouse;
  List<PostModel> _hostingNotices = [];
  bool _isHostingLoading = false;

  SharehouseModel? _stayingHouse;
  List<PostModel> _stayingNotices = [];
  bool _isStayingLoading = false;

  String? _noticeError;

  int? _filterMonth;
  int? _filterYear;

  List<ChatRoomListModel> _chatRooms = [];
  bool _isChatLoading = false;
  String? _chatError;

  static const int _chatPageSize = 10;
  int _chatNextPage = 0;
  bool _chatHasMore = true;
  bool _isLoadingMoreChats = false;
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bootstrapNoticeTab();
    _chatScrollController.addListener(_onChatScroll);
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
    _chatScrollController.removeListener(_onChatScroll);
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    if (_houseSubTabIndex == 0) {
      if (_noticeRole == _NoticeRole.hosting) {
        _loadHostingNotices();
      } else {
        _loadStayingNotices();
      }
    } else {
      _loadChats();
    }
  }

  void _onChatScroll() {
    if (!_chatScrollController.hasClients) return;
    final pos = _chatScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMoreChats();
    }
  }

  String _formatChatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '';
    try {
      final String utcString = timeString.endsWith('Z')
          ? timeString
          : '${timeString}Z';
      final DateTime localDate = DateTime.parse(utcString).toLocal();
      final DateTime now = DateTime.now();
      final bool isToday =
          localDate.year == now.year &&
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

  Future<void> _bootstrapNoticeTab() async {
    try {
      _currentUser ??= await AuthService.fetchProfile();

      final results = await Future.wait([
        _safeFetchMyListings(),
        SharehouseService.fetchMyCurrentSharehouse(),
      ]);

      if (!mounted) return;

      final List<MyListingItem> hostings = results[0] as List<MyListingItem>;
      final SharehouseModel? staying = results[1] as SharehouseModel?;

      final bool stayingIsMine =
          staying != null &&
          staying.hostId != null &&
          _currentUser != null &&
          staying.hostId == _currentUser!.memberId;

      setState(() {
        _hostingHouses = hostings;
        _selectedHostingHouse = hostings.isNotEmpty ? hostings.first : null;
        _stayingHouse = stayingIsMine ? null : staying;
        _noticeRole = hostings.isNotEmpty
            ? _NoticeRole.hosting
            : _NoticeRole.staying;
        _bootstrapped = true;
      });

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
      final posts = await PostService.getSharehousePosts(
        house.id,
        page: 0,
        size: 50,
      );
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
      final posts = await PostService.getSharehousePosts(
        house.id,
        page: 0,
        size: 50,
      );
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

  bool get _canWriteNotice =>
      _noticeRole == _NoticeRole.hosting && _selectedHostingHouse != null;

  bool get _isCurrentRoleHosting => _noticeRole == _NoticeRole.hosting;

  bool get _isLoadingCurrentRole =>
      _isCurrentRoleHosting ? _isHostingLoading : _isStayingLoading;

  List<PostModel> get _currentRoleNotices =>
      _isCurrentRoleHosting ? _hostingNotices : _stayingNotices;

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

  Future<void> _loadChats() async {
    if (_isChatLoading) return;
    setState(() {
      _isChatLoading = true;
      _chatError = null;
      _chatNextPage = 0;
      _chatHasMore = true;
    });

    try {
      final User user = _currentUser ?? await AuthService.fetchProfile();
      final rooms = await ChatService.getMyChatRooms(
        user.memberId,
        page: 0,
        size: _chatPageSize,
      );

      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _chatRooms = rooms;
        _chatNextPage = 1;
        _chatHasMore = rooms.length >= _chatPageSize;
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

  Future<void> _loadMoreChats() async {
    if (_isLoadingMoreChats || !_chatHasMore || _isChatLoading) return;
    final user = _currentUser;
    if (user == null) return;

    setState(() => _isLoadingMoreChats = true);
    try {
      final rooms = await ChatService.getMyChatRooms(
        user.memberId,
        page: _chatNextPage,
        size: _chatPageSize,
      );
      if (!mounted) return;
      setState(() {
        _chatRooms.addAll(rooms);
        _chatNextPage += 1;
        _chatHasMore = rooms.length >= _chatPageSize;
        _isLoadingMoreChats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMoreChats = false);
    }
  }

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildHouseSubTab('Notice', 'assets/icons/notice.svg', 0),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildHouseSubTab('Chat', 'assets/icons/chat.svg', 1),
          ),
        ],
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
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
            width: double.infinity,
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
  // Notice 탭 (슬림 디자인 고도화)
  // ===========================================================================
  Widget _buildNoticeContent() {
    return RefreshIndicator(
      color: green,
      onRefresh: _refreshCurrentRoleNotices,
      child: _buildNoticeListView(),
    );
  }

  Widget _buildNoticeListView() {
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

    if (!hasHosting && !hasStaying) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          _buildEmptyState(
            iconPath: 'assets/icons/house.svg',
            title: 'No house yet',
            subtitle: 'List a house or move into one to use notices.',
          ),
        ],
      );
    }

    if (_isLoadingCurrentRole && _currentRoleNotices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildIntegratedHeader(hasHosting, hasStaying),
          const SizedBox(height: 120),
          const Center(child: CircularProgressIndicator(color: green)),
        ],
      );
    }

    if (_noticeError != null && _currentRoleNotices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildIntegratedHeader(hasHosting, hasStaying),
          SizedBox(height: MediaQuery.of(context).size.height * 0.16),
          Center(
            child: Text(
              _noticeError!,
              style: const TextStyle(fontSize: 14, color: grey02),
            ),
          ),
        ],
      );
    }

    final List<PostModel> visible = _filteredNotices;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _buildIntegratedHeader(hasHosting, hasStaying),
        if (visible.isEmpty) ...[
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          _buildEmptyState(
            iconPath: 'assets/icons/edit-note.svg',
            title: 'No notices yet',
            subtitle: _isCurrentRoleHosting
                ? 'Tap the pencil to post a notice.'
                : 'Check back later for updates',
          ),
        ] else ...[
          const SizedBox(height: 4),
          ...visible.map(_buildNoticeCard),
        ],
      ],
    );
  }

  /// 🌟 수정된 통합 미니멀 헤더: 호스트 하우스가 여러 개여도 스왑 버튼이 항상 노출되도록 개선
  Widget _buildIntegratedHeader(bool hasHosting, bool hasStaying) {
    String titleText = 'No active space';
    VoidCallback? onTitleTap;
    bool showArrow = false;

    if (_noticeRole == _NoticeRole.hosting && _selectedHostingHouse != null) {
      titleText = _selectedHostingHouse!.title;
      if (_hostingHouses.length > 1) {
        showArrow = true;
        onTitleTap = _showHousePickerBottomSheet;
      }
    } else if (_noticeRole == _NoticeRole.staying && _stayingHouse != null) {
      titleText = _stayingHouse!.title;
    }

    final bool hasActiveFilter = _filterMonth != null || _filterYear != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. 좌측 타이틀 구역 (호스트 매물이 여러개면 피커를 띄우고, 하나면 역할 토글)
              Expanded(
                child: InkWell(
                  onTap:
                      onTitleTap ??
                      (hasHosting && hasStaying ? _toggleRole : null),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: dark,
                            ),
                          ),
                        ),
                        if (showArrow) ...[
                          const SizedBox(width: 7),
                          SvgPicture.asset(
                            'assets/icons/arrow_down.svg',
                            width: 7,
                            height: 7,
                            color: dark,
                          ),
                        ] else if (hasHosting && hasStaying) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: yellow.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _noticeRole == _NoticeRole.hosting
                                  ? 'Host'
                                  : 'Guest',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: darkgreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // 2. 우측 아이콘 버튼 구역
              Row(
                children: [
                  // 🛠️ [수정]: !showArrow 조건을 제거하여 호스트 매물이 많아도 호스트/게스트 스왑 버튼이 항상 보이도록 합니다.
                  if (hasHosting && hasStaying)
                    IconButton(
                      icon: const Icon(
                        Icons.swap_horiz_rounded,
                        color: grey03,
                        size: 22,
                      ),
                      onPressed: _toggleRole,
                      tooltip: 'Switch Role',
                    ),
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/filter.svg',
                      width: 18,
                      height: 18,
                      color: hasActiveFilter ? darkgreen : grey03,
                    ),
                    onPressed: _showFilterBottomSheet,
                  ),
                ],
              ),
            ],
          ),
          // 3. 필터링 활성화 시 인디케이터
          if (hasActiveFilter) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    if (_filterYear != null)
                      _buildFilterActiveChip('$_filterYear'),
                    if (_filterMonth != null)
                      _buildFilterActiveChip(
                        DateFormat('MMM').format(DateTime(2000, _filterMonth!)),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _filterMonth = null;
                    _filterYear = null;
                  }),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      color: grey03,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _toggleRole() {
    setState(() {
      _noticeRole = _noticeRole == _NoticeRole.hosting
          ? _NoticeRole.staying
          : _NoticeRole.hosting;
    });
    _refreshCurrentRoleNotices();
  }

  Widget _buildFilterActiveChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: grey01.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: dark,
        ),
      ),
    );
  }

  /// 하우스 선택용 바텀시트
  void _showHousePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select House (Hosting)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16), // 타이틀과 첫 항목 사이 간격
                // 하우스 목록 매핑
                ..._hostingHouses.map((h) {
                  final isSelected = _selectedHostingHouse?.id == h.id;

                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      if (isSelected) return;
                      setState(() {
                        _selectedHostingHouse = h;
                        _hostingNotices = const [];
                      });
                      _loadHostingNotices();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              h.title,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                fontSize: isSelected ? 14 : 13,
                                color: isSelected ? darkgreen : dark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check, color: darkgreen, size: 18),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 날짜 선택용 깔끔한 통합 바텀시트
  void _showFilterBottomSheet() {
    // 기본적으로 선택 바퀴가 가리킬 초기 날짜를 설정합니다. (기존 필터가 있으면 적용, 없으면 현재 날짜)
    final now = DateTime.now();
    final initialDateTime = DateTime(
      _filterYear ?? now.year,
      _filterMonth ?? now.month,
      1,
    );

    // 임시 변수에 현재 필터 상태를 저장해둡니다.
    int? tempYear = _filterYear;
    int? tempMonth = _filterMonth;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.only(top: 6),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // 1. 상단 바 (Cancel / Reset / Done 버튼)
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 취소 버튼
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: grey03,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // 초기화 버튼
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _filterYear = null;
                            _filterMonth = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      // 완료(적용) 버튼
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: darkgreen,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _filterYear = tempYear;
                            _filterMonth = tempMonth;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),

                // 2. 디테일 페이지 스타일의 부드러운 캘린더 피커 구역
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.monthYear, // 월/년도 선택 모드
                    initialDateTime: initialDateTime,
                    // 필터로 과거 데이터도 볼 수 있도록 최소/최대 연도를 적절히 제한합니다.
                    minimumDate: DateTime(now.year - 5, 1, 1),
                    maximumDate: DateTime(now.year + 1, 12, 31),
                    onDateTimeChanged: (DateTime newDateTime) {
                      // 바퀴가 굴러갈 때마다 임시 변수에 값을 담아둡니다. (Done을 누를 때만 최종 반영)
                      tempYear = newDateTime.year;
                      tempMonth = newDateTime.month;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildEmptyState({
    required String iconPath,
    required String title,
    required String subtitle,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(iconPath, color: grey01, width: 84, height: 84),
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

  Widget _buildNoticeCard(PostModel post) {
    final String? imageUrl = post.imageUrls.isNotEmpty
        ? post.imageUrls.first
        : null;

    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final bool hasAvatar =
        post.profileImageUrl != null && post.profileImageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: () => _openNoticeDetail(post),
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              if (post.title.isNotEmpty) ...[
                Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // 내용
              Text(
                post.content,
                maxLines: hasImage ? 2 : 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: dark,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // 이미지
              if (hasImage) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
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

              // 작성자 + 날짜
              Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: hasAvatar
                        ? NetworkImage(post.profileImageUrl!) as ImageProvider
                        : const AssetImage('assets/icons/default.png'),
                  ),

                  const SizedBox(width: 9),

                  Text(
                    post.authorName.isEmpty ? 'Host' : post.authorName,
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
  // Chat 탭 (기존 유지)
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
      controller: _chatScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _chatRooms.length + (_isLoadingMoreChats ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _chatRooms.length) {
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
        final item = _chatRooms[index];
        final int unreadCount = item.unreadCount;

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
                  backgroundImage:
                      (item.profileImageUrl != null &&
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
                                fontSize: 12,
                                color: grey04,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              constraints: const BoxConstraints(
                                minWidth: 22,
                                minHeight: 22,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: green,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: yellow,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
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
