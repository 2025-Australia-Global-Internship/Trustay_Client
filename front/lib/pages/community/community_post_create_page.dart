import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import 'package:front/constants/colors.dart';
import 'package:front/models/post_model.dart';
import 'package:front/services/post_service.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';

/// 커뮤니티 게시글 작성 페이지.
///
/// - 본문(필수) + 사진(0~5장)
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
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _contentCtl = TextEditingController();

  final List<File> _selectedImages = [];
  static const int _maxImages = 5;

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

  bool get _canSubmit =>
      _contentCtl.text.trim().isNotEmpty && !_submitting;

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

  /// 본문에서 제목 추출.
  /// - 첫 줄 우선, 너무 길면 30자에서 잘라준다.
  /// - 본문이 한 줄짜리 짧은 글이면 본문 자체가 제목 = 내용.
  String _deriveTitle(String content) {
    final firstLine =
        content.split(RegExp(r'\r?\n')).firstWhere((_) => true, orElse: () => '');
    final base = firstLine.trim().isNotEmpty ? firstLine.trim() : content.trim();
    return base.characters.take(30).toString();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
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
      if (!mounted) return;
      Navigator.of(context).pop<PostModel>(created);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
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
                'New Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _buildContentField(),
                  const SizedBox(height: 16),
                  _buildImagePicker(),
                ],
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: TextField(
        controller: _contentCtl,
        minLines: 6,
        maxLines: 14,
        style: const TextStyle(
          fontSize: 14,
          color: dark,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Share something with the community...',
          hintStyle: TextStyle(color: Color(0xFFD0D0D0)),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
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
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddImageButton(),
              const SizedBox(width: 10),
              ..._selectedImages.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 10),
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
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: green, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/camera.svg',
              width: 22,
              height: 22,
              color: green,
            ),
            const SizedBox(height: 4),
            const Text(
              'Add',
              style: TextStyle(
                color: green,
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
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            file,
            width: 92,
            height: 92,
            fit: BoxFit.cover,
          ),
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

  Widget _buildSubmitButton() {
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
              backgroundColor: green,
              disabledBackgroundColor: const Color(0xFFC7CFA0),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Post',
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
