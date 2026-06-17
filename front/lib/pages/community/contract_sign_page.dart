import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:signature/signature.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:front/constants/colors.dart';
import 'package:front/models/contract_model.dart';
import 'package:front/services/contract_service.dart';

/// 상대방이 받은 계약 제안을 확인하고 본인 서명을 추가하는 화면.
///
/// - 계약 조건 / 임대인·임차인 / 첨부 PDF 링크 노출
/// - 캔버스 손글씨 서명 캡쳐 → sign API 호출
/// - 양측 서명되면 ACTIVE 로 전이되고 채팅방에 CONTRACT_SIGNED 메시지가 broadcast 됨
class ContractSignPage extends StatefulWidget {
  final int contractId;
  final int memberId;

  const ContractSignPage({
    super.key,
    required this.contractId,
    required this.memberId,
  });

  @override
  State<ContractSignPage> createState() => _ContractSignPageState();
}

class _ContractSignPageState extends State<ContractSignPage> {
  ContractModel? _contract;
  bool _loading = true;
  String? _error;

  final SignatureController _sigCtl = SignatureController(
    penStrokeWidth: 3,
    penColor: dark,
    exportBackgroundColor: Colors.white,
  );
  bool _signing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sigCtl.dispose();
    super.dispose();
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
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the PDF externally.")),
      );
    }
  }

  Future<void> _sign() async {
    if (_sigCtl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw your signature.')),
      );
      return;
    }
    final bytes = await _sigCtl.toPngBytes();
    if (bytes == null) return;

    setState(() => _signing = true);
    try {
      final updated = await ContractService.sign(
        contractId: widget.contractId,
        signaturePng: bytes,
      );
      if (!mounted) return;
      setState(() => _contract = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.isActive
                ? 'Signed! The contract is now active.'
                : 'Your signature has been recorded.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sign: $e')));
    } finally {
      if (mounted) setState(() => _signing = false);
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
          'Review & sign contract',
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
                child: Text(_error!, style: const TextStyle(color: grey03)),
              ),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final c = _contract!;
    final canSign = c.needsMySignature(widget.memberId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusBadge(c.status),
          const SizedBox(height: 12),

          _card(
            title: 'Listing',
            child: Text(
              c.houseTitle ?? '-',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: dark,
              ),
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
            title: 'Terms',
            child: Column(
              children: [
                _rowKV(
                  'Deposit',
                  c.deposit == null ? '-' : '${_money(c.deposit!)} AUD',
                ),
                const SizedBox(height: 6),
                _rowKV(
                  'Monthly',
                  c.monthlyRent == null ? '-' : '${_money(c.monthlyRent!)} AUD',
                ),
                const SizedBox(height: 6),
                _rowKV('Period', '${c.startDate ?? '-'} ~ ${c.endDate ?? '-'}'),
              ],
            ),
          ),

          if (c.paperContractPdfUrl != null) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: darkgreen,
                side: const BorderSide(color: darkgreen),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
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

          const SizedBox(height: 16),

          _card(
            title: 'Signature status',
            child: Column(
              children: [
                _signatureStatusRow(
                  label: c.landlordName.isEmpty ? 'Landlord' : c.landlordName,
                  signedAt: c.landlordSignedAt,
                  signedUrl: c.landlordSignatureUrl,
                ),
                const SizedBox(height: 10),
                _signatureStatusRow(
                  label: c.tenantName.isEmpty ? 'Tenant' : c.tenantName,
                  signedAt: c.tenantSignedAt,
                  signedUrl: c.tenantSignatureUrl,
                ),
              ],
            ),
          ),

          if (canSign) ...[
            const SizedBox(height: 16),
            _card(
              title: 'Your signature',
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: grey01),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Signature(
                        controller: _sigCtl,
                        width: double.infinity,
                        height: 180,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        _sigCtl.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh, size: 16, color: grey04),
                      label: const Text(
                        'Clear',
                        style: TextStyle(
                          color: grey04,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              onPressed: _signing ? null : _sign,
              child: _signing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Agree and sign',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '※ Once both parties sign, the contract becomes active and is automatically linked when you make a payment.',
                style: TextStyle(fontSize: 11, color: grey03, height: 1.4),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                c.isActive
                    ? 'Both parties have signed. This contract is now active.'
                    : 'Your signature is already recorded. Waiting for the other party.',
                style: const TextStyle(
                  fontSize: 12,
                  color: grey04,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
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
              fontSize: 12,
              color: grey03,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(
              fontSize: 13,
              color: dark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _signatureStatusRow({
    required String label,
    required String? signedAt,
    required String? signedUrl,
  }) {
    final signed = signedUrl != null && signedUrl.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
                  child: Image.network(
                    signedUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported, size: 18),
                  ),
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
                  fontSize: 13,
                  color: dark,
                  fontWeight: FontWeight.w800,
                ),
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
