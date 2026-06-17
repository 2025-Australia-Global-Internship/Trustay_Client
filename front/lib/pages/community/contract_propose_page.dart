import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:signature/signature.dart';

import 'package:front/constants/colors.dart';
import 'package:front/services/contract_service.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:front/widgets/primary_button.dart';

/// Contract proposal screen.
///
/// - Deposit / monthly rent / start & end date inputs
/// - Handwritten signature on canvas (captured as PNG)
/// - Calls `propose` API which broadcasts a `CONTRACT_PROPOSAL` chat message
///
/// The proposer's role (LANDLORD / TENANT) is **decided automatically by the
/// caller** (typically derived from the listing's host) and passed in via
/// [iAm], so there is no role selector in this UI anymore: the landlord only
/// sees the landlord flow, the tenant only sees the tenant flow.
class ContractProposePage extends StatefulWidget {
  final int roomId;
  final int memberId;
  final int? paperContractDocumentId;

  /// 'LANDLORD' or 'TENANT' — decided by the parent (e.g. comparing
  /// `myMemberId == sharehouse.hostId`).
  final String iAm;

  const ContractProposePage({
    super.key,
    required this.roomId,
    required this.memberId,
    required this.iAm,
    this.paperContractDocumentId,
  });

  @override
  State<ContractProposePage> createState() => _ContractProposePageState();
}

class _ContractProposePageState extends State<ContractProposePage> {
  final _formKey = GlobalKey<FormState>();
  final _depositCtl = TextEditingController();
  final _rentCtl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  final SignatureController _sigCtl = SignatureController(
    penStrokeWidth: 3,
    penColor: dark,
    exportBackgroundColor: Colors.white,
  );
  bool _submitting = false;

  @override
  void dispose() {
    _depositCtl.dispose();
    _rentCtl.dispose();
    _sigCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = (start ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'Select'
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _formValid {
    return _depositCtl.text.trim().isNotEmpty &&
        _rentCtl.text.trim().isNotEmpty &&
        _startDate != null &&
        _endDate != null &&
        !_sigCtl.isEmpty;
  }

  Future<void> _submit() async {
    if (!_formValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in every field and sign before sending.'),
        ),
      );
      return;
    }
    final deposit = int.tryParse(_depositCtl.text.replaceAll(',', ''));
    final rent = int.tryParse(_rentCtl.text.replaceAll(',', ''));
    if (deposit == null || rent == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Amounts must be numbers.')));
      return;
    }
    final sigBytes = await _sigCtl.toPngBytes();
    if (sigBytes == null) return;

    setState(() => _submitting = true);
    try {
      await ContractService.propose(
        roomId: widget.roomId,
        paperContractDocumentId: widget.paperContractDocumentId,
        iAm: widget.iAm,
        deposit: deposit,
        monthlyRent: rent,
        startDate: _fmtDate(_startDate),
        endDate: _fmtDate(_endDate),
        signaturePng: sigBytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal sent to the other party.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send proposal: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _roleLabel => widget.iAm == 'LANDLORD' ? 'Landlord' : 'Tenant';

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
          'Propose contract',
          style: TextStyle(
            color: dark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 역할은 호스트 정보 기반으로 자동 결정되므로 선택 UI 없이 표시만 한다.
            _roleBanner(),
            const SizedBox(height: 18),

            // 1. Deposit (보증금) 입력창 변경
            CommonTextField(
              label: 'Terms',
              hintText: 'Deposit (AUD)',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              controller: _depositCtl,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter deposit';
                }
                return null;
              },
            ),

            // 2. Monthly Rent (월세) 입력창 변경
            CommonTextField(
              label: '',
              hintText: 'Monthly rent (AUD)',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              controller: _rentCtl,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter monthly rent';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _sectionTitle('Period'),
            Row(
              children: [
                Expanded(
                  child: _dateField(
                    label: 'Start',
                    value: _fmtDate(_startDate),
                    onTap: () => _pickDate(start: true),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _dateField(
                    label: 'End',
                    value: _fmtDate(_endDate),
                    onTap: () => _pickDate(start: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            _sectionTitle('Your signature'),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    child: Signature(
                      controller: _sigCtl,
                      width: double.infinity,
                      height: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const Divider(height: 1, color: grey01),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sign here with your finger',
                          style: TextStyle(
                            fontSize: 11,
                            color: grey02,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _sigCtl.clear();
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.refresh,
                            size: 16,
                            color: grey02,
                          ),
                          label: const Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 12,
                              color: grey02,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              formKey: _formKey,
              text: 'Send proposal',
              isLoading: _submitting, // 로딩 중일 때 로딩 서클 자동 작동
              enabled: !_submitting, // 로딩 중이 아닐 때만 활성화
              color: green,
              textColor: Colors.white,
              successMessage:
                  'Proposal sent successfully', // 성공 시 상단/하단 스낵바용 메시지
              failMessage: 'Failed to send proposal', // 실패 시 스낵바용 메시지
              onAction: () async {
                // PrimaryButton은 비동기로 bool 값(성공 여부)을 반환해야 합니다.
                // 기존 _submit() 메서드를 실행하고 정상 작동 시 true를 리턴하도록 합니다.
                await _submit();
                return true;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: dark,
        ),
      ),
    );
  }

  /// 역할 안내 배너 — 선택지가 아니라 정보 표시.
  Widget _roleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      decoration: BoxDecoration(
        color: darkgreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, size: 18, color: darkgreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are proposing as the $_roleLabel.',
              style: const TextStyle(
                fontSize: 12,
                color: darkgreen,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: grey03,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
              ],
            ),
            SvgPicture.asset(
              'assets/icons/calendar.svg',
              color: grey03,
              width: 15,
              height: 15,
            ),
          ],
        ),
      ),
    );
  }
}
