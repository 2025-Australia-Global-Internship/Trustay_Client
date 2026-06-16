import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:front/constants/colors.dart';
import 'package:front/services/post_service.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/widgets/primary_button.dart';

/// 새 공지 작성 페이지. 플로팅 버튼(연필 아이콘)에서 진입한다.
///
/// - 제목 / 내용 / (선택) 이미지 1~10장
/// - 작성 후 Navigator.pop(context, true) 로 부모 화면에 새로고침을 요청한다.
class NoticeCreatePage extends StatefulWidget {
  final int sharehouseId;

  const NoticeCreatePage({super.key, required this.sharehouseId});

  @override
  State<NoticeCreatePage> createState() => _NoticeCreatePageState();
}

class _NoticeCreatePageState extends State<NoticeCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleCtl = TextEditingController();
  final TextEditingController _contentCtl = TextEditingController();

  final List<File> _selectedImages = [];
  static const int _maxImages = 5;

  bool _submitting = false;

  @override
  void dispose() {
    _titleCtl.dispose();
    _contentCtl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can add up to $_maxImages images.')),
      );
      return;
    }

    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() {
      final remaining = _maxImages - _selectedImages.length;
      _selectedImages.addAll(picked.take(remaining).map((x) => File(x.path)));
    });
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<bool> _submit() async {
    if (_submitting) return false;
    final title = _titleCtl.text.trim();
    final content = _contentCtl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and content.')),
      );
      return false;
    }

    setState(() => _submitting = true);
    try {
      List<String>? imageUrls;
      if (_selectedImages.isNotEmpty) {
        imageUrls = await SharehouseService.uploadImages(_selectedImages);
      }

      await PostService.createPost(
        sharehouseId: widget.sharehouseId,
        title: title,
        content: content,
        isNotice: true,
        imageUrls: imageUrls,
      );

      if (!mounted) return false;
      Navigator.pop(context, true);
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
      // GradientLayout 은 상단 180px 만 그라데이션을 그리므로,
      // 나머지 영역이 검게 비치지 않도록 Scaffold 배경을 light cream 으로 깐다.
      backgroundColor: const Color(0xFFFAFAFA),
      body: GradientLayout(
        child: Column(
          children: [
            const CustomHeader(
              center: Text(
                'Write Notice',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 14),
                    _buildTitleField(),
                    const SizedBox(height: 14),
                    _buildContentField(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: PrimaryButton(
                formKey: _formKey,
                text: 'Post Notice',
                isLoading: _submitting,
                onAction: _submit,
                successMessage: '',
                failMessage: '',
                color: green,
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Title
  // ---------------------------------------------------------------------------
  Widget _buildTitleField() {
    return CommonTextField(
      label: 'Title',
      controller: _titleCtl,
      hintText: 'Notice title',
      bottomPadding: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------
  Widget _buildContentField() {
    return CommonTextField(
      label: 'Content',
      controller: _contentCtl,
      hintText: 'Write what your house mates need to know...',
      maxLines: 6,
      bottomPadding: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Image picker
  // ---------------------------------------------------------------------------
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${_selectedImages.length}/$_maxImages)',
              style: const TextStyle(fontSize: 12, color: grey03),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
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
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_camera, color: grey02, size: 32),
            const SizedBox(height: 6),
            const Text(
              'Photos',
              style: TextStyle(
                color: grey02,
                fontSize: 12,
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
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
