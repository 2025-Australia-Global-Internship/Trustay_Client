import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialCommPage extends StatelessWidget {
  const SocialCommPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                children: [
                  // My community section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My community',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildAddCommunity(),
                        _buildCommunityItem('assets/images/study.jpg', 'Study'),
                        _buildCommunityItem('assets/images/cafe.jpg', 'Cafe'),
                        _buildCommunityItem(
                          'assets/images/running.jpg',
                          'Running',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Trending section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trending',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            color: green,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 180, // 카드 높이
                    child: trendingCardList([
                      {
                        'title': 'Tennis',
                        'subtitle': 'Active 3 hours ago',
                        'count': '16',
                        'imagePath': 'assets/images/tennis.jpg',
                      },
                      {
                        'title': 'Baking',
                        'subtitle': 'Active 12 hours ago',
                        'count': '23',
                        'imagePath': 'assets/images/baking.jpg',
                      },
                      {
                        'title': 'Reading',
                        'subtitle': 'Active 5 hours ago',
                        'count': '12',
                        'imagePath': 'assets/images/reading.jpg',
                      },
                    ]),
                  ),

                  const SizedBox(height: 36),

                  // Posts for you
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Posts for you',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Post items
                  _buildPostCard(
                    'Claire',
                    '8 hours ago',
                    'Just finished my morning run! Feeling energized and ready for the day.',
                    true,
                    1,
                    '1k',
                    imagePath: 'assets/images/morning.jpg',
                  ),
                  _buildPostCard(
                    'Ella',
                    '9 hours ago',
                    'Baked some chocolate chip cookies today, they turned out amazing!',
                    true,
                    10,
                    '1k',
                    imagePath: 'assets/images/cookies.jpg',
                  ),
                  _buildPostCard(
                    'Hannah',
                    '9 hours ago',
                    'Reading a new mystery novel, can’t put it down!',
                    false,
                    18,
                    '1k',
                  ),
                  _buildPostCard(
                    'Annie',
                    '9 hours ago',
                    'Started learning guitar, fingers hurt but it’s fun!',
                    true,
                    10,
                    '1k',
                    imagePath: 'assets/images/guitar.jpg',
                  ),
                  _buildPostCard(
                    'Charlotte',
                    '9 hours ago',
                    'Went for a hike today, the view from the top was breathtaking!',
                    false,
                    36,
                    '1k',
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCommunity() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 70,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: green, width: 1.2),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/plus.svg',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                color: green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityItem(String image, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 70,
      child: Column(
        children: [
          CircleAvatar(radius: 35, backgroundImage: AssetImage(image)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkgreen,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget trendingCardList(List<Map<String, String>> items) {
    return SizedBox(
      height: 180, // 카드 높이 + 여유
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildTrendingCard(
            item['title'] ?? '',
            item['subtitle'] ?? '',
            item['count'] ?? '0',
            imagePath: item['imagePath'],
          );
        },
      ),
    );
  }

  Widget _buildTrendingCard(
    String title,
    String subtitle,
    String count, {
    String? imagePath,
  }) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 이미지 영역
            Padding(
              padding: EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imagePath != null && imagePath.isNotEmpty
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 110,
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
              ),
            ),

            // 우측 상단 count 박스
            Positioned(
              bottom: 69,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: yellow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/social.svg',
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 텍스트 영역
            Positioned(
              bottom: 11,
              left: 13,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: grey03),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: grey03,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(
    String name,
    String time,
    String content,
    bool hasImage,
    int comments,
    String likes, {
    String? imagePath,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(time, style: TextStyle(fontSize: 12, color: grey03)),
                  ],
                ),
              ),
              Baseline(
                baseline: 8,
                baselineType: TextBaseline.alphabetic,
                child: SvgPicture.asset(
                  'assets/icons/dots-linear.svg',
                  width: 28,
                  height: 28,
                  color: dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w400,
              color: dark,
            ),
          ),
          if (hasImage) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 200,
                width: double.infinity,
                child: imagePath != null && imagePath.isNotEmpty
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              SvgPicture.asset('assets/icons/heart.svg'),
              const SizedBox(width: 4),
              Text(likes, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 16),
              SvgPicture.asset(
                'assets/icons/community.svg',
                width: 21,
                height: 21,
              ),
              const SizedBox(width: 4),
              Text('$comments', style: const TextStyle(fontSize: 14)),
              const Spacer(),
              SvgPicture.asset(
                'assets/icons/bookmark.svg',
                width: 19,
                height: 19,
                color: dark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
