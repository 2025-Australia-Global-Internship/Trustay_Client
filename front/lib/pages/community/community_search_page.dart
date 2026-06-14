import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:front/constants/colors.dart';
import 'package:front/models/community_model.dart';
import 'package:front/models/search_model.dart';
import 'package:front/pages/community/community_detail_page.dart';
import 'package:front/services/community_service.dart';
import 'package:front/widgets/custom_header.dart';

/// 커뮤니티 이름 키워드 검색 페이지.
///
/// 메인의 [`SearchPage`](home/search_page.dart)와 동일한 패턴을 따른다.
/// - 입력 전: "Recently searches" + "Recently viewed" (서버 자동 집계)
/// - 입력 후: 결과 리스트 (커뮤니티 카드)
///
/// 서버는 `GET /communities?keyword=...` 호출 시 자동으로 최근 검색어를 기록하고,
/// `GET /communities/{id}` 호출 시 자동으로 최근 본 커뮤니티를 갱신한다.
/// (둘 다 토큰이 있을 때만 기록)
class CommunitySearchPage extends StatefulWidget {
  const CommunitySearchPage({super.key});

  @override
  State<CommunitySearchPage> createState() => _CommunitySearchPageState();
}

class _CommunitySearchPageState extends State<CommunitySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<SearchHistory> _searchHistory = [];
  List<CommunityModel> _recentViewed = [];
  List<CommunityModel> _searchResults = [];

  bool _isSearching = false;
  bool _isLoadingResults = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadRecentViewed();
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

  Future<void> _loadSearchHistory() async {
    final history = await CommunityService.fetchRecentSearches();
    if (!mounted) return;
    setState(() => _searchHistory = history);
  }

  Future<void> _loadRecentViewed() async {
    final list = await CommunityService.fetchRecentCommunities();
    if (!mounted) return;
    setState(() => _recentViewed = list);
  }

  // ──────────────────────────────────────────
  // 최근 검색어 조작
  // ──────────────────────────────────────────

  Future<void> _removeSearchQuery(SearchHistory item) async {
    if (item.id == null) {
      if (!mounted) return;
      setState(() => _searchHistory.removeWhere((h) => h.query == item.query));
      return;
    }
    try {
      await CommunityService.deleteRecentSearch(item.id!);
      await _loadSearchHistory();
    } catch (e) {
      debugPrint('Community recent search delete error: $e');
    }
  }

  Future<void> _clearAllHistory() async {
    try {
      await CommunityService.deleteAllRecentSearches();
      await _loadSearchHistory();
    } catch (e) {
      debugPrint('Community recent searches clear error: $e');
    }
  }

  // ──────────────────────────────────────────
  // 검색 실행 — 백엔드 /communities (keyword) 호출
  // ──────────────────────────────────────────

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _searchQuery = trimmed;
      _isSearching = true;
      _isLoadingResults = true;
      _searchResults = const [];
    });
    _searchFocus.unfocus();

    try {
      final results = await CommunityService.fetchCommunities(
        keyword: trimmed,
        size: 50,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isLoadingResults = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _isLoadingResults = false;
      });
    }

    // 서버가 검색 호출 시 자동으로 최근 검색어를 기록하므로 목록만 다시 받는다.
    await _loadSearchHistory();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchResults = const [];
    });
  }

  Future<void> _openCommunityDetail(CommunityModel c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommunityDetailPage(communityId: c.id, initial: c),
      ),
    );
    if (!mounted) return;
    // 상세에서 돌아오면 최근 본 목록은 갱신될 가능성이 있다.
    _loadRecentViewed();
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
                  hintText: 'Search communities',
                  hintStyle: const TextStyle(color: grey03, fontSize: 14),
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
                onChanged: (_) => setState(() {}),
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
  // 최근 검색 + 최근 본 커뮤니티 화면
  // ──────────────────────────────────────────

  Widget _buildRecentSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // 최근 본 커뮤니티 (서버 자동 집계 - 최신 5개)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              'Recently viewed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: dark,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _recentViewed.isEmpty
                ? const Text(
                    'No recently viewed communities',
                    style: TextStyle(fontSize: 13, color: grey03),
                  )
                : SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentViewed.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final c = _recentViewed[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openCommunityDetail(c),
                          child: _buildRecentCommunityTile(c),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 가로 스크롤 카드. 원형 아바타 + 이름 + 멤버 수.
  Widget _buildRecentCommunityTile(CommunityModel c) {
    final hasImage = c.imageUrl != null && c.imageUrl!.isNotEmpty;
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.grey[300],
            backgroundImage: hasImage
                ? NetworkImage(c.imageUrl!) as ImageProvider
                : const AssetImage('assets/icons/default.png'),
          ),
          const SizedBox(height: 8),
          Text(
            c.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: dark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '${c.memberCount} members',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: grey03),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // 검색 결과 화면
  // ──────────────────────────────────────────

  Widget _buildSearchResults() {
    if (_isLoadingResults) {
      return const Center(child: CircularProgressIndicator(color: green));
    }
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
            Text(
              'No communities matched "$_searchQuery"',
              style: const TextStyle(fontSize: 14, color: grey03),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _searchResults.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1, color: grey01),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_searchResults.length} results found',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
          );
        }
        final c = _searchResults[index - 1];
        return _buildResultTile(c);
      },
    );
  }

  Widget _buildResultTile(CommunityModel c) {
    final hasImage = c.imageUrl != null && c.imageUrl!.isNotEmpty;
    return InkWell(
      onTap: () => _openCommunityDetail(c),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              backgroundImage: hasImage
                  ? NetworkImage(c.imageUrl!) as ImageProvider
                  : const AssetImage('assets/icons/default.png'),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.category.label} · ${c.memberCount} members',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: grey03),
                  ),
                  if (c.description != null &&
                      c.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      c.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: grey03),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: grey02),
          ],
        ),
      ),
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
