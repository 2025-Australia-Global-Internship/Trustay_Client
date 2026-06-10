import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/colors.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/gradient_layout.dart';
import '../../models/listing_model.dart';
import '../../services/sharehouse_service.dart';
import '../../widgets/my_listing_card.dart';
import 'sharehouse_detail_page.dart';
import '../../widgets/primary_button.dart';

class ListingPage extends StatefulWidget {
  const ListingPage({super.key});

  @override
  State<ListingPage> createState() => _ListingPage();
}

class _ListingPage extends State<ListingPage> {
  final SharehouseService _SharehouseService = SharehouseService();

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
      final listings = await SharehouseService.fetchMyListings();
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
        title: const Text("Delete Listing"),
        content: const Text(
          "Are you sure you want to delete this listing?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: grey02)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performDelete(id);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(int id) async {
    try {
      final success = await SharehouseService.deleteListing(id);
      if (success) {
        setState(() {
          _listings.removeWhere((item) => item.id == id);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing deleted successfully.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete listing: $e")));
    }
  }

  // 수정 로직
  void _editListing(int id) {
    print("Edit Listing ID: $id");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Redirecting to the edit page (coming soon)."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: GradientLayout(
        child: Stack(
          children: [
            Column(
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
                Expanded(child: _buildContent()),
              ],
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: PrimaryButton(
                formKey: GlobalKey<FormState>(), // 단순 이동용이므로 빈 키 전달
                text: 'Create',
                svgIcon: 'assets/icons/plus.svg',
                onAction: () async {
                  // 페이지 이동 후 돌아왔을 때 데이터를 로드하도록 처리
                  await Navigator.pushNamed(context, '/sharehouse_create');
                  _loadData();
                  return true;
                },
                successMessage: '',
                failMessage: '',
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

    if (_listings.isEmpty || _hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: SvgPicture.asset(
                'assets/icons/home-edit.svg',
                color: grey01,
                placeholderBuilder: (_) =>
                    const Icon(Icons.home, size: 86, color: grey02),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No listings yet.',
              style: TextStyle(
                fontSize: 14,
                color: grey02,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'List your shared house to get started.',
              style: TextStyle(
                fontSize: 14,
                color: grey02,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      itemCount: _listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 17),
      itemBuilder: (context, index) {
        final item = _listings[index];
        return MyListingCard(
          item: item,
          onEdit: () => _editListing(item.id),
          onDelete: () => _deleteListing(item.id),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                // 본인이 등록한 매물이므로 조회수가 올라가지 않는 전용 상세 사용
                builder: (context) => SharehouseDetailPage(
                  houseId: item.id,
                  isMyListing: true,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
