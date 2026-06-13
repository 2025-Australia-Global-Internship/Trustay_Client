import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:front/constants/colors.dart';
import 'package:front/models/contract_model.dart';
import 'package:front/services/contract_service.dart';

import 'contract_sign_page.dart';

/// 계약 단건 조회 화면.
///
/// 채팅방의 CONTRACT_PROPOSAL / CONTRACT_SIGNED 메시지를 탭하면 진입.
/// - 상태(DRAFT/ACTIVE/EXPIRED)와 양측 서명 현황
/// - PDF (signed 또는 원본 스캔) 외부 열기
/// - 내가 아직 서명 안 했으면 "서명하러 가기" 버튼 → ContractSignPage
class ContractViewPage extends StatefulWidget {
  final int contractId;
  final int memberId;

  const ContractViewPage({
    super.key,
    required this.contractId,
    required this.memberId,
  });

  @override
  State<ContractViewPage> createState() => _ContractViewPageState();
}

class _ContractViewPageState extends State<ContractViewPage> {
  ContractModel? _contract;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await ContractService.getById(widget.contractId);
      if (!mounted) return;
      setState(() {
        _contract = c;
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

  Future<void> _openPdf(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the PDF externally.")),
      );
    }
  }

  Future<void> _gotoSign() async {
    final updated = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) => ContractSignPage(
          contractId: widget.contractId,
          memberId: widget.memberId,
        ),
      ),
    );
    if (updated == true) _load();
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
          'Contract',
          style: TextStyle(
            color: dark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child:
                        Text(_error!, style: const TextStyle(color: grey03)),
                  ),
                )
              : _buildBody(),
      bottomNavigationBar: _loading || _error != null || _contract == null
          ? null
          : _buildBottomBar(_contract!),
    );
  }

  Widget _buildBody() {
    final c = _contract!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _statusBadge(c.status),
        const SizedBox(height: 12),
        _card(
          title: 'Listing',
          child: Text(
            c.houseTitle ?? '-',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: dark),
          ),
        ),
        _card(
          title: 'Terms',
          child: Column(
            children: [
              _rowKV('Deposit',
                  c.deposit == null ? '-' : '${_money(c.deposit!)} AUD'),
              const SizedBox(height: 6),
              _rowKV('Monthly',
                  c.monthlyRent == null ? '-' : '${_money(c.monthlyRent!)} AUD'),
              const SizedBox(height: 6),
              _rowKV('Period', '${c.startDate ?? '-'} ~ ${c.endDate ?? '-'}'),
            ],
          ),
        ),
        _card(
          title: 'Parties',
          child: Column(
            children: [
              _rowKV('Landlord', c.landlordName),
              const SizedBox(height: 6),
              _rowKV('Tenant', c.tenantName),
            ],
          ),
        ),
        _card(
          title: 'Signature status',
          child: Column(
            children: [
              _signatureRow('Landlord', c.landlordSignatureUrl, c.landlordSignedAt),
              const SizedBox(height: 10),
              _signatureRow('Tenant', c.tenantSignatureUrl, c.tenantSignedAt),
            ],
          ),
        ),
        if (c.signedPdfUrl != null) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: darkgreen,
              side: const BorderSide(color: darkgreen),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _openPdf(c.signedPdfUrl!),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text(
              'Open signed contract PDF',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ] else if (c.paperContractPdfUrl != null) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: darkgreen,
              side: const BorderSide(color: darkgreen),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _openPdf(c.paperContractPdfUrl!),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text(
              'Open attached scan PDF',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(ContractModel c) {
    final needsMine = c.needsMySignature(widget.memberId);
    if (!needsMine && !c.isActive) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: needsMine
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _gotoSign,
                child: const Text(
                  'Add my signature',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6E5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: green, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Active contract · automatically linked at payment.',
                        style: TextStyle(
                          color: darkgreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'ACTIVE':
        color = green;
        label = 'Active';
        break;
      case 'SIGNED':
        color = green;
        label = 'Signed';
        break;
      case 'EXPIRED':
        color = grey03;
        label = 'Expired';
        break;
      default:
        color = const Color(0xFFFFB020);
        label = 'Pending';
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: darkgreen),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _rowKV(String k, String v) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            k,
            style: const TextStyle(
                fontSize: 12, color: grey04, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(
                fontSize: 13, color: dark, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _signatureRow(String label, String? signedUrl, String? signedAt) {
    final signed = signedUrl != null && signedUrl.isNotEmpty;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: signed
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(signedUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                    return const Icon(Icons.image_not_supported, size: 18);
                  }),
                )
              : const Icon(Icons.edit_off, size: 18, color: grey03),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 13, color: dark, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                signed
                    ? 'Signed · ${(signedAt ?? '').split('.').first}'
                    : 'Waiting for signature',
                style: TextStyle(
                  fontSize: 11,
                  color: signed ? green : grey03,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _money(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final rem = s.length - i - 1;
      if (rem > 0 && rem % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }
}
