import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/colors.dart';
// 1. 더미 대신 실제 모델 import
import '../models/sharehouse_model.dart';

class HouseCard extends StatelessWidget {
  // 2. 타입을 SharehouseModel로 변경
  final SharehouseModel house;
  final bool isGrid;

  const HouseCard({super.key, required this.house, this.isGrid = false});

  @override
  Widget build(BuildContext context) {
    // 3. 서버 모델 필드에 맞게 변수 매핑
    final imageUrl = house.imageUrls.isNotEmpty
        ? house.imageUrls.first
        : 'https://via.placeholder.com/400x300';

    return Container(
      width: isGrid ? double.infinity : 300,
      margin: EdgeInsets.only(right: isGrid ? 0 : 14, bottom: isGrid ? 16 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이미지 영역
          Padding(
            padding: const EdgeInsets.all(7),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  width: double.infinity,
                  color: grey01,
                  child: const Icon(Icons.home, size: 50, color: grey02),
                ),
              ),
            ),
          ),

          // 카드 내용 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 7, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 제목 + 가격 (house.rentPrice 사용)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        house.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isGrid ? 13 : 15,
                          fontWeight: FontWeight.w800,
                          color: dark,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${house.rentPrice}', // .price 대신 .rentPrice
                      style: TextStyle(
                        fontSize: isGrid ? 12 : 13,
                        fontWeight: FontWeight.w800,
                        color: dark,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 주소
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/pin.svg',
                      width: 12,
                      height: 12,
                      colorFilter: const ColorFilter.mode(
                        green,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        house.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: grey04,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isGrid ? 14 : 19),

                // 아이콘 영역 (서버 모델 필드명에 맞게 수정)
                Wrap(
                  spacing: 6,
                  runSpacing: 3,
                  children: [
                    _iconChip(
                      svg: 'assets/icons/bed.svg',
                      text: '${house.roomCount}', // .beds 대신 .roomCount
                      isGrid: isGrid,
                    ),
                    _iconChip(
                      svg: 'assets/icons/bathroom.svg',
                      text:
                          '${house.bathroomCount}', // .baths 대신 .bathroomCount
                      isGrid: isGrid,
                    ),
                    _iconChip(
                      svg: 'assets/icons/profile.svg',
                      text: '${house.currentResidents}',
                      isGrid: isGrid,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// _iconChip 함수는 기존과 동일하되 Svg color 부분만 업데이트된 방식으로 수정 권장
Widget _iconChip({
  required String svg,
  required String text,
  bool isGrid = false,
}) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isGrid ? 8.65 : 14,
      vertical: isGrid ? 7 : 8,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: grey01, width: 1.2),
      borderRadius: BorderRadius.circular(isGrid ? 16 : 20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          svg,
          width: isGrid ? 13 : 18,
          height: isGrid ? 13 : 18,
          colorFilter: const ColorFilter.mode(dark, BlendMode.srcIn),
        ),
        SizedBox(width: isGrid ? 6 : 10),
        Text(
          text,
          style: TextStyle(
            fontSize: isGrid ? 11 : 13,
            fontWeight: FontWeight.w700,
            color: dark,
            height: 1,
          ),
        ),
      ],
    ),
  );
}
