import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/models/user_model.dart';
import 'package:front/models/sharehouse_model.dart';
import 'package:front/models/house_dummy.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/circle_icon_button.dart';
import 'package:front/widgets/house_card.dart';
// 상세 페이지 이동을 위해 import 추가
import '../../pages/mypage/sharehouse_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user;
  String _selectedFilter = 'ALL'; // 필터 상태: ALL, HOUSE, APARTMENT, UNIT
  List<SharehouseModel> _houses = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadHouses();
  }

  Future<void> _loadProfile() async {
    final data = await AuthService.fetchProfile();
    setState(() {
      user = data;
    });
  }

  Future<void> _loadHouses() async {
    try {
      final list = await SharehouseService.getSharehouseList(_selectedFilter);
      if (!mounted) return;
      setState(() => _houses = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _houses = []);
    }
  }

  HouseDummy _toHouseDummy(SharehouseModel s) {
    const String baseUrl = "https://trustay.digitalbasis.com";

    List<String> fullImageUrls = s.imageUrls.map((url) {
      if (url.startsWith('https')) {
        return url;
      }
      return url.startsWith('/') ? '$baseUrl$url' : '$baseUrl/$url';
    }).toList();
    return HouseDummy(
      id: s.id,
      title: s.title,
      address: s.address,
      houseType: s.houseType,
      approvalStatus: 'APPROVED',
      imageUrls: fullImageUrls,
      price: s.rentPrice,
      beds: s.roomCount,
      baths: s.bathroomCount,
      currentResidents: s.currentResidents,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Navigator에서 원본 모델의 id를 사용하기 위해 맵핑 시기를 조절하거나
    // 리스트 자체를 유지한 채 빌드 시점에 변환합니다.
    final popularList = _houses.take(4).toList();
    final generalList = _houses;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GradientLayout(
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
                        backgroundImage: NetworkImage(
                          user?.profileImageUrl?.isNotEmpty == true
                              ? user!.profileImageUrl!
                              : 'https://i.pravatar.cc/150',
                        ),
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
                    _filterChip('Filter', icon: 'assets/icons/filter.svg'),
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
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

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
                        house: _toHouseDummy(item),
                        isGrid: false,
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
                    child: HouseCard(house: _toHouseDummy(item), isGrid: true),
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

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
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
