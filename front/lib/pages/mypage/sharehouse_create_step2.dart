import 'dart:io';
import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/models/sharehouse_create_model.dart';
import 'package:front/services/sharehouse_service.dart';

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
  // Property Type
  String _selectedPropertyType = 'HOUSE';
  final List<String> _propertyTypes = [
    'House',
    'Apartment',
    'Unit',
    'Townhouse',
  ];

  // Bills Included
  String _selectedBillsIncluded = 'YES';

  // Room Type
  String _selectedRoomType = 'PRIVATE_ROOM';

  // Entire Place
  bool _isEntirePlace = false;

  // Rent
  final TextEditingController _rentController = TextEditingController();
  String _rentPeriod = 'week';

  // Bond
  int _bondWeeks = 2;
  final List<int> _bondOptions = [2, 4];
  int? _customBondWeeks;
  final TextEditingController _customBondController = TextEditingController();

  // Minimum Stay
  String _minimumStay = 'No minimum stay';
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
    'Desk': 'DESK',
    'Chair': 'CHAIR',
    'Lamp': 'LAMP',
    'Kitchenette': 'KITCHENETTE',
    'Guests allowed': 'GUESTS_ALLOWED',
    'Couch': 'COUCH',
    'Desk lock': 'DESK_LOCK',
  };

  // Gender
  String _selectedGender = 'ANY';

  bool _isSubmitting = false;

  @override
  void dispose() {
    _rentController.dispose();
    _customBondController.dispose();
    _customStayController.dispose();
    super.dispose();
  }

  Future<void> _submitListing() async {
    // Validation
    if (_rentController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('임대료를 입력해주세요.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. 이미지 업로드
      final imageUrls = await SharehouseService.uploadImages(widget.images);

      // 2. 매물 등록
      final request = SharehouseCreateRequest(
        title: widget.title,
        shortDescription: widget.description,
        address: widget.address,
        detailedAddress: widget.detailedAddress,
        propertyType: _selectedPropertyType,
        billsIncluded: _selectedBillsIncluded,
        roomType: _selectedRoomType,
        isEntirePlace: _isEntirePlace,
        rentPerWeek: int.parse(_rentController.text),
        bond: _customBondWeeks ?? _bondWeeks,
        minimumStay: _customMinimumStay ?? 0,
        homeRules: _selectedHomeRules.toList(),
        features: _selectedFeatures.toList(),
        imageUrls: imageUrls,
        gender: _selectedGender,
      );

      final success = await SharehouseService.createSharehouse(request);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('매물이 등록되었습니다!')));
        // 리스팅 페이지로 돌아가기
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('등록 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GradientLayout(
        child: Stack(
          children: [
            Column(
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
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property Type
                        _buildPropertyType(),
                        const SizedBox(height: 24),

                        // Bills Included
                        _buildBillsIncluded(),
                        const SizedBox(height: 24),

                        // Room Type
                        _buildRoomType(),
                        const SizedBox(height: 24),

                        // Entire Place
                        _buildEntirePlace(),
                        const SizedBox(height: 24),

                        // Rent
                        _buildRent(),
                        const SizedBox(height: 24),

                        // Bond
                        _buildBond(),
                        const SizedBox(height: 24),

                        // Minimum Stay
                        _buildMinimumStay(),
                        const SizedBox(height: 24),

                        // Home Rules
                        _buildHomeRules(),
                        const SizedBox(height: 24),

                        // Features
                        _buildFeatures(),
                        const SizedBox(height: 24),

                        // Gender
                        _buildGender(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Submit Button
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Create',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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

  Widget _buildPropertyType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Property Type'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
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

  Widget _buildBillsIncluded() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bills Included'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildChoiceChip(
              label: 'Yes',
              selected: _selectedBillsIncluded == 'YES',
              onSelected: () {
                setState(() {
                  _selectedBillsIncluded = 'YES';
                });
              },
            ),
            _buildChoiceChip(
              label: 'No',
              selected: _selectedBillsIncluded == 'NO',
              onSelected: () {
                setState(() {
                  _selectedBillsIncluded = 'NO';
                });
              },
            ),
            _buildChoiceChip(
              label: 'Partially',
              selected: _selectedBillsIncluded == 'PARTIALLY',
              onSelected: () {
                setState(() {
                  _selectedBillsIncluded = 'PARTIALLY';
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Room Type'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildChoiceChip(
              label: 'Private room',
              selected: _selectedRoomType == 'PRIVATE_ROOM',
              onSelected: () {
                setState(() {
                  _selectedRoomType = 'PRIVATE_ROOM';
                });
              },
            ),
            _buildChoiceChip(
              label: 'Shared room',
              selected: _selectedRoomType == 'SHARED_ROOM',
              onSelected: () {
                setState(() {
                  _selectedRoomType = 'SHARED_ROOM';
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEntirePlace() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Entire place',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: dark,
            ),
          ),
        ),
        Switch(
          value: _isEntirePlace,
          onChanged: (value) {
            setState(() {
              _isEntirePlace = value;
            });
          },
          activeColor: green,
        ),
      ],
    );
  }

  Widget _buildRent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Rent'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  hintText: '0',
                  filled: true,
                  fillColor: grey01,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: grey01,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Text('week', style: TextStyle(fontSize: 14, color: dark)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: dark),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBond() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bond'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
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
              label: 'Custom',
              selected: _customBondWeeks != null,
              onSelected: () {
                _showCustomBondDialog();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimumStay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Minimum Stay'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
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
              label: 'Custom',
              selected: _customMinimumStay != null,
              onSelected: () {
                _showCustomStayDialog();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHomeRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Home Rules'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _homeRulesMap.entries.map((entry) {
            final isSelected = _selectedHomeRules.contains(entry.value);
            return _buildChoiceChip(
              label: entry.key,
              selected: isSelected,
              onSelected: () {
                setState(() {
                  if (isSelected) {
                    _selectedHomeRules.remove(entry.value);
                  } else {
                    _selectedHomeRules.add(entry.value);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Features'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _featuresMap.entries.map((entry) {
            final isSelected = _selectedFeatures.contains(entry.value);
            return _buildChoiceChip(
              label: entry.key,
              selected: isSelected,
              onSelected: () {
                setState(() {
                  if (isSelected) {
                    _selectedFeatures.remove(entry.value);
                  } else {
                    _selectedFeatures.add(entry.value);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGender() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wc, color: grey02, size: 20),
            const SizedBox(width: 8),
            _buildSectionTitle('Gender'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildChoiceChip(
              label: 'Male',
              selected: _selectedGender == 'MALE',
              onSelected: () {
                setState(() {
                  _selectedGender = 'MALE';
                });
              },
            ),
            _buildChoiceChip(
              label: 'Female',
              selected: _selectedGender == 'FEMALE',
              onSelected: () {
                setState(() {
                  _selectedGender = 'FEMALE';
                });
              },
            ),
            _buildChoiceChip(
              label: 'Any',
              selected: _selectedGender == 'ANY',
              onSelected: () {
                setState(() {
                  _selectedGender = 'ANY';
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? green : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? green : grey01, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : dark,
          ),
        ),
      ),
    );
  }

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
