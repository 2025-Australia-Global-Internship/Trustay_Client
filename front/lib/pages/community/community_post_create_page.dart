import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:front/constants/colors.dart';
import 'package:front/models/post_model.dart';
import 'package:front/services/post_service.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/widgets/primary_button.dart';

/// 커뮤니티 게시글 작성 페이지.
///
/// - 본문(필수) + 사진(선택, 최대 1장)
/// - 제목은 본문에서 자동 추출 (첫 30자)
/// - 작성 후 생성된 [PostModel] 을 result 로 pop.
class CommunityPostCreatePage extends StatefulWidget {
  final int communityId;

  const CommunityPostCreatePage({super.key, required this.communityId});

  @override
  State<CommunityPostCreatePage> createState() =>
      _CommunityPostCreatePageState();
}

class _CommunityPostCreatePageState extends State<CommunityPostCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _contentCtl = TextEditingController();

  /// 사진은 최대 1장만 첨부할 수 있다.
  /// 리스트 형태를 유지하는 이유: PostService.createPost / SharehouseService.uploadImages
  /// 시그니처가 `List<File>` 를 받기 때문에 호출 측 변경을 최소화하기 위함이다.
  final List<File> _selectedImages = [];
  static const int _maxImages = 1;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _contentCtl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contentCtl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _contentCtl.text.trim().isNotEmpty && !_submitting;

<<<<<<< HEAD
  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 $_maxImages개의 이미지만 선택할 수 있습니다.')),
      );
      return;
    }
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;
=======
  Future<void> _pickImage() async {
    if (_selectedImages.length >= _maxImages) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
>>>>>>> 4ccf48f752c93ecb555fba25a73efe6c3d56d1d9
    setState(() {
      _selectedImages
        ..clear()
        ..add(File(picked.path));
    });
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  /// 본문에서 제목 추출.
  /// - 첫 줄 우선, 너무 길면 30자에서 잘라준다.
  /// - 본문이 한 줄짜리 짧은 글이면 본문 자체가 제목 = 내용.
  String _deriveTitle(String content) {
    final firstLine = content
        .split(RegExp(r'\r?\n'))
        .firstWhere((_) => true, orElse: () => '');
    final base = firstLine.trim().isNotEmpty
        ? firstLine.trim()
        : content.trim();
    return base.characters.take(30).toString();
  }

  Future<bool> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (!_canSubmit) return false;
    final content = _contentCtl.text.trim();
    setState(() => _submitting = true);
    try {
      List<String>? imageUrls;
      if (_selectedImages.isNotEmpty) {
        imageUrls = await SharehouseService.uploadImages(_selectedImages);
      }
      final created = await PostService.createPost(
        communityId: widget.communityId,
        title: _deriveTitle(content),
        content: content,
        imageUrls: imageUrls,
      );
      if (!mounted) return true;
      Navigator.of(context).pop<PostModel>(created);
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      body: GradientLayout(
        child: Form(
          key: _formKey, // Form 위젯을 상위 Column 전체에 씌워서 하단 버튼까지 바인딩되도록 수정
          child: Column(
            children: [
              const CustomHeader(
                center: Text(
                  'New Post',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 24),
                      _buildContentField(),
                      const SizedBox(height: 24), // 하단 여백 조절
                    ],
                  ),
                ),
              ),
              // 스크롤 영역 외부(바텀 고정)로 버튼 이동
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Content',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: dark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: TextFormField(
            controller: _contentCtl,
            minLines: 6,
            maxLines: 14,
            style: const TextStyle(
              fontSize: 14,
              color: dark,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Share something with the community...',
              hintStyle: TextStyle(color: grey02),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final hasImage = _selectedImages.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              'Photo',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
            SizedBox(width: 6),
            Text(
<<<<<<< HEAD
              '(${_selectedImages.length}/$_maxImages)',
              style: const TextStyle(
=======
              '(Optional)',
              style: TextStyle(
>>>>>>> 4ccf48f752c93ecb555fba25a73efe6c3d56d1d9
                fontSize: 12,
                color: grey02,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
<<<<<<< HEAD
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddImageButton(),
              const SizedBox(width: 8),
              ..._selectedImages.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildSelectedImage(e.key, e.value),
                ),
              ),
            ],
          ),
=======
          child: hasImage
              ? _buildSelectedImage(0, _selectedImages.first)
              : _buildAddImageButton(),
>>>>>>> 4ccf48f752c93ecb555fba25a73efe6c3d56d1d9
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
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
<<<<<<< HEAD
              'Photos',
=======
              'Photo',
>>>>>>> 4ccf48f752c93ecb555fba25a73efe6c3d56d1d9
              style: TextStyle(
                fontSize: 12,
                color: grey02,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImage(int index, File file) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
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
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      // 기기 하단 노치와 패딩 레이아웃을 맞추기 위한 좌우 및 하단 패딩 설정
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 35),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          formKey: _formKey,
          text: 'Post',
          onAction: _submit,
          successMessage: '',
          failMessage: '',
          enabled: _canSubmit,
        ),
      ),
    );
  }
}
