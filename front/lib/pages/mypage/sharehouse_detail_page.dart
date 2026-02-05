import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:front/constants/colors.dart';
import 'package:front/models/sharehouse_detail_model.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/circle_icon_button.dart';
import 'package:front/widgets/primary_button.dart';

import 'package:front/services/auth_service.dart';
import 'package:front/services/chat_service.dart';
import 'package:front/pages/community/chat_room_page.dart'; // 경로 확인

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
  LatLng? _location;
  bool _isLoadingLocation = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final data = await SharehouseService.getSharehouseDetail(widget.houseId);
      if (mounted) {
        setState(() {
          _house = data;
          _isLoading = false;
        });
      }
      if (data.address != null && data.address!.isNotEmpty) {
        _geocodeAddress(data.address!);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _geocodeAddress(String address) async {
    setState(() => _isLoadingLocation = true);
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'ShareHouseApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          if (mounted) {
            setState(() {
              _location = LatLng(lat, lon);
              _isLoadingLocation = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingLocation = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _handleWishToggle() async {
    try {
      final bool currentStatus = await SharehouseService.toggleWish(
        widget.houseId,
      );
      setState(() => _isWished = currentStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isWished ? "Added to Wishlist." : "Removed from Wishlist.",
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("Wish Error: $e");
    }
  }

  // [수정된 채팅방 생성 로직]
  Future<bool> _handleCreateChat() async {
    print("🚀 Chatting Now Clicked");
    try {
      // 1. 내 정보 가져오기
      final user = await AuthService.fetchProfile();
      print(" - My ID: ${user.memberId}");

      // 2. 채팅방 생성 요청 (hostId 제거, houseId와 내 ID만 전송)
      final int roomId = await ChatService.createOrGetChatRoom(
        widget.houseId,
        user.memberId,
      );

      print("✅ Room Created: $roomId");

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomPage(
              roomId: roomId,
              // 상대방 이름은 현재 페이지의 호스트 이름으로 표시
              roomName: _house?.hostName ?? "Host",
              myMemberId: user.memberId,
            ),
          ),
        );
      }
      return true;
    } catch (e) {
      print("❌ Chat Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("로그인이 필요하거나 오류가 발생했습니다.")));
      }
      return false;
    }
  }

  // --- UI PART ---
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
                      if (_house!.address != null) ...[
                        _buildLocationSection(_house!),
                        const SizedBox(height: 40),
                      ],
                      _buildHostSection(_house!),
                      const SizedBox(height: 40),
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: dark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _house!.description,
                        style: const TextStyle(color: grey04, height: 1.5),
                      ),
                      const SizedBox(height: 35),
                      _buildPropertyDetails(_house!),
                      const SizedBox(height: 36),
                      if (_house!.homeRules != null)
                        _buildChipSection(
                          title: 'Home Rules',
                          commaSeparatedItems: _house!.homeRules,
                        ),
                      const SizedBox(height: 36),
                      if (_house!.features != null)
                        _buildChipSection(
                          title: 'Features',
                          commaSeparatedItems: _house!.features,
                        ),
                      const SizedBox(height: 100),
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

  // UI Helper Widgets (그대로 유지)
  String _formatRoomType(dynamic roomType) {
    final type = roomType.toString().split('.').last.toLowerCase();
    if (type == 'sharedroom') return 'Shared room';
    if (type == 'privateroom') return 'Private room';
    return _capitalize(type);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Widget _buildTopImage(BuildContext context, List<String> images) {
    final imageList = images.isNotEmpty
        ? images
        : ['https://via.placeholder.com/600x400'];
    return Stack(
      children: [
        SizedBox(
          height: 280,
          width: double.infinity,
          child: PageView.builder(
            itemCount: imageList.length,
            onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
            itemBuilder: (context, index) =>
                Image.network(imageList[index], fit: BoxFit.cover),
          ),
        ),
        CustomHeader(showBack: true, backButtonStyle: BackButtonStyle.light),
        Positioned(
          top: 24,
          right: 16,
          child: Column(
            children: [
              CircleIconButton(
                svgAsset: _isWished
                    ? 'assets/icons/heart_filled.svg'
                    : 'assets/icons/heart.svg',
                iconColor: _isWished ? green : dark,
                onPressed: _handleWishToggle,
              ),
              const SizedBox(height: 8),
              CircleIconButton(icon: Icons.share_outlined, onPressed: () {}),
            ],
          ),
        ),
        Positioned(
          bottom: 13,
          left: 16,
          right: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/view.svg',
                        width: 15,
                        height: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "${_house?.viewCount ?? 0}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  imageList.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _currentImageIndex == index
                          ? yellow
                          : Colors.white.withOpacity(0.65),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitlePrice(SharehouseDetailModel house) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 부분
        Expanded(
          child: Text(
            house.title,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            maxLines: 2, // 원하면 줄 수 제한
            overflow: TextOverflow.ellipsis, // 길면 ... 처리
          ),
        ),

        const SizedBox(width: 8), // 제목과 가격 사이 간격
        // 가격 부분 (항상 오른쪽 끝)
        Row(
          children: [
            Text(
              "\$${house.rentPrice}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: dark,
              ),
            ),
            const Text(
              "/week",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: dark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureIcons(SharehouseDetailModel house) {
    return SizedBox(
      height: 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            _iconChip(
              SvgPicture.asset(
                'assets/icons/bed.svg',
                color: dark,
                width: 27,
                height: 27,
              ),
              "${house.roomCount} Rooms",
            ),
            const SizedBox(width: 12),
            _iconChip(
              SvgPicture.asset(
                'assets/icons/bathroom.svg',
                color: dark,
                width: 25,
                height: 25,
              ),
              "${house.bathroomCount} Baths",
            ),
            const SizedBox(width: 12),
            _iconChip(
              SvgPicture.asset(
                'assets/icons/profile.svg',
                width: 26,
                height: 26,
                color: dark,
              ),
              "${house.currentResidents} Resident",
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconChip(Widget icon, String label) {
    return Container(
      width: 135,
      height: 105,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 25, 0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(height: 13),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(SharehouseDetailModel house) {
    final MapController mapController = MapController();
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: SvgPicture.asset(
                'assets/icons/pin.svg',
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                house.address!,
                style: const TextStyle(
                  height: 1.4,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: dark,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                if (_location != null) mapController.move(_location!, 15);
              },
              icon: SvgPicture.asset(
                'assets/icons/reset.svg',
                width: 19,
                height: 19,
                color: grey03,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: _isLoadingLocation
              ? const Center(child: CircularProgressIndicator(color: green))
              : FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: _location ?? LatLng(0, 0),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                    ),
                    if (_location != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _location!,
                            width: 50,
                            height: 50,
                            child: SvgPicture.asset(
                              'assets/icons/house-pin.svg',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
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

  Widget _buildPropertyDetails(SharehouseDetailModel house) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Property Type',
                house.houseType.toString().split('.').last.toLowerCase(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailItem(
                'Bills Included',
                house.billsIncluded ? 'Yes' : 'No',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Room Type',
                _formatRoomType(house.roomType),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailItem('Bond', '${house.bondType} weeks'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Minimum Stay',
                house.minimumStay == 0
                    ? 'No minimum stay'
                    : '${house.minimumStay} months',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildDetailItem('Gender', house.gender)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Age',
                house.age != 'No age rejection'
                    ? 'Minimum ${house.age}'
                    : house.age,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailItem(
                'Religion',
                house.religion != '' ? house.religion : 'Any',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: dark,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(color: grey01, width: 1.2),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Text(
                _capitalize(value),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: dark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChipSection({
    required String title,
    required String? commaSeparatedItems,
  }) {
    final items =
        commaSeparatedItems
            ?.split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .map((e) {
              // _ → 공백으로 바꾸고, 첫 글자만 대문자, 나머지는 소문자
              final formatted = e.replaceAll('_', ' ');
              return formatted[0].toUpperCase() +
                  formatted.substring(1).toLowerCase();
            })
            .toList() ??
        [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: dark,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 24,
          runSpacing: 18,
          children: items.map((e) => _buildCheckChip(e)).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckChip(String text) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 96) / 2,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: green, width: 1.2),
              color: green,
            ),
            child: const Icon(Icons.check, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: dark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
        onAction: () async => await _handleCreateChat(),
        successMessage: "",
        failMessage: "채팅방 생성 실패",
      ),
    );
  }
}
