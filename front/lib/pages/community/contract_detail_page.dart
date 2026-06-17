import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:front/constants/colors.dart';
import 'package:front/models/paper_contract_model.dart';
import 'package:front/services/paper_contract_service.dart';

import 'contract_propose_page.dart';

/// Paper contract scan detail page.
/// Opened when the user taps a CONTRACT chat message.
///
/// - Per-page image viewer (PageView + InteractiveViewer)
/// - Expandable OCR text panel
/// - "Open PDF externally" action
/// - "Propose contract from this scan" CTA → [ContractProposePage]
///
/// [iAm] is decided by the caller (typically `myMemberId == sharehouse.hostId`)
/// and forwarded as-is to [ContractProposePage] so there's no role picker.
class ContractDetailPage extends StatefulWidget {
  final int documentId;
  final int memberId;
  final int roomId;

  /// 'LANDLORD' or 'TENANT' — propagated to the propose screen.
  final String iAm;

  const ContractDetailPage({
    super.key,
    required this.documentId,
    required this.memberId,
    required this.roomId,
    required this.iAm,
  });

  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> {
  PaperContractDocumentModel? _doc;
  bool _loading = true;
  String? _error;
  bool _ocrExpanded = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await PaperContractService.getDocument(
        documentId: widget.documentId,
        memberId: widget.memberId,
      );
      if (!mounted) return;
      setState(() {
        _doc = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openPdfExternal() async {
    final url = _doc?.pdfUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the PDF externally.")),
      );
    }
  }

  Future<void> _gotoPropose() async {
    final doc = _doc;
    if (doc == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractProposePage(
          roomId: widget.roomId,
          memberId: widget.memberId,
          iAm: widget.iAm,
          paperContractDocumentId: doc.id,
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
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
          'Contract scan',
          style: TextStyle(
            color: dark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/export.svg',
              color: dark,
              width: 22,
              height: 22,
            ),
            onPressed: _openPdfExternal,
            tooltip: 'Open PDF externally',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildBody(),
      // 하단 영역:
      //   - 세입자(TENANT) → "Propose contract from this scan" CTA
      //   - 호스트(LANDLORD) → 수정/입력 권한 없음을 알리는 read-only 안내 박스
      //                       (이 단계에서 호스트는 본인이 보낸 계약서만 확인 가능)
      bottomNavigationBar: (_loading || _error != null)
          ? null
          : (widget.iAm == 'TENANT' ? _buildCta() : _buildHostInfoBar()),
    );
  }

  /// 호스트(LANDLORD) 시점의 하단 안내 배너.
  /// 이 단계에서 호스트는 deposit/rent 등을 수정할 수 없고, 자신이 보낸
  /// 계약서가 무엇인지 확인만 가능하다는 점을 분명히 보여준다.
  Widget _buildHostInfoBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: darkgreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: darkgreen, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "You sent this contract. The tenant will fill in deposit, "
                  "rent and dates. You'll review and sign in the final step.",
                  style: TextStyle(
                    fontSize: 12,
                    color: darkgreen,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _error ?? 'Error',
          style: const TextStyle(color: grey03, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final doc = _doc!;
    final pages = doc.sourceImageUrls;
    final bool isHost = widget.iAm == 'LANDLORD';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 호스트는 자신이 보낸 계약서를 확인만 할 수 있다는 안내 배지.
          if (isHost) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
              decoration: BoxDecoration(
                color: darkgreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: darkgreen,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    // 혹시 모를 글자 넘침 방지를 위해 Expanded 권장
                    child: Text(
                      'Sent by you · read only',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: darkgreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // 원본 페이지 뷰어
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.white,
              height: 460,
              child: pages.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: grey02,
                      ),
                    )
                  : Stack(
                      children: [
                        PageView.builder(
                          itemCount: pages.length,
                          onPageChanged: (i) =>
                              setState(() => _currentPage = i),
                          itemBuilder: (_, i) => InteractiveViewer(
                            child: Image.network(
                              pages[i],
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: grey02,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentPage + 1} / ${pages.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          _MetaRow(label: 'Status', value: doc.status ?? '-'),
          _MetaRow(
            label: 'Created',
            value: doc.regTime?.split('T').first ?? '-',
          ),

          const SizedBox(height: 16),

          // OCR 텍스트
          if ((doc.ocrText ?? '').isNotEmpty) ...[
            InkWell(
              onTap: () => setState(() => _ocrExpanded = !_ocrExpanded),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.text_snippet_outlined,
                      size: 18,
                      color: darkgreen,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'OCR text',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: dark,
                        ),
                      ),
                    ),
                    SvgPicture.asset(
                      _ocrExpanded
                          ? 'assets/icons/arrow_up.svg'
                          : 'assets/icons/arrow_down.svg',
                      color: grey03,
                      width: 15,
                    ),
                  ],
                ),
              ),
            ),
            if (_ocrExpanded) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: grey01.withOpacity(0.7)),
                ),
                child: SelectableText(
                  doc.ocrText!,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: dark,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '※ OCR may misread characters — please double-check the terms in the next step.',
                style: TextStyle(fontSize: 11, color: grey03, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCta() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          onPressed: _gotoPropose,
          child: const Text(
            'Propose contract from this scan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800, // 기존 두께 유지
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: grey03,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
