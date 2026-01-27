import 'package:flutter/material.dart';
import '../models/house_dummy.dart';
import '../constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HouseCard extends StatelessWidget {
  final HouseDummy house;

  const HouseCard({super.key, required this.house});

  @override
  Widget build(BuildContext context) {
    final imageUrl = house.imageUrls.isNotEmpty
        ? house.imageUrls.first
        : 'https://via.placeholder.com/400x300';

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 이미지
          Padding(
            padding: const EdgeInsets.all(10), // 카드 안에서 띄우기
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14), // 이미지 자체 라디우스
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        house.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '\$${house.price}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

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
                        style: const TextStyle(fontSize: 12, color: grey04),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// 아이콘 영역
                Row(
                  children: [
                    _iconChip(
                      svg: 'assets/icons/bed.svg',
                      text: '${house.beds}',
                    ),
                    _iconChip(
                      svg: 'assets/icons/bathroom.svg',
                      text: '${house.baths}',
                    ),
                    _iconChip(
                      svg: 'assets/icons/profile.svg',
                      text: '${house.people}',
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

  Widget _iconChip({required String svg, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: grey02, width: 1.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SvgPicture.asset(svg, width: 16, height: 16, color: dark),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
