import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // SVG 사용을 위해 추가
import 'package:front/constants/colors.dart';
import 'package:front/models/sharehouse_detail_model.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/circle_icon_button.dart';
import 'package:front/widgets/primary_button.dart';

class SharehouseDetailPage extends StatefulWidget {
  final int houseId;
  const SharehouseDetailPage({super.key, required this.houseId});

  @override
  State<SharehouseDetailPage> createState() => _SharehouseDetailPageState();
}

class _SharehouseDetailPageState extends State<SharehouseDetailPage> {
  SharehouseDetailModel? _house;
  bool _isLoading = true;
  bool _isWished = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final data = await SharehouseService.getSharehouseDetail(widget.houseId);
      setState(() {
        _house = data;
        // [중요] 만약 모델에 isWished 필드가 있다면 여기서 상태를 동기화해야 합니다.
        // 현재 모델에 없다면 기본 false로 시작하되, 클릭 후엔 서버 응답을 따릅니다.
        // _isWished = data.isWished ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleWishToggle() async {
    try {
      // 서버에서 토글 후 최종 '찜 상태(bool)'를 반환받음
      final bool currentStatus = await SharehouseService.toggleWish(
        widget.houseId,
      );

      setState(() {
        _isWished = currentStatus; // 서버가 알려준 true/false를 그대로 반영
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isWished ? "Wishlist에 추가되었습니다." : "Wishlist에서 제거되었습니다.",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint("Wish Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: green)),
      );
    if (_house == null)
      return const Scaffold(body: Center(child: Text("Data not found")));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopImage(context, _house!.imageUrls),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitlePrice(_house!),
                      const SizedBox(height: 20),
                      _buildFeatureIcons(_house!),
                      const SizedBox(height: 24),
                      _buildHostSection(_house!),
                      const SizedBox(height: 20),
                      Text(
                        _house!.description,
                        style: const TextStyle(color: grey04, height: 1.5),
                      ),
                      const SizedBox(height: 30),
                      if (_house!.homeRules != null)
                        _buildInfoSection("Home Rules", _house!.homeRules!),
                      if (_house!.features != null)
                        _buildInfoSection("Features", _house!.features!),
                      const SizedBox(height: 30),
                      _buildDetailGrid(_house!),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildChatButton(),
        ],
      ),
    );
  }

  Widget _buildTopImage(BuildContext context, List<String> images) {
    return Stack(
      children: [
        Image.network(
          images.isNotEmpty
              ? images.first
              : 'https://via.placeholder.com/600x400',
          height: 350,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        CustomHeader(
          showBack: true,
          backButtonStyle: BackButtonStyle.light,
          trailing: Row(
            children: [
              // [핵심] 찜 상태에 따라 svgAsset 경로를 직접 분기 처리
              CircleIconButton(
                // icon 대신 svgAsset을 사용하여 이미지가 바뀌도록 설정
                svgAsset: _isWished
                    ? 'assets/icons/heart_filled.svg'
                    : 'assets/icons/heart.svg',
                iconColor: _isWished ? green : dark,
                onPressed: _handleWishToggle,
              ),
              const SizedBox(width: 8),
              CircleIconButton(icon: Icons.share_outlined, onPressed: () {}),
            ],
          ),
        ),
      ],
    );
  }

  // ... 나머지 UI 메서드 (_buildTitlePrice, _iconChip 등은 이전과 동일) ...
  Widget _buildTitlePrice(SharehouseDetailModel house) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            house.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          "\$${house.rentPrice}/week",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: green,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureIcons(SharehouseDetailModel house) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _iconChip(Icons.king_bed_outlined, "${house.roomCount} Rooms"),
        _iconChip(Icons.bathtub_outlined, "${house.bathroomCount} Baths"),
        _iconChip(Icons.visibility_outlined, "${house.viewCount} Views"),
      ],
    );
  }

  Widget _iconChip(IconData icon, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: grey01),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: grey02),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: grey04)),
        ],
      ),
    );
  }

  Widget _buildDetailGrid(SharehouseDetailModel house) {
    final list = [
      {"label": "Room", "value": house.roomType.toString().split('.').last},
      {"label": "Min. Stay", "value": "${house.minimumStay} months"},
      {"label": "Gender", "value": house.gender},
      {
        "label": "Bills",
        "value": house.billsIncluded ? "Included" : "Excluded",
      },
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: list
          .map(
            (i) => SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i['label']!,
                    style: const TextStyle(color: grey02, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: grey01),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      i['value']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildHostSection(SharehouseDetailModel house) {
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: grey01,
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          "Posted by ${house.hostName}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildChatButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: PrimaryButton(
        formKey: GlobalKey<FormState>(),
        text: "Chatting now",
        onAction: () async => true,
        successMessage: "채팅을 시작합니다.",
        failMessage: "실패",
      ),
    );
  }
}
