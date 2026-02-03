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

  // Property Type
  String? _selectedPropertyType;
  final List<String> _propertyTypes = [
    'House',
    'Apartment',
    'Unit',
    'Townhouse',
  ];

  // Bills Included
  String? _selectedBillsIncluded;

  // Room Type
  String? _selectedRoomType;

  // Rent
  final TextEditingController _rentController = TextEditingController();

  // Bond
  int _bondWeeks = 2;
  final List<int> _bondOptions = [2, 4];
  int? _customBondWeeks;
  final TextEditingController _customBondController = TextEditingController();

  // Minimum Stay
  String? _minimumStay;
  int? _customMinimumStay;
  final TextEditingController _customStayController = TextEditingController();

  // Home Rules
  final Set<String> _selectedHomeRules = {};
  final Map<String, String> _homeRulesMap = {
    'No smoking': 'NO_SMOKING',
    'No parties': 'NO_PARTIES',
    'Pets allowed': 'PETS_ALLOWED',
    'Guests allowed': 'GUESTS_ALLOWED',
  };

  // Features
  final Set<String> _selectedFeatures = {};
  final Map<String, String> _featuresMap = {
    'Double bed': 'DOUBLE_BED',
    'Queen bed': 'QUEEN_BED',
    'Bed side table': 'BED_SIDE_TABLE',
    'Wardrobe': 'WARDROBE',
    'Door lock': 'DOOR_LOCK',
    'Couch': 'COUCH',
    'Chair': 'CHAIR',
    'Desk': 'DESK',
    'Lamp': 'LAMP',
    'Kitchenette': 'KITCHENETTE',
    'Mirror': 'MIRROR',
    'Fan': 'FAN',
    'Air Conditioner': 'AIR_CONDITIONER',
    'Heater': 'HEATER',
    'Washing Machine': 'WASHING_MACHINE',
    'Iron': 'IRON',
    'Dining Table': 'DINING_TABLE',
    'Dining Chairs': 'DINING_CHAIRS',
    'Oven': 'OVEN',
    'Microwave': 'MICROWAVE',
    'Refrigerator': 'REFRIGERATOR',
    'Stove': 'STOVE',
    'Dishwasher': 'DISHWASHER',
    'Kettle': 'KETTLE',
    'Toaster': 'TOASTER',
    'Coffee Maker': 'COFFEE_MAKER',
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
    _customStayController.dispose();
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
    if (_rentController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('임대료를 입력해주세요.')));
      }
      return false;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 이미지 업로드
      final imageUrls = await SharehouseService.uploadImages(widget.images);

      // 2. rentPrice 파싱
      final int rentPrice = int.parse(_rentController.text);

      // 3. options 리스트 구성: homeRules + features 합침
      final List<String> options = [
        ..._selectedHomeRules,
        ..._selectedFeatures,
      ];

      // 4. Request 생성
      final request = SharehouseCreateRequest(
        title: widget.title,
        description: widget.description,
        address: widget.address,
        houseType: (_selectedPropertyType ?? '').toUpperCase(),
        rentPrice: rentPrice,
        roomCount: _roomCount,
        bathroomCount: _bathroomCount,
        currentResidents: _currentResidents,
        options: options,
        imageUrls: imageUrls,
      );

      // 5. API 호출
      final success = await SharehouseService.createSharehouse(request);

      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('매물이 등록되었습니다!')));
        Navigator.of(context).popUntil((route) => route.isFirst);
        return true;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('등록 실패: 알 수 없는 오류')));
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('등록 실패: $e')));
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                'Add Property',
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

                      _buildBond(),
                      const SizedBox(height: 26),

                      _buildMinimumStay(),
                      const SizedBox(height: 26),

                      _buildHomeRules(),
                      const SizedBox(height: 26),

                      _buildFeatures(),
                      const SizedBox(height: 26),

                      // Bedroom / Bathroom / Resident 카운터
                      _buildCounters(),
                      const SizedBox(height: 26),

                      _buildGender(),
                      const SizedBox(height: 42),

                      PrimaryButton(
                        formKey: _formKey,
                        text: 'Publish',
                        isLoading: _isLoading,
                        onAction: _submitListing,
                        successMessage: '매물이 등록되었습니다!',
                        failMessage: '등록 실패',
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
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: dark,
      ),
    );
  }

  // ─── Property Type ───────────────────────────────────────────
  Widget _buildPropertyType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Property Type'),
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
        _buildSectionTitle('Bills Included'),
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
        _buildSectionTitle('Room Type'),
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
              selected: _selectedRoomType == 'SHARED_ROOM',
              onSelected: () =>
                  setState(() => _selectedRoomType = 'SHARED_ROOM'),
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
    return CommonTextField(
      label: 'Rent',
      controller: _rentController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      prefixIcon: SvgPicture.asset(
        'assets/icons/dollar.svg',
        width: 16,
        height: 16,
        color: dark,
      ),
      suffixText: 'week',
      hintText: '0',
      bottomPadding: 0,
    );
  }

  // ─── Bond ────────────────────────────────────────────────────
  Widget _buildBond() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bond'),
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
              selected: _customBondWeeks != null,
              onSelected: _showCustomBondDialog,
            ),
          ],
        ),
      ],
    );
  }

  // ─── Minimum Stay ────────────────────────────────────────────
  Widget _buildMinimumStay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Minimum Stay'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            _buildChoiceChip(
              label: 'No minimum stay',
              selected:
                  _minimumStay == 'No minimum stay' &&
                  _customMinimumStay == null,
              onSelected: () {
                setState(() {
                  _minimumStay = 'No minimum stay';
                  _customMinimumStay = null;
                  _customStayController.clear();
                });
              },
            ),
            _buildChoiceChip(
              label: _customMinimumStay != null
                  ? '${_customMinimumStay} weeks'
                  : 'Custom',
              selected: _customMinimumStay != null,
              onSelected: _showCustomStayDialog,
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
        _buildCounterRow(
          icon: SvgPicture.asset(
            'assets/icons/bed.svg',
            width: 22,
            height: 22,
            color: dark,
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
            width: 18,
            height: 18,
            color: dark,
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
            color: dark,
          ),
          label: 'Resident',
          value: _currentResidents,
          onIncrement: () => _increment(2),
          onDecrement: () => _decrement(2),
        ),
      ],
    );
  }

  // ─── CounterRow ───────────────────────────────────────────
  Widget _buildCounterRow({
    required Widget icon,
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: grey01, width: 1.2),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          icon,
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
          // - button
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: green, width: 1.2),
              ),
              child: const Icon(Icons.remove, color: green, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 24,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: dark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // + button
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: green, width: 1.2),
              ),
              child: const Icon(Icons.add, color: green, size: 20),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ─── Gender ──────────────────────────────────────────────────
  Widget _buildGender() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Gender'),
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
              label: 'Any',
              selected: _selectedGender == 'ANY',
              onSelected: () => setState(() => _selectedGender = 'ANY'),
            ),
          ],
        ),
      ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? green : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? green : grey01, width: 1.2),
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

  // ─── Custom Bond Dialog ──────────────────────────────────────
  void _showCustomBondDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Bond'),
        content: TextField(
          controller: _customBondController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Weeks',
            hintText: 'Enter number of weeks',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_customBondController.text.isNotEmpty) {
                setState(() {
                  _customBondWeeks = int.tryParse(_customBondController.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─── Custom Minimum Stay Dialog ──────────────────────────────
  void _showCustomStayDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Minimum Stay'),
        content: TextField(
          controller: _customStayController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Weeks',
            hintText: 'Enter number of weeks',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_customStayController.text.isNotEmpty) {
                setState(() {
                  _customMinimumStay = int.tryParse(_customStayController.text);
                  _minimumStay = 'Custom';
                });
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
