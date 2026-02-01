import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/colors.dart';
import '../models/house_dummy.dart';

class HouseCard extends StatelessWidget {
  final HouseDummy house;
  final bool isGrid;

  const HouseCard({super.key, required this.house, this.isGrid = false});

  @override
  Widget build(BuildContext context) {
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이미지
          Padding(
            padding: EdgeInsets.all(7),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 140,
                    width: double.infinity,
                    color: grey01,
                    child: const Icon(Icons.home, size: 50, color: grey01),
                  );
                },
              ),
            ),
          ),

          // 카드 내용
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 7, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 제목 + 가격
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
                      '\$${house.price}',
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
                      color: green,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        house.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: grey04,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),

                isGrid ? SizedBox(height: 14) : SizedBox(height: 19),

                // 아이콘 영역
                Wrap(
                  spacing: 6,
                  runSpacing: 3,
                  children: [
                    _iconChip(
                      svg: 'assets/icons/bed.svg',
                      text: '${house.beds}',
                      isGrid: isGrid,
                    ),
                    _iconChip(
                      svg: 'assets/icons/bathroom.svg',
                      text: '${house.baths}',
                      isGrid: isGrid,
                    ),
                    _iconChip(
                      svg: 'assets/icons/profile.svg',
                      text: '${house.people}',
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
      color: Colors.transparent,
      border: Border.all(color: grey01, width: 1.2),
      borderRadius: isGrid
          ? BorderRadius.circular(16)
          : BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          svg,
          width: isGrid ? 13 : 18,
          height: isGrid ? 13 : 18,
          color: dark,
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
