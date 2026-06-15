import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/review_service.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/gradient_layout.dart';

/// 홈스테이를 나간 직후(혹은 거주 이력이 있는 매물에 대해) 작성하는 리뷰 화면.
///
/// - 별점 (1 ~ 5) 필수
/// - 본문 텍스트 (선택, 최대 2000자) — 이미지/사진은 첨부하지 않는다.
///
/// 작성 성공 시 `Navigator.pop(context, true)` 로 종료 → 호출 측에서
/// 목록을 새로고침할 수 있다.
class WriteReviewPage extends StatefulWidget {
  final int houseId;
  final String? houseTitle;

  const WriteReviewPage({
    super.key,
    required this.houseId,
    this.houseTitle,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  int _rating = 0;
  final TextEditingController _contentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final content = _contentCtrl.text.trim();
      await ReviewService.createReview(
        houseId: widget.houseId,
        rating: _rating,
        content: content.isEmpty ? null : content,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your review!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: GradientLayout(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              CustomHeader(
                center: const Text(
                  'Write a Review',
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.houseTitle != null &&
                          widget.houseTitle!.trim().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
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
                          child: Row(
                            children: [
                              const Icon(Icons.home_outlined,
                                  size: 18, color: darkgreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.houseTitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: dark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                      const Text(
                        'How would you rate your stay?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StarPicker(
                        rating: _rating,
                        onChanged: (v) => setState(() => _rating = v),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Tell others about your stay',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: grey01, width: 1),
                        ),
                        child: TextField(
                          controller: _contentCtrl,
                          maxLength: 2000,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            hintText:
                                'What did you like? What could be better? (optional)',
                            hintStyle: TextStyle(color: grey03, fontSize: 13),
                            contentPadding: EdgeInsets.all(14),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: dark,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Review',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarPicker extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _StarPicker({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              size: 44,
              color: filled ? green : grey02,
            ),
          ),
        );
      }),
    );
  }
}
