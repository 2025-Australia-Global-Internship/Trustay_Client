import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';
import 'package:front/models/search_model.dart';
import 'package:front/models/sharehouse_model.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/house_card.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/pages/mypage/sharehouse_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<SearchHistory> _searchHistory = [];
  List<SharehouseModel> _allHouses = [];
  List<SharehouseModel> _recentViewed = []; // ← SharedPreferences에서 로드
  List<SharehouseModel> _searchResults = [];

  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadHouses();
    _loadRecentViewed(); // ← 추가
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────
  // 데이터 로드
  // ──────────────────────────────────────────

  Future<void> _loadHouses() async {
    try {
      final list = await SharehouseService.fetchAllHouses(houseType: 'ALL');
      if (!mounted) return;
      setState(() => _allHouses = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _allHouses = []);
    }
  }

  // 최근 검색어: 서버 API `/sharehouses/recent-searches` 사용
  //   - 서버가 검색 호출(GET /sharehouses?keyword=...) 시 자동 기록.
  //   - 미로그인/오류 시 빈 리스트 폴백.
  Future<void> _loadSearchHistory() async {
    final history = await SharehouseService.fetchRecentSearches();
    if (!mounted) return;
    setState(() => _searchHistory = history);
  }

  // 최근 본 매물: 서버 API `/sharehouses/recent` 사용
  //   - 서버가 사용자 조회 이력을 기준으로 최근 5개를 내려준다.
  //   - 미로그인/오류 시 빈 리스트 폴백.
  Future<void> _loadRecentViewed() async {
    final list = await SharehouseService.fetchRecentSharehouses();
    if (!mounted) return;
    setState(() => _recentViewed = list);
  }

  // ──────────────────────────────────────────
  // 검색 기록 조작 (서버 API 기반)
  // ──────────────────────────────────────────

  // 검색어 등록 API 는 없다. 서버가 GET /sharehouses?keyword=... 호출 시
  // 자동으로 기록하므로, 검색 실행 후 목록만 다시 받아오면 된다.

  Future<void> _removeSearchQuery(SearchHistory item) async {
    // 서버에 등록되지 않은(=id 가 없는) 항목은 클라이언트 측에서만 제거.
    if (item.id == null) {
      if (!mounted) return;
      setState(() => _searchHistory.removeWhere((h) => h.query == item.query));
      return;
    }
    try {
      await SharehouseService.deleteRecentSearch(item.id!);
      await _loadSearchHistory();
    } catch (e) {
      debugPrint('Recent search delete error: $e');
    }
  }

  Future<void> _clearAllHistory() async {
    try {
      await SharehouseService.deleteAllRecentSearches();
      await _loadSearchHistory();
    } catch (e) {
      debugPrint('Recent searches clear error: $e');
    }
  }

  // ──────────────────────────────────────────
  // 최근 본 매물은 서버에서 자동 집계되므로 클라이언트에서 삭제하지 않는다.
  // ──────────────────────────────────────────

  // ──────────────────────────────────────────
  // 검색 실행 — 백엔드 /sharehouses (keyword) 호출
  //   기존엔 클라이언트에서 _allHouses에 contains 매칭만 했지만,
  //   서버 측 LIKE 검색 + 필터를 사용하도록 교체.
  // ──────────────────────────────────────────

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _searchQuery = trimmed;
      _isSearching = true;
      _searchResults = const [];
    });
    _searchFocus.unfocus();

    try {
      final results = await SharehouseService.fetchAllHouses(
        keyword: trimmed,
        size: 50,
      );
      if (!mounted) return;
      setState(() => _searchResults = results);
    } catch (e) {
      if (!mounted) return;
      // 서버 호출이 실패해도 사용자 흐름을 끊지 않도록 빈 결과만 표시
      setState(() => _searchResults = const []);
    }

    // 서버가 검색 호출 시 자동으로 최근 검색어를 기록하므로,
    // 별도 등록 API 호출 없이 목록만 다시 받아온다.
    await _loadSearchHistory();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchResults = [];
    });
  }

  // ──────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          CustomHeader(
            showBack: true,
            toolbarHeight: 72,
            trailing: Container(
              width: MediaQuery.of(context).size.width - 95,
              height: 50,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: grey03,
                            size: 20,
                          ),
                          onPressed: _clearSearch,
                        )
                      : GestureDetector(
                          onTap: () => _performSearch(_searchController.text),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SvgPicture.asset(
                              'assets/icons/search.svg',
                              width: 20,
                              height: 20,
                              color: grey03,
                            ),
                          ),
                        ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildRecentSection(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // 최근 검색 + 최근 본 매물 화면
  // ──────────────────────────────────────────

  Widget _buildRecentSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 최근 검색
          _buildSectionHeader(
            title: 'Recently searches',
            isEmpty: _searchHistory.isEmpty,
            onDeleteAll: () => _showDeleteDialog(
              message: 'Delete all search history?',
              onConfirm: _clearAllHistory,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _searchHistory.isEmpty
                ? const Text(
                    'No recent searches',
                    style: TextStyle(fontSize: 13, color: grey03),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _searchHistory
                        .map((h) => _buildSearchChip(h))
                        .toList(),
                  ),
          ),

          const SizedBox(height: 24),

          // 최근 본 매물 (서버 자동 집계 - 최신 5개)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              children: const [
                Text(
                  'Recently viewed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _recentViewed.isEmpty
                ? const Text(
                    'No recently viewed houses',
                    style: TextStyle(fontSize: 13, color: grey03),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 9,
                          crossAxisSpacing: 11,
                          childAspectRatio: 0.65,
                        ),
                    itemCount: _recentViewed.length,
                    itemBuilder: (context, index) {
                      final house = _recentViewed[index];
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SharehouseDetailPage(houseId: house.id),
                            ),
                          );
                          // 상세 페이지에서 돌아오면 최근 본 매물 목록도 갱신
                          _loadRecentViewed();
                        },
                        child: HouseCard(
                          house: house,
                          isGrid: true,
                          initialIsWished: house.wishedByMe,
                          onWishChanged: (wished) {
                            // 찜 상태 변경 시 로컬 모델도 동기화 (재진입 시 깜빡임 방지)
                            // SharehouseModel.wishedByMe 가 final 이므로
                            // 새 인스턴스로 교체한다.
                            setState(() {
                              _recentViewed[index] = SharehouseModel(
                                id: house.id,
                                title: house.title,
                                address: house.address,
                                houseType: house.houseType,
                                imageUrls: house.imageUrls,
                                rentPrice: house.rentPrice,
                                bathroomCount: house.bathroomCount,
                                roomCount: house.roomCount,
                                currentResidents: house.currentResidents,
                                viewCount: house.viewCount,
                                wishCount: house.wishCount,
                                wishedByMe: wished,
                                approvalStatus: house.approvalStatus,
                                lat: house.lat,
                                lon: house.lon,
                              );
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // 검색 결과 화면
  // ──────────────────────────────────────────

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/search.svg',
              width: 80,
              height: 80,
              color: grey02,
            ),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: grey03,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try different keywords',
              style: TextStyle(fontSize: 14, color: grey03),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${_searchResults.length} results found',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: dark,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 9,
            crossAxisSpacing: 11,
            childAspectRatio: 0.68,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) =>
              HouseCard(house: _searchResults[index], isGrid: true),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // 공통 위젯
  // ──────────────────────────────────────────

  Widget _buildSectionHeader({
    required String title,
    required bool isEmpty,
    required VoidCallback onDeleteAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
          GestureDetector(
            onTap: isEmpty ? null : onDeleteAll,
            child: Text(
              'Delete all',
              style: TextStyle(
                color: isEmpty ? grey02 : green,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchChip(SearchHistory item) {
    final query = item.query;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: grey01, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                _searchController.text = query;
                _performSearch(query);
              },
              child: Text(
                query,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: dark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _removeSearchQuery(item),
              child: const Icon(Icons.close, size: 16, color: grey03),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog({
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
