import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';
import 'package:front/models/search_model.dart';
import 'package:front/models/sharehouse_model.dart';
import 'package:front/models/house_dummy.dart';
import 'package:front/services/search_service.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/house_card.dart';
import 'package:front/widgets/custom_header.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<SearchHistory> _searchHistory = [];
  List<SharehouseModel> _houses = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    try {
      final list = await SharehouseService.getSharehouseList('ALL');
      if (!mounted) return;
      setState(() => _houses = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _houses = []);
    }
  }

  HouseDummy _toHouseDummy(SharehouseModel s) {
    return HouseDummy(
      id: s.id,
      title: s.title,
      address: s.address,
      houseType: s.houseType,
      approvalStatus: 'APPROVED',
      imageUrls: s.imageUrls,
      price: s.rentPrice,
      beds: s.roomCount,
      baths: s.bathroomCount,
      people: s.currentResidents,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final history = await SearchService.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }

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

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });
    _addSearchQuery(query);
    _searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = _isSearching && _searchQuery.isNotEmpty
        ? _houses.where((house) {
            final query = _searchQuery.toLowerCase();
            return house.title.toLowerCase().contains(query) ||
                house.address.toLowerCase().contains(query) ||
                house.houseType.toLowerCase().contains(query);
          }).toList()
        : <SharehouseModel>[];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // CustomHeader 사용
          CustomHeader(
            showBack: true,
            toolbarHeight: 72,
            trailing: Container(
              width: MediaQuery.of(context).size.width - 95,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 8,
                      offset: Offset(0, 2),
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
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _isSearching = false;
                                _searchQuery = '';
                              });
                            },
                          )
                        : Padding(
                            padding: const EdgeInsets.all(12),
                            child: SvgPicture.asset(
                              'assets/icons/search.svg',
                              width: 20,
                              height: 20,
                              color: dark,
                            ),
                          ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),
          ),

          // 검색 결과 또는 최근 검색
          Expanded(
            child: _isSearching && _searchQuery.isNotEmpty
                ? _buildSearchResults(searchResults)
                : _buildRecentSearches(),
          ),
        ],
      ),
    );
  }

  // 최근 검색 및 최근 본 매물
  Widget _buildRecentSearches() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 최근 검색
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recently searches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
                GestureDetector(
                  onTap: _searchHistory.isEmpty
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete all search history?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _clearAllHistory();
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                  child: Text(
                    'Delete all',
                    style: TextStyle(
                      color: _searchHistory.isEmpty ? grey02 : green,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
                        .map((history) => _buildSearchChip(history.query))
                        .toList(),
                  ),
          ),

          const SizedBox(height: 24),

          // 최근 본 매물
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Recently viewed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
                Text(
                  'Delete all',
                  style: TextStyle(
                    color: green,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 9,
                crossAxisSpacing: 11,
                childAspectRatio: 0.68,
              ),
              itemCount: _houses.length > 4 ? 4 : _houses.length,
              itemBuilder: (context, index) =>
                  HouseCard(house: _toHouseDummy(_houses[index]), isGrid: true),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 검색 결과
  Widget _buildSearchResults(List<SharehouseModel> results) {
    if (results.isEmpty) {
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
          '${results.length} results found',
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
          itemCount: results.length,
          itemBuilder: (context, index) =>
              HouseCard(house: _toHouseDummy(results[index]), isGrid: true),
        ),
      ],
    );
  }

  // 검색 기록 칩
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
}
