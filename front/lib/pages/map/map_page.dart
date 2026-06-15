import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';
import 'package:front/models/sharehouse_model.dart';
import 'package:front/pages/mypage/sharehouse_detail_page.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/custom_header.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  static const LatLng _defaultCenter =
      LatLng(-37.74159952548629, 144.99780308175087);
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _selectedFilter = 'all';

  /// 검색 결과로 표시할 매물 목록. (lat/lon 이 있는 항목만 핀으로 렌더링)
  List<SharehouseModel> _results = const [];
  bool _isSearching = false;
  String? _searchError;
  SharehouseModel? _focusedHouse;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
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

              // Filter Chips
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
                      _filterChip(
                        'Bus stop',
                        selected: _selectedFilter == 'bus',
                        type: 'bus',
                      ),
                      _filterChip(
                        'Tram stop',
                        selected: _selectedFilter == 'tram',
                        type: 'tram',
                      ),
                      _filterChip(
                        'Train station',
                        selected: _selectedFilter == 'train',
                        type: 'train',
                      ),
                      _filterChip(
                        'Restaurant',
                        selected: _selectedFilter == 'restaurant',
                        type: 'restaurant',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 검색 진행 / 결과 안내 / 매물 결과 패널 (하단)
          if (_isSearching)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 24,
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
              bottom: 24,
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
              bottom: 16,
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

  Widget _filterChip(String text, {bool selected = false, String? type}) {
    return GestureDetector(
      onTap: type != null
          ? () {
              setState(() => _selectedFilter = type);
              print('Filter selected: $type');
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        decoration: BoxDecoration(
          color: selected ? green : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
