import 'dart:io';
import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/widgets/primary_button.dart';
import 'package:front/models/sharehouse_create_model.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/routes/navigation_type.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:front/pages/mypage/post_pending_approval.dart';

class SharehouseCreateStep2Page extends StatefulWidget {
  final List<File> images;
  final String title;
  final String description;
  final String address;
  final String detailedAddress;

  const SharehouseCreateStep2Page({
    super.key,
    required this.images,
    required this.title,
    required this.description,
    required this.address,
    required this.detailedAddress,
  });

  @override
  State<SharehouseCreateStep2Page> createState() =>
      _SharehouseCreateStep2PageState();
}

class _SharehouseCreateStep2PageState extends State<SharehouseCreateStep2Page> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Property Type — API enum: HOUSE, APARTMENT, UNIT, TOWNHOUSE
  String? _selectedPropertyType;
  final List<String> _propertyTypes = [
    'House',
    'Apartment',
    'Unit',
    'Townhouse',
  ];

  // Bills Included
  String? _selectedBillsIncluded;

  // Room Type — API enum: SHAREDROOM, PRIVATE_ROOM, ENTIRE_PLACE
  String? _selectedRoomType;

  // Rent
  final TextEditingController _rentController = TextEditingController();

  // Religion & Dietary Preference
  final TextEditingController _religionController = TextEditingController();
  final TextEditingController _dietaryController = TextEditingController();

  // Bond
  int? _bondWeeks;
  final List<int> _bondOptions = [2, 4];
  int? _customBondWeeks;
  final TextEditingController _customBondController = TextEditingController();

  // ─── Minimum Stay (minimumStay: int, 주 단위) ─────────────────
  // _minimumStayLabel: UI 상태 추적용 ('No minimum stay' | 'Custom')
  // _minimumStayWeeks: 실제 API에 보낼 값 (주 단위 정수, 0 = 제한없음)
  String? _minimumStayLabel;
  int _minimumStayWeeks = 0;
  final TextEditingController _minimumStayController = TextEditingController();

  // ─── Age (age: string) ────────────────────────────────────────
  // _ageLabel: UI 상태 추적용 ('No age rejection' | 'Specify minimum age')
  // _ageValue: 실제 API에 보낼 값
  String _ageLabel = 'No age rejection';
  String _ageValue = 'No age rejection'; // API age 필드 값
  int? _customAgeInput;
  final TextEditingController _customAgeController = TextEditingController();

  // Home Rules
  final Set<String> _selectedHomeRules = {};
  final Map<String, String> _homeRulesMap = {
    'No smoking': 'No smoking',
    'No parties': 'No parties',
    'Pets allowed': 'Pets allowed',
    'Guests allowed': 'Guests allowed',
  };

  // Features
  final Set<String> _selectedFeatures = {};
  final Map<String, String> _featuresMap = {
    'Double bed': 'Double bed',
    'Queen bed': 'Queen bed',
    'Bed side table': 'Bed side table',
    'Wardrobe': 'Wardrobe',
    'Door lock': 'Door lock',
    'Couch': 'Couch',
    'Chair': 'Chair',
    'Desk': 'Desk',
    'Lamp': 'Lamp',
    'Kitchenette': 'Kitchenette',
    'Mirror': 'Mirror',
    'Fan': 'Fan',
    'Air Conditioner': 'Air Conditioner',
    'Heater': 'Heater',
    'Washing Machine': 'Washing Machine',
    'Iron': 'Iron',
    'Dining Table': 'Dining Table',
    'Dining Chairs': 'Dining Chairs',
    'Oven': 'Oven',
    'Microwave': 'Microwave',
    'Refrigerator': 'Refrigerator',
    'Stove': 'Stove',
    'Dishwasher': 'Dishwasher',
    'Kettle': 'Kettle',
    'Toaster': 'Toaster',
    'Coffee Maker': 'Coffee Maker',
  };

  // Bedroom / Bathroom / Resident 카운터
  int _roomCount = 0;
  int _bathroomCount = 0;
  int _currentResidents = 0;

  // Gender
  String? _selectedGender;

  bool _isLoading = false;

  @override
  void dispose() {
    _rentController.dispose();
    _customBondController.dispose();
    _minimumStayController.dispose();
    _customAgeController.dispose();
    _religionController.dispose();
    _dietaryController.dispose();
    super.dispose();
  }

  // ─── 카운터 공통 증감 ─────────────────────────────────────────
  void _increment(int type) {
    setState(() {
      switch (type) {
        case 0:
          _roomCount++;
          break;
        case 1:
          _bathroomCount++;
          break;
        case 2:
          _currentResidents++;
          break;
      }
    });
  }

  void _decrement(int type) {
    setState(() {
      switch (type) {
        case 0:
          if (_roomCount > 0) _roomCount--;
          break;
        case 1:
          if (_bathroomCount > 0) _bathroomCount--;
          break;
        case 2:
          if (_currentResidents > 0) _currentResidents--;
          break;
      }
    });
  }

  Future<bool> _submitListing() async {
    // 1. 필수값 검증
    if (_rentController.text.isEmpty || _selectedPropertyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return false;
    }

    setState(() => _isLoading = true);

    try {
      // 2. 이미지 서버 업로드 (URL 리스트 획득)
      final imageUrls = await SharehouseService.uploadImages(widget.images);

      // 3. address: 기본 주소 + 상세 주소 조합
      final fullAddress = widget.detailedAddress.trim().isEmpty
          ? widget.address
          : '${widget.address}, ${widget.detailedAddress}';

      // 4. Request 객체 생성
      final request = SharehouseCreateRequest(
        title: widget.title,
        description: widget.description,

        // [FIX] address: detailedAddress 포함하여 전송
        address: fullAddress,

        // [FIX] houseType: UI 선택값이 이미 대문자 enum 형태로 저장됨 (e.g. 'APARTMENT')
        houseType: _selectedPropertyType!,

        rentPrice: int.parse(_rentController.text),
        roomCount: _roomCount,
        bathroomCount: _bathroomCount,
        currentResidents: _currentResidents,
        homeRules: _selectedHomeRules.toList(),
        features: _selectedFeatures.toList(),
        imageUrls: imageUrls,
        billsIncluded: _selectedBillsIncluded == 'YES',

        // [FIX] roomType: 기본값을 API 스펙 기준 'SHAREDROOM'으로 통일
        roomType: _selectedRoomType ?? 'SHAREDROOM',

        // [FIX] bondType: 선택된 주 수 전송 (미선택 시 0)
        bondType: _bondWeeks ?? _customBondWeeks ?? 0,

        // [FIX] minimumStay: 전용 변수(_minimumStayWeeks) 사용, 주 단위 정수
        minimumStay: _minimumStayWeeks,

        // [FIX] gender: 미선택 시 'ANY' 전송
        gender: _selectedGender ?? 'ANY',

        // [FIX] age: 전용 변수(_ageValue) 사용 — minimumStay와 완전히 분리
        age: _ageValue,

        religion: _religionController.text,
        dietaryPreference: _dietaryController.text,
      );

      // 5. API 호출
      final success = await SharehouseService.createSharehouse(request);
      debugPrint('API result: $success');
      return success;
    } catch (e, stackTrace) {
      debugPrint('submitListing Error: $e');
      debugPrint('StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                'Add Property',
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
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPropertyType(),
                      const SizedBox(height: 26),

                      _buildBillsIncluded(),
                      const SizedBox(height: 26),

                      _buildRoomType(),
                      const SizedBox(height: 26),

                      _buildRent(),
                      const SizedBox(height: 26),

                      _buildCounters(),
                      const SizedBox(height: 26),

                      _buildBond(),
                      const SizedBox(height: 26),

                      _buildMinimumStay(),
                      const SizedBox(height: 26),

                      _buildHomeRules(),
                      const SizedBox(height: 26),

                      _buildFeatures(),
                      const SizedBox(height: 26),

                      _buildGender(),
                      const SizedBox(height: 26),

                      _buildAge(),
                      const SizedBox(height: 26),

                      _buildReligion(),
                      const SizedBox(height: 26),

                      _buildDietaryPreference(),
                      const SizedBox(height: 42),

                      PrimaryButton(
                        formKey: _formKey,
                        text: 'Publish',
                        isLoading: _isLoading,
                        onAction: () async {
                          return await _submitListing();
                        },
                        successMessage: '매물이 등록되었습니다!',
                        failMessage: '등록 실패',
                        nextRoute: '/post_pending',
                        navigationType: NavigationType.clearStack,
                        enabled: true,
                      ),
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

  // ─── Section Title ───────────────────────────────────────────
  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: dark,
          ),
        ),
        if (isRequired)
          const Text(
            '*',
            style: TextStyle(
              color: green,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }

  // ─── Property Type ───────────────────────────────────────────
  // [FIX] key를 toUpperCase()로 변환 → API enum과 일치 (e.g. 'APARTMENT')
  Widget _buildPropertyType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Property Type', isRequired: true),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: _propertyTypes.map((type) {
            final key = type.toUpperCase().replaceAll(' ', '_');
            final isSelected = _selectedPropertyType == key;
            return _buildChoiceChip(
              label: type,
              selected: isSelected,
              onSelected: () {
                setState(() {
                  _selectedPropertyType = key;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Bills Included ──────────────────────────────────────────
  Widget _buildBillsIncluded() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bills Included', isRequired: true),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            _buildChoiceChip(
              label: 'Yes',
              selected: _selectedBillsIncluded == 'YES',
              onSelected: () => setState(() => _selectedBillsIncluded = 'YES'),
            ),
            _buildChoiceChip(
              label: 'No',
              selected: _selectedBillsIncluded == 'NO',
              onSelected: () => setState(() => _selectedBillsIncluded = 'NO'),
            ),
            _buildChoiceChip(
              label: 'Partially',
              selected: _selectedBillsIncluded == 'PARTIALLY',
              onSelected: () =>
                  setState(() => _selectedBillsIncluded = 'PARTIALLY'),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Room Type ───────────────────────────────────────────────
  Widget _buildRoomType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Room Type', isRequired: true),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            _buildChoiceChip(
              label: 'Private room',
              selected: _selectedRoomType == 'PRIVATE_ROOM',
              onSelected: () =>
                  setState(() => _selectedRoomType = 'PRIVATE_ROOM'),
            ),
            _buildChoiceChip(
              label: 'Shared room',
              // [FIX] API 스펙 enum: SHAREDROOM (언더스코어 없음)
              selected: _selectedRoomType == 'SHAREDROOM',
              onSelected: () =>
                  setState(() => _selectedRoomType = 'SHAREDROOM'),
            ),
            _buildChoiceChip(
              label: 'Entire place',
              selected: _selectedRoomType == 'ENTIRE_PLACE',
              onSelected: () =>
                  setState(() => _selectedRoomType = 'ENTIRE_PLACE'),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Rent ────────────────────────────────────────────────────
  Widget _buildRent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Rent',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
              const TextSpan(
                text: '*',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CommonTextField(
          label: '',
          controller: _rentController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefixIcon: SvgPicture.asset(
            'assets/icons/dollar.svg',
            width: 16,
            height: 16,
            color: green,
          ),
          suffixText: 'week',
          hintText: '0',
          bottomPadding: 0,
        ),
      ],
    );
  }

  // ─── Bond ────────────────────────────────────────────────────
  Widget _buildBond() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bond', isRequired: true),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            ..._bondOptions.map((weeks) {
              final isSelected =
                  _bondWeeks == weeks && _customBondWeeks == null;
              return _buildChoiceChip(
                label: '$weeks weeks',
                selected: isSelected,
                onSelected: () {
                  setState(() {
                    _bondWeeks = weeks;
                    _customBondWeeks = null;
                    _customBondController.clear();
                  });
                },
              );
            }).toList(),
            _buildChoiceChip(
              label: _customBondWeeks != null
                  ? '${_customBondWeeks} weeks'
                  : 'Custom',
              selected: _bondWeeks == null && _customBondWeeks != null,
              onSelected: () {
                setState(() {
                  _bondWeeks = null;
                });
              },
            ),
            CommonTextField(
              label: '',
              controller: _customBondController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: SvgPicture.asset(
                'assets/icons/calendar.svg',
                width: 16,
                height: 16,
                color: green,
              ),
              prefixIconPadding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
              suffixText: 'week',
              hintText: '0',
              bottomPadding: 0,
              readOnly: false,
              onChanged: (value) {
                setState(() {
                  _customBondWeeks = int.tryParse(value);
                  if (_customBondWeeks != null) {
                    _bondWeeks = null;
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  // ─── Minimum Stay ─────────────────────────────────────────────
  // [FIX] minimumStay 전용 변수(_minimumStayLabel, _minimumStayWeeks, _minimumStayController) 사용
  //       Age와 완전히 분리됨
  Widget _buildMinimumStay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Minimum Stay', isRequired: true),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            _buildChoiceChip(
              label: 'No minimum stay',
              selected: _minimumStayLabel == 'No minimum stay',
              onSelected: () {
                setState(() {
                  _minimumStayLabel = 'No minimum stay';
                  _minimumStayWeeks = 0; // API에 0 전송
                  _minimumStayController.clear();
                });
              },
            ),
            _buildChoiceChip(
              label: 'Custom',
              selected: _minimumStayLabel == 'Custom',
              onSelected: () {
                setState(() {
                  _minimumStayLabel = 'Custom';
                });
              },
            ),
            CommonTextField(
              label: '',
              controller: _minimumStayController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: SvgPicture.asset(
                'assets/icons/home.svg',
                width: 18,
                height: 18,
                color: green,
              ),
              prefixIconPadding: const EdgeInsets.fromLTRB(20, 0, 11, 0),
              suffixText: 'week',
              hintText: '0',
              bottomPadding: 0,
              readOnly: _minimumStayLabel != 'Custom',
              onChanged: (value) {
                setState(() {
                  _minimumStayWeeks = int.tryParse(value) ?? 0;
                  if (_minimumStayWeeks > 0) _minimumStayLabel = 'Custom';
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  // ─── Home Rules ──────────────────────────────────────────────
  Widget _buildHomeRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Home Rules'),
        const SizedBox(height: 13),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 5,
            runSpacing: 16,
            children: _homeRulesMap.entries.map((entry) {
              final isSelected = _selectedHomeRules.contains(entry.value);
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 2,
                child: _buildCheckboxTile(
                  label: entry.key,
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedHomeRules.add(entry.value);
                      } else {
                        _selectedHomeRules.remove(entry.value);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Features ────────────────────────────────────────────────
  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Features'),
        const SizedBox(height: 13),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 5,
            runSpacing: 16,
            children: _featuresMap.entries.map((entry) {
              final isSelected = _selectedFeatures.contains(entry.value);
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 2,
                child: _buildCheckboxTile(
                  label: entry.key,
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedFeatures.add(entry.value);
                      } else {
                        _selectedFeatures.remove(entry.value);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Bedroom / Bathroom / Resident 카운터 ────────────────────
  Widget _buildCounters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Number of',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
              const TextSpan(
                text: '*',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCounterRow(
          icon: SvgPicture.asset(
            'assets/icons/bed.svg',
            width: 21,
            height: 21,
            colorFilter: const ColorFilter.mode(dark, BlendMode.srcIn),
          ),
          label: 'Bedroom',
          value: _roomCount,
          onIncrement: () => _increment(0),
          onDecrement: () => _decrement(0),
        ),
        const SizedBox(height: 12),
        _buildCounterRow(
          icon: SvgPicture.asset(
            'assets/icons/bathroom.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(dark, BlendMode.srcIn),
          ),
          label: 'Bathroom',
          value: _bathroomCount,
          onIncrement: () => _increment(1),
          onDecrement: () => _decrement(1),
        ),
        const SizedBox(height: 12),
        _buildCounterRow(
          icon: SvgPicture.asset(
            'assets/icons/profile.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(dark, BlendMode.srcIn),
          ),
          label: 'Resident',
          value: _currentResidents,
          onIncrement: () => _increment(2),
          onDecrement: () => _decrement(2),
        ),
      ],
    );
  }

  // ─── CounterRow ──────────────────────────────────────────────
  Widget _buildCounterRow({
    required Widget icon,
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          SizedBox(width: 24, child: Center(child: icon)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: dark,
            ),
          ),
          const Spacer(),
          _buildCounterBtn(
            icon: Icons.remove,
            onTap: onDecrement,
            isEnabled: value > 0,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 24,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildCounterBtn(
            icon: Icons.add,
            onTap: onIncrement,
            isEnabled: true,
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }

  Widget _buildCounterBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: green, width: 1.1),
        ),
        child: Icon(icon, color: green, size: 20),
      ),
    );
  }

  // ─── Gender ──────────────────────────────────────────────────
  Widget _buildGender() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Gender', isRequired: true),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            _buildChoiceChip(
              label: 'Male',
              selected: _selectedGender == 'MALE',
              onSelected: () => setState(() => _selectedGender = 'MALE'),
            ),
            _buildChoiceChip(
              label: 'Female',
              selected: _selectedGender == 'FEMALE',
              onSelected: () => setState(() => _selectedGender = 'FEMALE'),
            ),
            _buildChoiceChip(
              label: 'Non-binary',
              selected: _selectedGender == 'NON_BINARY',
              onSelected: () => setState(() => _selectedGender = 'NON_BINARY'),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Age ──────────────────────────────────────────────────────
  // [FIX] Age 전용 변수(_ageLabel, _ageValue, _customAgeInput, _customAgeController) 사용
  //       Minimum Stay 변수와 완전히 분리됨
  Widget _buildAge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Age', isRequired: true),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            _buildChoiceChip(
              label: 'No age rejection',
              selected: _ageLabel == 'No age rejection',
              onSelected: () {
                setState(() {
                  _ageLabel = 'No age rejection';
                  _ageValue = 'No age rejection'; // API age 필드 값
                  _customAgeInput = null;
                  _customAgeController.clear();
                });
              },
            ),
            _buildChoiceChip(
              label: 'Specify minimum age',
              selected: _ageLabel == 'Specify minimum age',
              onSelected: () {
                setState(() {
                  _ageLabel = 'Specify minimum age';
                });
              },
            ),
            CommonTextField(
              label: '',
              controller: _customAgeController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: SvgPicture.asset(
                'assets/icons/social.svg',
                width: 16,
                height: 16,
                color: green,
              ),
              prefixIconPadding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
              suffixText: 'Age',
              hintText: '0',
              bottomPadding: 0,
              readOnly: _ageLabel != 'Specify minimum age',
              onChanged: (value) {
                setState(() {
                  _customAgeInput = int.tryParse(value);
                  if (_customAgeInput != null) {
                    // API age 필드: 숫자를 문자열로 전송
                    _ageValue = value;
                    _ageLabel = 'Specify minimum age';
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  // ─── Religion ──────────────────────────────────────────────────
  Widget _buildReligion() {
    return CommonTextField(
      label: 'Religion',
      labelFontWeight: FontWeight.w800,
      controller: _religionController,
      labelFontSize: 15,
      bottomPadding: 0,
    );
  }

  // ─── Dietary Preference ─────────────────────────────────────────
  Widget _buildDietaryPreference() {
    return CommonTextField(
      label: 'Dietary Preference',
      labelFontWeight: FontWeight.w800,
      controller: _dietaryController,
      labelFontSize: 15,
      bottomPadding: 0,
    );
  }

  // ─── Reusable Checkbox Tile ──────────────────────────────────
  Widget _buildCheckboxTile({
    required String label,
    required bool value,
    required void Function(bool?) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: value ? green : grey01, width: 1.2),
              color: value ? green : Colors.transparent,
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
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

  // ─── Reusable Choice Chip ────────────────────────────────────
  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? green : Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : dark,
          ),
        ),
      ),
    );
  }
}
