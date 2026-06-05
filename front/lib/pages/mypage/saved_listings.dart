import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/colors.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/gradient_layout.dart';
import '../../models/sharehouse_model.dart';
import '../../services/sharehouse_service.dart';
import '../../widgets/house_card.dart';
import 'sharehouse_detail_page.dart';

class SavedListingsPage extends StatefulWidget {
  const SavedListingsPage({super.key});

  @override
  State<SavedListingsPage> createState() => _SavedListingsPageState();
}

class _SavedListingsPageState extends State<SavedListingsPage> {
  List<SharehouseModel> _wishlist = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final wishlist = await SharehouseService.fetchWishlist();
      if (!mounted) return;
      setState(() {
        _wishlist = wishlist;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Wishlist Load Error: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: GradientLayout(
        child: Column(
          children: [
            CustomHeader(
              center: const Text(
                'Saved',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
              showBack: true,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: green,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }

    if (_wishlist.isEmpty || _hasError) {
      return ListView(
        // RefreshIndicator가 동작하려면 스크롤 가능해야 함
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/heart.svg',
                  width: 72,
                  height: 72,
                  colorFilter: const ColorFilter.mode(grey01, BlendMode.srcIn),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No saved listings yet.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: grey02,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap the heart on any listing to save it.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: grey02,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _wishlist.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = _wishlist[index];
        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SharehouseDetailPage(houseId: item.id),
              ),
            );
            _loadData(); // 디테일에서 찜 해제하고 돌아오면 목록 갱신
          },
          child: HouseCard(house: item, isGrid: false),
        );
      },
    );
  }
}
