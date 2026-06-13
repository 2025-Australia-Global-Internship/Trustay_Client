import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import 'package:front/constants/colors.dart';
import 'package:front/services/paper_contract_service.dart';

/// "+" 메뉴 → Contract 누른 뒤 열리는 종이 계약서 스캔 업로드 화면.
///
/// 사용자가 사진 여러 장(또는 카메라 연속 촬영)으로 계약서를 캡쳐 → 페이지 순서 조정 → 업로드.
/// 업로드되면 백엔드가 OCR + PDF 합본을 만들고 채팅방에 CONTRACT 메시지를 자동 broadcast 하므로,
/// 이 화면은 단순히 성공/실패만 보여주고 pop.
class ContractScanUploadPage extends StatefulWidget {
  final int roomId;
  final int memberId;

  const ContractScanUploadPage({
    super.key,
    required this.roomId,
    required this.memberId,
  });

  @override
  State<ContractScanUploadPage> createState() => _ContractScanUploadPageState();
}

class _ContractScanUploadPageState extends State<ContractScanUploadPage> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pages = [];
  bool _uploading = false;

  Future<void> _addFromGallery() async {
    if (_uploading) return;
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() => _pages.addAll(picked));
  }

  Future<void> _addFromCamera() async {
    if (_uploading) return;
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _pages.add(picked));
  }

  void _removeAt(int index) {
    if (_uploading) return;
    setState(() => _pages.removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    if (_uploading) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, item);
    });
  }

  Future<void> _upload() async {
    if (_pages.isEmpty || _uploading) return;
    setState(() => _uploading = true);
    try {
      await PaperContractService.scan(
        roomId: widget.roomId,
        memberId: widget.memberId,
        images: _pages.map((x) => File(x.path)).toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contract scan shared in the chat.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/arrow_back.svg',
            width: 22,
            height: 22,
            color: dark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan contract',
          style: TextStyle(
            color: dark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHelpBanner(),
          Expanded(
            child: _pages.isEmpty
                ? _buildEmptyState()
                : _buildPagesGrid(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHelpBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Take a photo of each page of the paper contract. We will run OCR, '
        'merge the pages into a single PDF, and share it in this chat. '
        'For multi-page contracts, please arrange the pages in order.',
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: grey04,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_outlined, size: 64, color: grey02),
          const SizedBox(height: 12),
          const Text(
            'No pages added yet.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: grey03,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _addButton(
                icon: Icons.photo_library_outlined,
                label: 'From gallery',
                onTap: _addFromGallery,
              ),
              const SizedBox(width: 12),
              _addButton(
                icon: Icons.camera_alt_outlined,
                label: 'Take photo',
                onTap: _addFromCamera,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: grey01),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: darkgreen),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: darkgreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagesGrid() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _pages.length,
      onReorder: _reorder,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final file = _pages[index];
        return Container(
          key: ValueKey(file.path),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: darkgreen,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(file.path),
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: grey03),
                onPressed: () => _removeAt(index),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.drag_handle, color: grey02),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            if (_pages.isNotEmpty) ...[
              Expanded(
                flex: 0,
                child: Row(
                  children: [
                    _miniIconButton(
                      icon: Icons.photo_library_outlined,
                      onTap: _addFromGallery,
                    ),
                    const SizedBox(width: 8),
                    _miniIconButton(
                      icon: Icons.camera_alt_outlined,
                      onTap: _addFromCamera,
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ],
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pages.isEmpty ? grey01 : green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _pages.isEmpty || _uploading ? null : _upload,
                child: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _pages.isEmpty
                            ? 'Add at least one page'
                            : 'Upload ${_pages.length} page${_pages.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: _uploading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: darkgreen, size: 22),
      ),
    );
  }
}
