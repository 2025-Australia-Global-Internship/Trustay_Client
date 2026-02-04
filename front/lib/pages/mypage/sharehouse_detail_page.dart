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
        _isLoading = false;
      });

      // 주소가 있으면 geocoding 실행
      if (data.address != null && data.address!.isNotEmpty) {
        _geocodeAddress(data.address!);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Nominatim API를 사용한 Geocoding
  Future<void> _geocodeAddress(String address) async {
    setState(() => _isLoadingLocation = true);

    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ShareHouseApp/1.0', // Nominatim requires User-Agent
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          setState(() {
            _location = LatLng(lat, lon);
            _isLoadingLocation = false;
          });
        } else {
          setState(() => _isLoadingLocation = false);
          debugPrint('No location found for address: $address');
        }
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint('Geocoding error: $e');
    }
  }

  Future<void> _handleWishToggle() async {
    try {
      final bool currentStatus = await SharehouseService.toggleWish(
        widget.houseId,
      );

      setState(() {
        _isWished = currentStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isWished ? "Added to Wishlist." : "Removed from Wishlist.",
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: green)),
      );
    }
    if (_house == null) {
      return const Scaffold(body: Center(child: Text("Data not found")));
    }

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
                      // 주소와 지도 섹션 추가
                      if (_house!.address != null) ...[
                        _buildLocationSection(_house!),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildLocationSection(SharehouseDetailModel house) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 주소 텍스트
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on, color: green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                house.address,
                style: const TextStyle(
                  height: 1.4,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: dark,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 지도
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: grey01, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: _isLoadingLocation
              ? const Center(child: CircularProgressIndicator(color: green))
              : _location != null
              ? FlutterMap(
                  options: MapOptions(
                    initialCenter: _location!,
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _location!,
                          width: 50,
                          height: 50,
                          child: Container(
                            clipBehavior: Clip.none, // <-- 확대해도 잘리지 않음
                            decoration: BoxDecoration(
                              color: green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: green.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.home,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, color: grey02, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Location not available',
                        style: TextStyle(color: grey03, fontSize: 14),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTopImage(BuildContext context, List<String> images) {
    return Stack(
      children: [
        Image.network(
          images.isNotEmpty
              ? images.first
              : 'https://via.placeholder.com/600x400',
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        CustomHeader(showBack: true, backButtonStyle: BackButtonStyle.light),
        Positioned(
          top: 24,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
      ],
    );
  }

  Widget _buildTitlePrice(SharehouseDetailModel house) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            house.title,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
        ),
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
            Text(
              "/week",
              style: const TextStyle(
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
              "${house.viewCount} Resident",
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
