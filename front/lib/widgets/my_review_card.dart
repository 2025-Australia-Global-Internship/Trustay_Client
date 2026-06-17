// widgets/my_review_card.dart
//
// "My Reviews" 페이지에서 내가 작성한 리뷰 한 건을 보여주는 카드.
// 디자인 컨벤션은 MyListingCard 와 동일하게 맞췄다.
//   - 좌측 매물 썸네일 + 우측 상단 별점 뱃지 + 제목 + 주소
//   - 아래쪽 박스에 리뷰 본문
//   - 하단에 Delete 액션 (Edit/Delete 같은 분할 버튼 대신 단일 행)

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/colors.dart';
import '../models/review_model.dart';

class MyReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback? onTap; // 카드 탭 → 매물 상세
  final VoidCallback? onDelete;

  const MyReviewCard({
    super.key,
    required this.review,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = review.houseImageUrl ?? '';
    final title = (review.houseTitle?.trim().isNotEmpty ?? false)
        ? review.houseTitle!
        : 'Listing unavailable';
    final address = (review.houseAddress?.trim().isNotEmpty ?? false)
        ? review.houseAddress!
        : 'Address unavailable';
    final content = (review.content?.trim().isNotEmpty ?? false)
        ? review.content!.trim()
        : 'No comment.';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 100,
                            height: 80,
                            color: grey01,
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      color: grey02,
                                    ),
                                  )
                                : const Icon(Icons.home, color: grey02),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ratingBadge(review.rating),
                              const SizedBox(height: 8),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: dark,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: grey04,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: dark,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                Container(
                  height: 44,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF5F5F5))),
                  ),
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 15,
                          height: 15,
                          child: SvgPicture.asset(
                            'assets/icons/trash.svg',
                            color: Colors.redAccent,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 별점 배지. listing card 의 status 뱃지 자리에 들어가는 동일한 모양.
  Widget _ratingBadge(int rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: green.withOpacity(0.5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: green),
          const SizedBox(width: 3),
          Text(
            '$rating.0',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: green,
            ),
          ),
        ],
      ),
    );
  }
}
