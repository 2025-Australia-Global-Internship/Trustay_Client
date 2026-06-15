import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/colors.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/gradient_layout.dart';
import '../../widgets/my_review_card.dart';
import 'sharehouse_detail_page.dart';

/// "My Reviews" — 내가 작성한 리뷰들을 카드 형태로 보여주는 페이지.
///
/// 디자인 컨벤션은 [ListingPage] 와 동일하게 맞췄다.
/// 카드 탭 시 해당 매물 상세로 이동하고, 우측 하단 Delete 액션으로 본인 리뷰를 삭제할 수 있다.
class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final reviews = await ReviewService.getMyReviews(size: 50);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _confirmDelete(ReviewModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Review',
          style: TextStyle(fontWeight: FontWeight.w800, color: dark),
        ),
        content: const Text(
          'Are you sure you want to delete this review?\nThis action cannot be undone.',
          style: TextStyle(color: grey04, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: grey02)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performDelete(r);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(ReviewModel r) async {
    try {
      await ReviewService.deleteReview(r.id);
      if (!mounted) return;
      setState(() {
        _reviews.removeWhere((e) => e.id == r.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete review: $e')),
      );
    }
  }

  void _openHouse(ReviewModel r) {
    final houseId = r.houseId;
    if (houseId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharehouseDetailPage(houseId: houseId),
      ),
    );
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
                'My Reviews',
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
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }
    if (_hasError) {
      return _emptyState(
        title: 'Unable to load reviews.',
        subtitle: 'Pull down or try again later.',
      );
    }
    if (_reviews.isEmpty) {
      return _emptyState(
        title: 'No reviews yet.',
        subtitle: 'Reviews you write will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: green,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        itemCount: _reviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: 17),
        itemBuilder: (context, index) {
          final r = _reviews[index];
          return MyReviewCard(
            review: r,
            onTap: r.houseId != null ? () => _openHouse(r) : null,
            onDelete: () => _confirmDelete(r),
          );
        },
      ),
    );
  }

  Widget _emptyState({required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: SvgPicture.asset(
              'assets/icons/review.svg',
              color: grey01,
              placeholderBuilder: (_) =>
                  const Icon(Icons.rate_review_outlined, size: 86, color: grey02),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: grey02,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: grey02,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
