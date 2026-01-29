// widgets/my_listing_card.dart

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/listing_model.dart';

class MyListingCard extends StatelessWidget {
  final MyListingItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap; // [추가] 카드 클릭 이벤트

  const MyListingCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.onTap, // [추가]
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED': return green;
      case 'REJECTED': return Colors.red;
      case 'WAITING': default: return const Color(0xFFFFA000);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'APPROVED': return '승인됨';
      case 'REJECTED': return '반려됨';
      case 'WAITING': return '심사중';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // [수정] 카드 전체 클릭 효과(Ripple)를 위해 Material과 InkWell 추가
      child: Material(
        color: Colors.transparent, // 배경색은 Container가 담당
        borderRadius: BorderRadius.circular(16), // 리플 효과가 둥근 모서리를 넘지 않도록 설정
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap, // [연결] 상위에서 전달받은 상세 페이지 이동 함수 실행
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: grey01,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: grey02),
                              )
                            : const Icon(Icons.home, color: grey02),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(item.approvalStatus).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _getStatusColor(item.approvalStatus).withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _getStatusText(item.approvalStatus),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _getStatusColor(item.approvalStatus),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: grey02,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 하단 버튼 영역 (수정 / 삭제)
              // 여기에는 별도의 InkWell이 있으므로, 이 버튼들을 누르면 onTap(상세이동)은 발생하지 않습니다.
              Container(
                height: 44,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF5F5F5))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onEdit,
                        // 하단 모서리 둥글게 처리 (리플 효과용)
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 16, color: grey02),
                            SizedBox(width: 4),
                            Text('수정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: dark)),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, color: const Color(0xFFF5F5F5)),
                    Expanded(
                      child: InkWell(
                        onTap: onDelete,
                        // 하단 모서리 둥글게 처리 (리플 효과용)
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            SizedBox(width: 4), 
                            Text('삭제', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}