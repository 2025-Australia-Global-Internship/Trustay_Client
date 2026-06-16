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
            height: MediaQuery.of(context).size.height * 0.7,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: grey02,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap the heart on any listing to save it.',
                  style: TextStyle(
                    fontSize: 14,
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

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _wishlist.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 9,
        crossAxisSpacing: 11,
        childAspectRatio: 0.65, // 카드의 가로세로 비율
      ),
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
            _loadData();
          },
          child: HouseCard(
            house: item,
            isGrid: true,
            initialIsWished: true, // 찜 목록이므로 항상 true
            onWishChanged: (wished) {
              if (!wished) {
                // 찜 취소 시 목록에서 즉시 제거
                setState(() => _wishlist.removeWhere((h) => h.id == item.id));
              }
            },
          ),
        );
      },
    );
  }
}
