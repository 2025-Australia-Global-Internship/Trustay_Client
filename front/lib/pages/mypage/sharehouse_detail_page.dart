import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

// [경로 확인 필요]
import '../../constants/colors.dart';
import '../../models/sharehouse_detail_model.dart';
import '../../services/sharehouse_service.dart'; // [변경] 통합된 서비스 import
import '../../widgets/circle_icon_button.dart';

class SharehouseDetailPage extends StatefulWidget {
  final int houseId;

  const SharehouseDetailPage({super.key, required this.houseId});

  @override
  State<SharehouseDetailPage> createState() => _SharehouseDetailPageState();
}

class _SharehouseDetailPageState extends State<SharehouseDetailPage> {
  // Service 인스턴스 생성 불필요
  
  SharehouseDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      // [변경] SharehouseService 사용
      final data = await SharehouseService.getSharehouseDetail(widget.houseId);
      
      if (!mounted) return;
      setState(() {
        _detail = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // 가격 포맷팅
  String _formatCurrency(int price) {
    return NumberFormat('#,###').format(price);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: green)));
    }

    if (_errorMessage != null || _detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(_errorMessage ?? "데이터를 불러올 수 없습니다.")),
      );
    }

    final data = _detail!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. 상단 이미지 슬라이더
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.white,
                leading: CircleIconButton(
                  icon: Icons.arrow_back,
                  backgroundColor: Colors.white.withOpacity(0.8),
                  onPressed: () => Navigator.pop(context),
                  elevation: 0,
                  size: 40,
                  padding: const EdgeInsets.all(8),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      PageView.builder(
                        itemCount: data.imageUrls.isNotEmpty ? data.imageUrls.length : 1,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          if (data.imageUrls.isEmpty) {
                            return Container(color: grey01, child: const Icon(Icons.home, size: 60, color: grey02));
                          }
                          return Image.network(
                            data.imageUrls[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      if (data.imageUrls.length > 1)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${_currentImageIndex + 1} / ${data.imageUrls.length}",
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. 상세 정보
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 태그
                      Row(
                        children: [
                          _buildTag(data.houseType),
                          const SizedBox(width: 8),
                          _buildTag(data.roomType, color: yellow, textColor: darkgreen),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 제목
                      Text(
                        data.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: dark),
                      ),
                      const SizedBox(height: 8),

                      // 주소
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: grey02),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "${data.address} ${data.addressDetail}",
                              style: const TextStyle(fontSize: 14, color: grey02),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(thickness: 1, color: grey01),
                      const SizedBox(height: 24),

                      // 가격 정보
                      _buildSectionTitle("가격 정보"),
                      _buildPriceRow("월세", "${_formatCurrency(data.monthlyRent)}원 / 월"),
                      _buildPriceRow("보증금", "${_formatCurrency(data.deposit)}원"),
                      _buildPriceRow("관리비", "${_formatCurrency(data.maintenanceFee)}원"),

                      const SizedBox(height: 24),

                      // 옵션
                      _buildSectionTitle("옵션"),
                      data.options.isEmpty
                          ? const Text("등록된 옵션이 없습니다.", style: TextStyle(color: grey02))
                          : Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: data.options.map((opt) => _buildOptionIcon(opt)).toList(),
                            ),

                      const SizedBox(height: 24),
                      const Divider(thickness: 1, color: grey01),
                      const SizedBox(height: 24),

                      // 상세 설명
                      _buildSectionTitle("상세 설명"),
                      Text(
                        data.content,
                        style: const TextStyle(fontSize: 14, height: 1.6, color: dark),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 하단 버튼
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: grey01)),
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // 문의하기 기능 연결
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkgreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("문의하기", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dark)),
    );
  }

  Widget _buildTag(String text, {Color color = grey01, Color textColor = grey02}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: grey02)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: dark)),
        ],
      ),
    );
  }

  Widget _buildOptionIcon(String optionName) {
    String iconPath = 'assets/icons/check.svg'; 
    if (optionName.contains('WIFI')) iconPath = 'assets/icons/wifi.svg';
    if (optionName.contains('BED')) iconPath = 'assets/icons/bed.svg';
    // 필요 아이콘 추가

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.asset(
            iconPath,
            color: dark,
            placeholderBuilder: (_) => const Icon(Icons.check_circle_outline, color: grey02),
          ),
        ),
        const SizedBox(height: 8),
        Text(optionName, style: const TextStyle(fontSize: 12, color: grey03)),
      ],
    );
  }
}