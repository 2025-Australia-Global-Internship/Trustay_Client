import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';
import 'package:front/models/search_model.dart';
import 'package:front/models/sharehouse_model.dart';
import 'package:front/services/search_service.dart';
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

  Future<void> _loadSearchHistory() async {
    final history = await SearchService.getSearchHistory();
    if (!mounted) return;
    setState(() => _searchHistory = history);
  }

  Future<void> _loadRecentViewed() async {
    final list = await SearchService.getRecentViewed();
    if (!mounted) return;
    setState(() => _recentViewed = list);
  }

  // ──────────────────────────────────────────
  // 검색 기록 조작
  // ──────────────────────────────────────────

  Future<void> _addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;
    await SearchService.addSearchHistory(query);
    await _loadSearchHistory();
  }

  Future<void> _removeSearchQuery(String query) async {
    await SearchService.removeSearchHistory(query);
    await _loadSearchHistory();
  }

  Future<void> _clearAllHistory() async {
    await SearchService.clearSearchHistory();
    await _loadSearchHistory();
  }

  // ──────────────────────────────────────────
  // 최근 본 매물 조작
  // ──────────────────────────────────────────

  Future<void> _clearRecentViewed() async {
    await SearchService.clearRecentViewed();
    await _loadRecentViewed();
  }

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

    _addSearchQuery(trimmed);
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
                        .map((h) => _buildSearchChip(h.query))
                        .toList(),
                  ),
          ),

          const SizedBox(height: 24),

          // 최근 본 매물
          _buildSectionHeader(
            title: 'Recently viewed',
            isEmpty: _recentViewed.isEmpty,
            onDeleteAll: () => _showDeleteDialog(
              message: 'Delete all viewed history?',
              onConfirm: _clearRecentViewed,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          childAspectRatio: 0.68,
                        ),
                    itemCount: _recentViewed.length > 4
                        ? 4
                        : _recentViewed.length,
                    itemBuilder: (context, index) {
                      final house = _recentViewed[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SharehouseDetailPage(houseId: house.id),
                            ),
                          );
                        },
                        child: HouseCard(house: house, isGrid: true),
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

  Widget _buildSearchChip(String query) {
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
              onTap: () => _removeSearchQuery(query),
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
