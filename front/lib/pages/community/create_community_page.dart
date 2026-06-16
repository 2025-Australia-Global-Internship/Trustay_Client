import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:front/constants/colors.dart';
import 'package:front/models/community_model.dart';
import 'package:front/services/community_service.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/widgets/primary_button.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  static const int _nameMaxLength = 24;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _categoriesExpanded = false;
  CommunityCategory? _selectedCategory;
  File? _coverImage;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _coverImage != null &&
      !_isSubmitting;

  Future<void> _pickCoverImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
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
      String? imageUrl;
      if (_coverImage != null) {
        final urls = await SharehouseService.uploadImages([_coverImage!]);
        if (urls.isNotEmpty) imageUrl = urls.first;
      }

      final created = await CommunityService.createCommunity(
        name: name,
        description: desc.isEmpty ? null : desc,
        category: _selectedCategory,
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      await _showSuccessSheet();
      if (!mounted) return;
      Navigator.of(context).pop<CommunityModel>(created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
      barrierColor: Colors.black.withValues(alpha: 0.35),
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
                Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEFF3DC),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: green.withValues(alpha: 0.25),
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
                    fontSize: 14,
                    color: grey02,
                    fontWeight: FontWeight.w600,
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
              showBack: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What kind of community?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 35),
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
                                ? Colors.redAccent.withValues(alpha: 0.85)
                                : grey03,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildNameField(),
                      const SizedBox(height: 14),
                      _buildSectionLabel('Category'),
                      const SizedBox(height: 12),
                      _buildCategoryChips(),
                      const SizedBox(height: 14),
                      _buildDescriptionField(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: PrimaryButton(
                formKey: _formKey,
                text: 'Create',
                isLoading: _isSubmitting,
                onAction: () async {
                  await _submit();
                  return false;
                },
                successMessage: '',
                failMessage: '',
                enabled: _canSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                : SvgPicture.asset(
                    'assets/icons/camera.svg',
                    color: Color(0xFFB7B7B7),
                    width: 35,
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: dark,
      ),
    );
  }

  Widget _buildNameField() {
    final length = _nameController.text.characters.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CommonTextField(
          label: 'Community Name',
          controller: _nameController,
          hintText: 'Sunday Jogging',
          inputFormatters: [LengthLimitingTextInputFormatter(_nameMaxLength)],
          bottomPadding: 0,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            '$length/$_nameMaxLength',
            style: const TextStyle(
              fontSize: 11,
              color: grey02,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    const collapsedCount = 2;
    final all = CommunityCategory.values
        .where((c) => c != CommunityCategory.other)
        .toList(growable: false);
    final visible = _categoriesExpanded
        ? all
        : all.take(collapsedCount).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [...visible.map(_buildCategoryChip), _buildExpandToggleChip()],
    );
  }

  Widget _buildCategoryChip(CommunityCategory cat) {
    final selected = _selectedCategory == cat;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = selected ? null : cat;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 19),
        decoration: BoxDecoration(
          color: selected ? green : Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // 💡 [수정] Center 대신 Row와 mainAxisSize.min을 조합하여 정렬합니다.
        child: Row(
          mainAxisSize: MainAxisSize.min, // 👈 중요: 글자 너비만큼만 칩 크기를 조절해 줍니다.
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cat.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : dark,
              ),
            ),
          ],
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
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 19),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
    return CommonTextField(
      label: 'Community Description',
      controller: _descController,
      hintText: 'What is this community about?',
      maxLines: 6,
      bottomPadding: 0,
    );
  }
}
