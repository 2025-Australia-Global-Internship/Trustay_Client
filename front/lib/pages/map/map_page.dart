import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';
import 'package:front/index.dart' show lastReselectedTabIndex, tabReselectTick;
import 'package:front/models/search_model.dart';
import 'package:front/models/sharehouse_model.dart';
import 'package:front/pages/mypage/sharehouse_detail_page.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/custom_header.dart';

/// IndexPage 의 Map 탭 인덱스 (탭 재선택 시그널 매칭용).
const int _kMapTabIndex = 2;

/// 하단 네브바가 차지하는 시각적 영역 — 결과 카드/안내 박스가 네브바 위로
/// 올라오도록 Positioned.bottom 의 base 로 사용한다.
/// (BottomNavbar: height 74 + bottom padding 30 ≈ 104, 약간 여백)
const double _kBottomNavbarOverlay = 116;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  static const LatLng _defaultCenter =
      LatLng(-37.74159952548629, 144.99780308175087);
  static const double _defaultZoom = 15.0;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// 검색 결과로 표시할 매물 목록. (lat/lon 이 있는 항목만 핀으로 렌더링)
  List<SharehouseModel> _results = const [];
  bool _isSearching = false;
  String? _searchError;
  SharehouseModel? _focusedHouse;

  /// 검색창 위쪽에 보여줄 최근 검색어 목록.
  /// - 서버는 사용자가 `GET /sharehouses?keyword=...` 를 호출할 때마다 자동
  ///   기록한다 → [_performSearch] 직후 다시 fetch 해서 로컬 갱신.
  /// - 미로그인/네트워크 실패 시 빈 리스트로 폴백.
  List<SearchHistory> _recentSearches = const [];

  @override
  void initState() {
    super.initState();
    // 같은 Map 탭을 다시 누르면 → 검색/카메라를 초기화한다.
    tabReselectTick.addListener(_onTabReselect);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    tabReselectTick.removeListener(_onTabReselect);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// IndexPage 가 같은 탭을 재선택했을 때 호출. 내 탭(Map)일 때만 새로고침.
  void _onTabReselect() {
    if (!mounted) return;
    if (lastReselectedTabIndex != _kMapTabIndex) return;
    _resetMap();
  }

  /// 지도 새로고침 — 검색어/결과를 비우고 카메라를 기본 위치로 복귀.
  /// 최근 검색어 목록도 다시 받아와 최신 상태로 만든다.
  void _resetMap() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() {
      _results = const [];
      _isSearching = false;
      _searchError = null;
      _focusedHouse = null;
    });
    try {
      mapController.move(_defaultCenter, _defaultZoom);
    } catch (_) {
      // MapController 가 아직 attach 되지 않은 시점이면 무시.
    }
    _loadRecentSearches();
  }

  /// 서버에서 최근 검색어 목록을 받아와 칩 영역 갱신.
  /// 미로그인/네트워크 실패 시 빈 목록을 그대로 둔다.
  Future<void> _loadRecentSearches() async {
    final list = await SharehouseService.fetchRecentSearches();
    if (!mounted) return;
    setState(() => _recentSearches = list);
  }

  /// 칩의 X 버튼 — 단건 삭제 후 목록 갱신.
  Future<void> _deleteRecentSearch(SearchHistory item) async {
    if (item.id == null) return;
    // 낙관적 갱신.
    final removedAt = _recentSearches.indexWhere((e) => e.id == item.id);
    if (removedAt == -1) return;
    final removed = _recentSearches[removedAt];
    setState(() {
      _recentSearches = List.of(_recentSearches)..removeAt(removedAt);
    });
    try {
      await SharehouseService.deleteRecentSearch(item.id!);
    } catch (_) {
      if (!mounted) return;
      // 실패 시 롤백.
      setState(() {
        final restored = List.of(_recentSearches)..insert(removedAt, removed);
        _recentSearches = restored;
      });
    }
  }

  /// 검색 기록 칩 클릭 — 검색창에 채우고 즉시 검색 실행.
  void _searchByHistory(SearchHistory item) {
    _searchController.text = item.query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: item.query.length),
    );
    _performSearch(item.query);
  }

  /// 입력한 키워드(주소 일부 / 매물명)로 백엔드의 활성 매물을 검색.
  ///
  /// 백엔드 SharehouseSearchReq 는 `address` 와 `keyword` 두 필드를 모두 받으므로
  /// 사용자가 어떤 조합으로 검색해도 잡히도록 둘 다 보낸다.
  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _searchError = null;
        _focusedHouse = null;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final list = await SharehouseService.fetchAllHouses(
        address: q,
        keyword: q,
        status: 'ACTIVE',
        size: 30,
      );
      if (!mounted) return;
      // lat/lon 가진 항목만 지도 핀 대상.
      final withCoords = list
          .where((h) => h.lat != null && h.lon != null)
          .toList(growable: false);
      setState(() {
        _results = withCoords;
        _isSearching = false;
        _focusedHouse = withCoords.isNotEmpty ? withCoords.first : null;
      });
      if (withCoords.isNotEmpty) {
        // 첫 번째 결과로 카메라 이동.
        final first = withCoords.first;
        mapController.move(LatLng(first.lat!, first.lon!), 15.0);
      } else {
        setState(() {
          _searchError = list.isEmpty
              ? 'No houses match this address.'
              : 'No coordinates available for these houses.';
        });
      }
      // 서버가 검색 키워드를 자동 기록하므로, 직후에 목록을 갱신한다.
      _loadRecentSearches();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _results = const [];
        _searchError = 'Failed to search. Please try again.';
      });
    }
  }

  /// 검색 결과 카드 탭 → 그 매물 위치로 카메라 이동 + 상세 페이지 열기.
  void _openHouse(SharehouseModel h) {
    if (h.lat != null && h.lon != null) {
      mapController.move(LatLng(h.lat!, h.lon!), 16.0);
    }
    setState(() => _focusedHouse = h);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharehouseDetailPage(houseId: h.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // 지도 (전체 화면)
          FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.front',
              ),

              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // 상단 검색바와 필터
          Column(
            children: [
              // CustomHeader with Search Bar
              CustomHeader(
                showBack: true,
                toolbarHeight: 72,
                center: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.14),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        autofocus: true,
                        cursorColor: grey03,
                        onSubmitted: _performSearch,
                        decoration: InputDecoration(
                          border: InputBorder.none,

                          prefixIcon: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 2, 12, 0),
                            child: SvgPicture.asset(
                              'assets/icons/pin.svg',
                              width: 20,
                              height: 20,
                              color: green,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),

                          hintText: 'Where do you want to go?',
                          hintStyle: TextStyle(
                            color: grey03,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),

                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),

                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: grey03,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SvgPicture.asset(
                                    'assets/icons/search.svg',
                                    width: 20,
                                    height: 20,
                                    color: grey03,
                                  ),
                                ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ),
              ),

              // 최근 검색어 칩 (서버: GET /sharehouses/recent-searches)
              // - 검색 시 서버가 자동 기록하므로 검색 직후 다시 fetch 한다.
              // - 미로그인/이력 없음 시에는 영역 자체를 숨겨 헤더를 깔끔하게 보여준다.
              if (_recentSearches.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        for (final item in _recentSearches)
                          _historyChip(item),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // 검색 진행 / 결과 안내 / 매물 결과 패널 (하단)
          // 하단 네브바와 겹치지 않도록 bottom 의 base 를 [_kBottomNavbarOverlay]
          // 위로 잡아 둔다. (네브바 height 74 + padding 30 + 약간의 여백)
          if (_isSearching)
            const Positioned(
              left: 0,
              right: 0,
              bottom: _kBottomNavbarOverlay,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: CircularProgressIndicator(color: green),
                  ),
                ),
              ),
            )
          else if (_searchError != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: _kBottomNavbarOverlay,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: grey03),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _searchError!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: dark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_results.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: _kBottomNavbarOverlay,
              child: _buildResultsSheet(),
            ),
        ],
      ),
    );
  }

  /// 검색된 매물 + 기본 핀(검색 전엔 기본 위치)으로 마커 리스트 구성.
  List<Marker> _buildMarkers() {
    if (_results.isEmpty) {
      return [
        Marker(
          point: _defaultCenter,
          width: 40,
          height: 40,
          child: SvgPicture.asset(
            'assets/icons/pin.svg',
            width: 24,
            height: 24,
          ),
        ),
      ];
    }
    return _results.map((h) {
      final bool isFocused = _focusedHouse?.id == h.id;
      return Marker(
        point: LatLng(h.lat!, h.lon!),
        width: isFocused ? 56 : 40,
        height: isFocused ? 56 : 40,
        child: GestureDetector(
          onTap: () => _openHouse(h),
          child: SvgPicture.asset(
            'assets/icons/pin.svg',
            width: isFocused ? 36 : 24,
            height: isFocused ? 36 : 24,
            colorFilter: isFocused
                ? const ColorFilter.mode(green, BlendMode.srcIn)
                : null,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildResultsSheet() {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _results.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final h = _results[i];
          final hasImage = h.imageUrls.isNotEmpty;
          return GestureDetector(
            onTap: () => _openHouse(h),
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: hasImage
                          ? Image.network(
                              h.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: grey01,
                                child: const Icon(Icons.image, color: grey02),
                              ),
                            )
                          : Container(
                              color: grey01,
                              child: const Icon(Icons.home, color: grey02),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          h.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: dark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          h.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: grey03,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${h.rentPrice} / week',
                          style: const TextStyle(
                            fontSize: 12,
                            color: darkgreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 최근 검색어 칩.
  /// - 좌측: 시계 아이콘 + 키워드 텍스트 (탭 시 즉시 그 키워드로 재검색)
  /// - 우측: X 아이콘 (탭 시 그 항목만 삭제, 본인 소유 레코드만 가능)
  Widget _historyChip(SearchHistory item) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _searchByHistory(item),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history,
                    size: 16,
                    color: grey03,
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      item.query,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // X 버튼 — 칩 자체 탭과 충돌하지 않게 별도 InkWell 사용.
                  InkResponse
                      (
                    radius: 16,
                    onTap: item.id != null
                        ? () => _deleteRecentSearch(item)
                        : null,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: grey03,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
