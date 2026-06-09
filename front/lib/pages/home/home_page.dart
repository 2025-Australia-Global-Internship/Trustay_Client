import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/models/user_model.dart';
import 'package:front/models/sharehouse_model.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/circle_icon_button.dart';
import 'package:front/widgets/house_card.dart';
// 상세 페이지 이동을 위해 import 추가
import '../../pages/mypage/sharehouse_detail_page.dart';

import 'package:front/main.dart'; // routeObserver import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  User? user;
  String _selectedFilter = 'ALL'; // 필터 상태: ALL, HOUSE, APARTMENT, UNIT
  List<SharehouseModel> _houses = [];
  Set<int> _wishedIds = {}; // 찜한 매물 id 집합
  bool _isLoading = false; // 로딩 상태 추가

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadHouses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // routeObserver에 등록
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // 다른 페이지에서 pop되어 홈으로 돌아올 때 호출
  @override
  void didPopNext() {
    _loadHouses(); // ← 여기서 실행됨
  }

  // 프로필 정보 로드
  Future<void> _loadProfile() async {
    try {
      final data = await AuthService.fetchProfile();
      setState(() => user = data);
    } catch (e) {
      debugPrint('Profile Load Error: $e');
    }
  }

  // 쉐어하우스 목록 + 찜 목록 병렬 로드
  Future<void> _loadHouses() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SharehouseService.fetchAllHouses(houseType: _selectedFilter),
        SharehouseService.fetchWishlist(),
      ]);
      setState(() {
        _houses = results[0] as List<SharehouseModel>;
        _wishedIds = (results[1] as List<SharehouseModel>)
            .map((h) => h.id)
            .toSet();
      });
    } catch (e) {
      debugPrint('House Load Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 필터 칩 클릭 시 호출될 함수
  void _onFilterSelected(String type) {
    setState(() => _selectedFilter = type);
    _loadHouses(); // 필터 변경 시 다시 불러오기
  }

  @override
  Widget build(BuildContext context) {
    // Navigator에서 원본 모델의 id를 사용하기 위해 맵핑 시기를 조절하거나
    // 리스트 자체를 유지한 채 빌드 시점에 변환합니다.
    final popularList = _houses.take(4).toList();
    final generalList = _houses;

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: GradientLayout(
        child: RefreshIndicator(
          onRefresh: _loadHouses,
          child: CustomScrollView(
            slivers: [
              // 헤더
              SliverToBoxAdapter(
                child: CustomHeader(
                  showBack: false,
                  toolbarHeight: 64,
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              user?.profileImageUrl?.isNotEmpty == true
                              ? NetworkImage(user!.profileImageUrl!)
                                    as ImageProvider
                              : const AssetImage('assets/icons/default.png'),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/pin.svg',
                                  width: 14,
                                  height: 14,
                                  color: green,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  (user?.location ?? 'Location'),
                                  style: const TextStyle(
                                    color: grey04,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Welcome, ${user?.name ?? ''}!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: dark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    children: [
                      CircleIconButton(
                        svgAsset: 'assets/icons/search.svg',
                        iconSize: 23,
                        padding: const EdgeInsets.only(right: 8),
                        onPressed: () {
                          Navigator.pushNamed(context, '/search');
                        },
                      ),
                      CircleIconButton(
                        svgAsset: 'assets/icons/bell.svg',
                        iconSize: 22,
                        iconColor: dark,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),

              // 제목
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Explore Your Place to Stay,',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: dark,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Built on Trust.',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 필터칩
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 45,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _filterChip(
                        'Filter',
                        icon: 'assets/icons/filter.svg',
                        type: 'ALL',
                      ), // ALL 등으로 타입 지정
                      const SizedBox(width: 6),
                      _filterChip(
                        'All',
                        selected: _selectedFilter == 'ALL',
                        type: 'ALL',
                      ),
                      _filterChip(
                        'House',
                        selected: _selectedFilter == 'HOUSE',
                        type: 'HOUSE',
                      ),
                      _filterChip(
                        'Apartment',
                        selected: _selectedFilter == 'APARTMENT',
                        type: 'APARTMENT',
                      ),
                      _filterChip(
                        'Unit',
                        selected: _selectedFilter == 'UNIT',
                        type: 'UNIT',
                      ),
                      _filterChip(
                        'Townhouse',
                        selected: _selectedFilter == 'TOWNHOUSE',
                        type: 'TOWNHOUSE',
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator(color: green)),
                ),

              // Popular Listings
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Popular listings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'See all',
                        style: TextStyle(
                          color: green,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // Popular horizontal list (수정됨: 클릭 시 상세페이지 이동)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 270,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: popularList.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final item = popularList[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SharehouseDetailPage(houseId: item.id),
                            ),
                          );
                        },
                        child: HouseCard(
                          house: item,
                          isGrid: false,
                          initialIsWished: _wishedIds.contains(item.id),
                          onWishChanged: (wished) {
                            setState(() {
                              if (wished) {
                                _wishedIds.add(item.id);
                              } else {
                                _wishedIds.remove(item.id);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 36)),

              // Personalized
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Personalized',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'See all',
                        style: TextStyle(
                          color: green,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // Personalized Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = generalList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SharehouseDetailPage(houseId: item.id),
                          ),
                        );
                      },
                      child: HouseCard(
                        house: item,
                        isGrid: true,
                        initialIsWished: _wishedIds.contains(item.id),
                        onWishChanged: (wished) {
                          setState(() {
                            if (wished) {
                              _wishedIds.add(item.id);
                            } else {
                              _wishedIds.remove(item.id);
                            }
                          });
                        },
                      ),
                    );
                  }, childCount: generalList.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 11,
                    childAspectRatio: 0.68,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 72)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(
    String text, {
    bool selected = false,
    String? icon,
    String? type,
  }) {
    return GestureDetector(
      onTap: type != null
          ? () {
              setState(() => _selectedFilter = type);
              _loadHouses();
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? green : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? green : grey01, width: 1.2),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              SvgPicture.asset(
                icon,
                width: 16,
                height: 16,
                color: selected ? Colors.white : dark,
              ),
              const SizedBox(width: 8),
            ],
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
