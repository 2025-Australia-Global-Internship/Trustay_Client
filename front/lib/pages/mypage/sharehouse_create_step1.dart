import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'sharehouse_create_step2.dart';
import 'package:front/widgets/primary_button.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SharehouseCreateStep1Page extends StatefulWidget {
  const SharehouseCreateStep1Page({super.key});

  @override
  State<SharehouseCreateStep1Page> createState() =>
      _SharehouseCreateStep1PageState();
}

class _SharehouseCreateStep1PageState extends State<SharehouseCreateStep1Page> {
  Timer? _debounce;

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

  // 주소 검색
  Future<void> _searchAddress(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _addressSuggestions = [];
        _selectedAddressIndex = -1;
      });
      return;
    }

    if (_isSearchingAddress) return;

    setState(() {
      _isSearchingAddress = true;
    });

    try {
      final apiKey = dotenv.env['GEOAPIFY_API_KEY'];

      final url = Uri.https('api.geoapify.com', '/v1/geocode/autocomplete', {
        'text': query,
        'filter': 'countrycode:au',
        'limit': '5',
        'format': 'json',
        'apiKey': apiKey,
      });

      final response = await http.get(url);

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final results = data['results'] as List;

        setState(() {
          _addressSuggestions = results.map((item) {
            return item['formatted'] as String;
          }).toList();

          _isSearchingAddress = false;
        });
      } else {
        setState(() {
          _isSearchingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('Geoapify error: $e');

      setState(() {
        _isSearchingAddress = false;
      });
    }
  }

  // 주소 선택
  void _selectAddress(int index) {
    setState(() {
      // 선택 시 인덱스를 고정하여 validator 통과
      _selectedAddressIndex = index;
      _addressController.text = _addressSuggestions[index];
      _addressSuggestions = []; // 리스트 닫기
    });
  }

  // 다음 단계로 — 검증 포함, bool 반환
  Future<bool> _continueToNextStep() async {
    // 폼 내 validator (title, description, detailedAddress 등)
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // 폼 validator 밖의 추가 검증
    if (_selectedImages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must select at least one image.")),
        );
      }
      return false;
    }

    if (_selectedAddressIndex == -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must select an address.")),
        );
      }
      return false;
    }

    // 검증 통과 → Step2로 이동
    if (mounted) {
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

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: GradientLayout(
        child: Column(
          children: [
            CustomHeader(
              center: const Text(
                'Create Listing',
                style: TextStyle(
                  fontSize: 18,
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // 설명
                      CommonTextField(
                        label: 'Short Description',
                        controller: _descriptionController,
                        hintText: 'e.g. Bright room near tram, quiet house',
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                        bottomPadding: 0,
                      ),

                      const SizedBox(height: 12),

                      // 주소 검색
                      _buildAddressSearch(),
                      Padding(
                        padding: EdgeInsets.fromLTRB(8, 10, 16, 0),
                        child: Text(
                          'Exact address will not be shown publicly',
                          style: TextStyle(
                            color: grey02,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 다음 버튼 — _formKey를 그대로 전달, onAction에서 검증 수행
                      PrimaryButton(
                        formKey: _formKey,
                        text: 'save',
                        onAction: _continueToNextStep,
                        successMessage: '',
                        failMessage: '',
                        enabled: true,
                      ),
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
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera, color: grey02, size: 32),
                      SizedBox(height: 6),
                      Text(
                        'Photos',
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
                          borderRadius: BorderRadius.circular(16),
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
          onChanged: (value) {
            if (_debounce?.isActive ?? false) {
              _debounce!.cancel();
            }

            _debounce = Timer(const Duration(milliseconds: 700), () {
              _searchAddress(value);
            });
          },
          prefixIcon: SvgPicture.asset(
            'assets/icons/pin.svg',
            width: 24,
            height: 24,
          ),
          suffixIcon: SvgPicture.asset(
            'assets/icons/search.svg',
            width: 22,
            height: 22,
            color: grey04,
          ),
          hintText: 'e.g. Preston',
          validator: (value) {
            if (_selectedAddressIndex == -1) {
              return 'Please select an address';
            }
            return null;
          },
        ),

        // 주소 검색 결과 리스트
        if (_addressSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12), // 입력창과 약간의 간격
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _addressSuggestions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFFAFAFA)),
                itemBuilder: (context, index) {
                  final address = _addressSuggestions[index];
                  return ListTile(
                    dense: true,
                    horizontalTitleGap: -6,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: SvgPicture.asset(
                      'assets/icons/pin.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        green,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: Text(
                      _addressSuggestions[index],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectAddress(index),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
