import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// [중요] 경로에 맞춰 import를 수정해주세요.
import '../../constants/colors.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/gradient_layout.dart';
import '../../models/listing_model.dart';
import '../../services/listing_service.dart';
import '../../widgets/my_listing_card.dart';
import 'sharehouse_detail_page.dart'; // [추가] 상세 페이지 import

class ListingPage extends StatefulWidget {
  const ListingPage({super.key});

  @override
  State<ListingPage> createState() => _ListingPage();
}

class _ListingPage extends State<ListingPage> {
  final ListingService _listingService = ListingService();

  List<MyListingItem> _listings = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 데이터 로드
  Future<void> _loadData() async {
    try {
      final listings = await _listingService.fetchMyListings();
      if (!mounted) return;
      setState(() {
        _listings = listings;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      print('ERROR: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // 삭제 로직
  void _deleteListing(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("매물 삭제"),
        content: const Text("정말로 이 매물을 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소", style: TextStyle(color: grey02)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performDelete(id);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(int id) async {
    try {
      final success = await _listingService.deleteListing(id);
      if (success) {
        setState(() {
          _listings.removeWhere((item) => item.id == id);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("매물이 삭제되었습니다.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("삭제 실패: $e")),
      );
    }
  }

  // 수정 로직
  void _editListing(int id) {
    // TODO: 수정 페이지로 이동 구현
    print("Edit Listing ID: $id");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("수정 페이지로 이동합니다 (구현 예정)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientLayout(
        child: Column(
          children: [
            CustomHeader(
              center: const Text(
                'Listings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
              showBack: true,
            ),
            
            Expanded(
              child: _buildContent(),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // 생성 후 돌아왔을 때 새로고침
                    Navigator.pushNamed(context, '/sharehouse_create').then((_) {
                      _loadData();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: darkgreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Create New Listing',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
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

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("매물 정보를 불러오지 못했습니다.", style: TextStyle(color: grey02)),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() { _isLoading = true; });
                _loadData();
              },
              child: const Text("다시 시도", style: TextStyle(color: dark, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }

    if (_listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 86,
              height: 86,
              child: SvgPicture.asset(
                'assets/icons/home-edit.svg',
                color: grey02,
                placeholderBuilder: (_) => const Icon(Icons.home, size: 86, color: grey02),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '등록된 매물이 없습니다.',
              style: TextStyle(fontSize: 13, color: grey02, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _listings[index];
        return MyListingCard(
          item: item,
          onEdit: () => _editListing(item.id),
          onDelete: () => _deleteListing(item.id),
          // [추가된 부분] 카드를 눌렀을 때 상세 페이지로 이동
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SharehouseDetailPage(houseId: item.id),
              ),
            );
          },
        );
      },
    );
  }
}