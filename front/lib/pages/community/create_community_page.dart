import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:front/constants/colors.dart';
import 'package:front/models/community_model.dart';
import 'package:front/services/community_service.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';

/// "Create Community" 화면.
///
/// 디자인:
/// - 상단: 노란 그라데이션 배경 + 뒤로가기 + 타이틀 ("Create Community")
/// - 헤딩: "What kind of community?"
/// - 입력1: Community Name (24자 카운터)
/// - 입력2: Category (칩 형태, 기본 2개 + Expand/Collapse)
/// - 입력3: Community Description (멀티라인)
/// - 하단: 노란 둥근 Create 버튼
/// - 생성 성공 시 BottomSheet 로 "Congratulations!" 안내 후 Done 누르면
///   생성된 [CommunityModel] 을 result 로 pop.
class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  static const int _nameMaxLength = 24;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  /// 칩 영역 펼침 여부. 펼치면 모든 카테고리가 보이고, 접으면 처음 두 개만 보인다.
  bool _categoriesExpanded = false;
  CommunityCategory? _selectedCategory;

  /// 사용자가 선택한 커뮤니티 대표 이미지(옵션).
  File? _coverImage;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 글자 수 카운터를 갱신하기 위해 listen.
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// 이름이 비어 있지 않고, 커버 이미지가 선택되어 있어야 생성 가능.
  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _coverImage != null &&
      !_isSubmitting;

  Future<void> _pickCoverImage() async {
    try {
      final picked =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;
      setState(() => _coverImage = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    setState(() => _isSubmitting = true);
    try {
      // 1) 이미지가 있으면 먼저 업로드해서 URL 을 확보한다.
      String? imageUrl;
      if (_coverImage != null) {
        final urls = await SharehouseService.uploadImages([_coverImage!]);
        if (urls.isNotEmpty) imageUrl = urls.first;
      }

      // 2) 커뮤니티 생성.
      final created = await CommunityService.createCommunity(
        name: name,
        description: desc.isEmpty ? null : desc,
        category: _selectedCategory,
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      // 성공 시 바텀시트 안내 → Done 누르면 생성된 커뮤니티를 result 로 pop.
      await _showSuccessSheet();
      if (!mounted) return;
      Navigator.of(context).pop<CommunityModel>(created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showSuccessSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withOpacity(0.35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 큰 후광 + 체크 아이콘
                Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEFF3DC),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: green.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Community has been created\nsuccessfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: grey03,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                      foregroundColor: dark,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      body: GradientLayout(
        child: Column(
          children: [
            const CustomHeader(
              center: Text(
                'Create Community',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
              showBack: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const Text(
                      'What kind of community?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: dark,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(child: _buildCoverPicker()),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        _coverImage == null
                            ? 'Add a cover image (required)'
                            : 'Tap to change cover',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _coverImage == null
                              ? Colors.redAccent.withOpacity(0.85)
                              : grey03,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildSectionLabel('Community Name'),
                    const SizedBox(height: 8),
                    _buildNameField(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Category'),
                    const SizedBox(height: 12),
                    _buildCategoryChips(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Community Description'),
                    const SizedBox(height: 8),
                    _buildDescriptionField(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomCreateButton(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cover image picker
  // ---------------------------------------------------------------------------
  Widget _buildCoverPicker() {
    final hasImage = _coverImage != null;
    return GestureDetector(
      onTap: _pickCoverImage,
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8E8E8),
              image: hasImage
                  ? DecorationImage(
                      image: FileImage(_coverImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: hasImage
                ? null
                : const Icon(
                    Icons.photo_camera_rounded,
                    color: Color(0xFFB7B7B7),
                    size: 30,
                  ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 섹션 빌더
  // ---------------------------------------------------------------------------
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: dark,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    final length = _nameController.text.characters.length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _nameController,
            maxLength: _nameMaxLength,
            // maxLength 카운터를 따로 그려서 기본 표시는 숨김.
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) =>
                null,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Sunday Jogging',
              hintStyle: TextStyle(
                color: Color(0xFFD0D0D0),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: dark,
            ),
          ),
          Text(
            '$length/$_nameMaxLength',
            style: const TextStyle(
              fontSize: 11,
              color: grey02,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    // 항상 보이는 처음 두 개 + 펼쳤을 때만 보이는 나머지.
    const collapsedCount = 2;
    final all = CommunityCategory.values
        .where((c) => c != CommunityCategory.other)
        .toList(growable: false);
    final visible =
        _categoriesExpanded ? all : all.take(collapsedCount).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        ...visible.map(_buildCategoryChip),
        _buildExpandToggleChip(),
      ],
    );
  }

  Widget _buildCategoryChip(CommunityCategory cat) {
    final selected = _selectedCategory == cat;
    return GestureDetector(
      onTap: () {
        setState(() {
          // 같은 칩을 다시 누르면 선택 해제.
          _selectedCategory = selected ? null : cat;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? darkgreen : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? darkgreen : const Color(0xFFE3E3E3),
            width: 1,
          ),
        ),
        child: Text(
          cat.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : dark,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandToggleChip() {
    return GestureDetector(
      onTap: () {
        setState(() => _categoriesExpanded = !_categoriesExpanded);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE3E3E3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _categoriesExpanded ? 'Collapse' : 'Expand',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _categoriesExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: dark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: TextField(
        controller: _descController,
        minLines: 4,
        maxLines: 8,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'What is this community about?',
          hintStyle: TextStyle(
            color: Color(0xFFD0D0D0),
            fontWeight: FontWeight.w500,
          ),
        ),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: dark,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildBottomCreateButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _canSubmit ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: yellow,
              disabledBackgroundColor: const Color(0xFFFFF6CB),
              foregroundColor: dark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: dark,
                    ),
                  )
                : const Text(
                    'Create',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
