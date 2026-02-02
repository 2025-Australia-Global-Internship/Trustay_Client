import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/models/sharehouse_create_model.dart';
import 'package:front/services/sharehouse_service.dart';
import 'sharehouse_create_step2.dart';
import 'package:front/widgets/primary_button.dart';
import 'package:front/widgets/common_text_field.dart';

class SharehouseCreateStep1Page extends StatefulWidget {
  const SharehouseCreateStep1Page({super.key});

  @override
  State<SharehouseCreateStep1Page> createState() =>
      _SharehouseCreateStep1PageState();
}

class _SharehouseCreateStep1PageState extends State<SharehouseCreateStep1Page> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // 이미지
  List<File> _selectedImages = [];
  final int _maxImages = 10;

  // 폼 필드
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailedAddressController =
      TextEditingController();

  // 주소 검색 결과
  List<String> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  int _selectedAddressIndex = -1;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _detailedAddressController.dispose();
    super.dispose();
  }

  // 이미지 선택
  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 $_maxImages개의 이미지만 선택할 수 있습니다.')),
      );
      return;
    }

    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        final remainingSlots = _maxImages - _selectedImages.length;
        final filesToAdd = pickedFiles
            .take(remainingSlots)
            .map((xFile) => File(xFile.path))
            .toList();
        _selectedImages.addAll(filesToAdd);
      });
    }
  }

  // 이미지 삭제
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // 주소 검색 (더미 데이터)
  void _searchAddress(String query) {
    if (query.isEmpty) {
      setState(() {
        _addressSuggestions = [];
        _isSearchingAddress = false;
      });
      return;
    }

    setState(() {
      _isSearchingAddress = true;
    });

    // TODO: 실제 주소 검색 API 연동
    // 현재는 더미 데이터
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _addressSuggestions =
            [
                  'Preston',
                  'Preston, VIC 3072',
                  'Preston South, VIC 3072',
                  'Preston West, VIC 3072',
                ]
                .where(
                  (addr) => addr.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
        _isSearchingAddress = false;
      });
    });
  }

  // 주소 선택
  void _selectAddress(int index) {
    setState(() {
      _selectedAddressIndex = index;
      _addressController.text = _addressSuggestions[index];
      _addressSuggestions = [];
    });
  }

  // 다음 단계로
  void _continueToNextStep() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 1개 이상의 이미지를 선택해주세요.')));
      return;
    }

    if (_selectedAddressIndex == -1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('주소를 선택해주세요.')));
      return;
    }

    // Step 2로 데이터 전달
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharehouseCreateStep2Page(
          images: _selectedImages,
          title: _titleController.text,
          description: _descriptionController.text,
          address: _addressController.text,
          detailedAddress: _detailedAddressController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GradientLayout(
        child: Column(
          children: [
            CustomHeader(
              center: const Text(
                'Create Listing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
              showBack: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이미지 섹션
                      _buildImageSection(),
                      const SizedBox(height: 24),

                      // 제목
                      CommonTextField(
                        label: 'Title',
                        controller: _titleController,
                        hintText: 'e.g. Bright room near tram, quiet house',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // 짧은 설명
                      CommonTextField(
                        label: 'Short Description',
                        controller: _descriptionController,
                        hintText: 'e.g. Bright room near tram, quiet house',
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                        bottomPadding: 0,
                      ),

                      // 주소 검색
                      _buildAddressSearch(),

                      // 상세 주소
                      CommonTextField(
                        label: '',
                        controller: _detailedAddressController,
                        hintText: 'Exact address will not be shown publicly',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // 다음 버튼
                      _buildContinueButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: dark,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 이미지 추가 버튼
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 100,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: grey01, width: 1.2),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera, color: grey02, size: 32),
                      SizedBox(height: 6),
                      Text(
                        'Minimum 3',
                        style: TextStyle(
                          fontSize: 12,
                          color: grey02,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 선택된 이미지들
              ..._selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonTextField(
          label: '',
          bottomPadding: 0,
          controller: _addressController,
          onChanged: _searchAddress, // 입력 시 검색
          prefixIcon: SvgPicture.asset(
            'assets/icons/pin.svg',
            width: 25,
            height: 25,
          ),
          suffixIcon: SvgPicture.asset(
            'assets/icons/search-color.svg',
            width: 28,
            height: 28,
          ),
          hintText: 'e.g. Preston',
          validator: (value) {
            if (_selectedAddressIndex == -1) {
              return 'Please select an address';
            }
            return null;
          },
        ),

        // 주소 검색 결과 더미 리스트
        if (_addressSuggestions.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: grey01, width: 1.2), // 아웃라인 보더 추가
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addressSuggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final address = _addressSuggestions[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ), // 아이템 간격 넓히기
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: SvgPicture.asset(
                      'assets/icons/pin.svg',
                      width: 22,
                      height: 22,
                      color: green,
                    ),
                  ),
                  title: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => _selectAddress(index),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return PrimaryButton(
      formKey: GlobalKey<FormState>(), // 폼 검증 필요 없으면 새 key 사용
      text: 'Continue to Details',
      onAction: () async {
        _continueToNextStep();
        return true; // 성공 처리
      },
      successMessage: '',
      failMessage: '',
      enabled: true,
    );
  }
}
