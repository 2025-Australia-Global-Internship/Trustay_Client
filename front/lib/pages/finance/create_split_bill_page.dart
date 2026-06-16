import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:front/constants/colors.dart';
import 'package:front/constants/exchange_rate.dart';
import 'package:front/models/chat_room_list_model.dart';
import 'package:front/models/user_model.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/services/chat_service.dart';
import 'package:front/services/payment_service.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/widgets/primary_button.dart';

import 'select_mate_sheet.dart';

/// Split Bill 생성 페이지 (Create_Split_Bills_01 디자인).
///
/// 입력값:
///  - Total Bill (호주달러, 정수 단위로 보냄)
///  - Bill Name (백엔드 `title` 로 사용)
///  - Note (현재 백엔드 모델에 별도 필드 없음 — title 에 합쳐서 전달)
///  - Split With (메이트 리스트, 자기 자신 포함하여 N등분)
///
/// 백엔드 createDutchPay 호출 시:
///  - payeeMemberId = 본인(현재 사용자)
///  - memberIds     = 선택한 메이트 들의 memberId (본인 제외)
class CreateSplitBillPage extends StatefulWidget {
  const CreateSplitBillPage({super.key});

  @override
  State<CreateSplitBillPage> createState() => _CreateSplitBillPageState();
}

class _CreateSplitBillPageState extends State<CreateSplitBillPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  User? _me;
  List<ChatRoomListModel> _mateCandidates = const [];
  final List<ChatRoomListModel> _selectedMates = [];
  bool _isSubmitting = false;
  bool _isLoadingCandidates = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final user = await AuthService.fetchProfile();
      final rooms = await ChatService.getMyChatRooms(
        user.memberId,
        page: 0,
        size: 50,
      );
      // 자기 자신 제외 + 중복 memberId 제거.
      final Map<int, ChatRoomListModel> unique = {};
      for (final r in rooms) {
        if (r.otherMemberId <= 0) continue;
        if (r.otherMemberId == user.memberId) continue;
        unique.putIfAbsent(r.otherMemberId, () => r);
      }
      if (!mounted) return;
      setState(() {
        _me = user;
        _mateCandidates = unique.values.toList();
        _isLoadingCandidates = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCandidates = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 계산
  // ---------------------------------------------------------------------------

  /// 호주달러 입력값을 double 로 파싱 ($, 콤마 제거).
  double get _totalAmount {
    final raw = _amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  /// 총 인원수 = 나 + 선택된 메이트.
  int get _splitCount => 1 + _selectedMates.length;

  /// 각자 분담 금액 (소수 둘째 자리까지).
  double get _perPerson => _splitCount == 0 ? 0 : (_totalAmount / _splitCount);

  bool get _canSubmit =>
      _totalAmount > 0 &&
      _selectedMates.isNotEmpty &&
      _nameCtrl.text.trim().isNotEmpty &&
      !_isSubmitting;

  String _fmtMoney(num v) {
    return NumberFormat.currency(
      locale: 'en_AU',
      symbol: '\$',
      decimalDigits: 2,
    ).format(v);
  }

  // ---------------------------------------------------------------------------
  // 액션
  // ---------------------------------------------------------------------------
  Future<void> _openSelectMate() async {
    if (_mateCandidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need to chat with someone first before adding them as a mate.',
          ),
        ),
      );
      return;
    }
    final selected = await showModalBottomSheet<List<ChatRoomListModel>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SelectMateSheet(
        candidates: _mateCandidates,
        initialSelected: _selectedMates,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedMates
        ..clear()
        ..addAll(selected);
    });
  }

  void _removeMate(ChatRoomListModel m) {
    setState(() {
      _selectedMates.removeWhere((e) => e.otherMemberId == m.otherMemberId);
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final me = _me;
    if (me == null) return;

    setState(() => _isSubmitting = true);
    try {
      // 입력값은 호주달러(AUD). 서버/DB/토스 결제는 모두 KRW 정수로 통일하므로
      // 전송 직전에 환산한다 (1 AUD ≈ kAudToKrwRate KRW).
      // 변환 단계는 audToKrw 에 일원화돼 있어 환율을 바꾸려면 그 한 곳만 손대면 된다.
      final int totalKrw = audToKrw(_totalAmount);
      // 백엔드 createDutchPay 규약:
      //   - memberIds 에는 "본인 포함" 전체 참여자가 들어가야 한다.
      //   - payeeMemberId 는 memberIds 에 반드시 포함돼야 한다.
      // 본인이 payee(받는 쪽)이고 본인 몫도 N등분에 참여한다.
      final memberIds = <int>[
        me.memberId,
        ..._selectedMates.map((e) => e.otherMemberId),
      ];
      await PaymentService.createDutchPay(
        totalAmount: totalKrw,
        memberIds: memberIds,
        payeeMemberId: me.memberId,
        title: _composeTitle(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Split bill sent. We'll let you know as mates pay their share.",
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create split bill: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Bill Name 과 Note 를 합쳐서 backend title 로 전달.
  /// (백엔드 도메인에 별도 note 필드가 없는 한 합쳐서 보내는 게 가장 안전.)
  String _composeTitle() {
    final name = _nameCtrl.text.trim();
    final note = _noteCtrl.text.trim();
    if (note.isEmpty) return name;
    return '$name — $note';
  }

  // ---------------------------------------------------------------------------
  // 빌드
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: GradientLayout(
        child: Column(
          children: [
            const CustomHeader(
              showBack: true,
              toolbarHeight: 56,
              center: Text(
                'Create Split Bills',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountField(),
                      if (_totalAmount > 0) ...[
                        const SizedBox(height: 8),
                        _buildKrwPreview(),
                      ],
                      const SizedBox(height: 14),
                      CommonTextField(
                        label: 'Bill Name',
                        controller: _nameCtrl,
                        hintText: 'Shared Meal',
                        onChanged: (_) => setState(() {}),
                        bottomPadding: 0,
                      ),
                      const SizedBox(height: 14),
                      CommonTextField(
                        label: 'Note',
                        controller: _noteCtrl,
                        hintText: 'Please send the money by January.',
                        maxLines: 2,
                        onChanged: (_) => setState(() {}),
                        bottomPadding: 0,
                      ),
                      const SizedBox(height: 26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _label('Split With'),
                          Text(
                            '${_selectedMates.length} person',
                            style: const TextStyle(
                              fontSize: 12,
                              color: grey03,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingCandidates)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(color: green),
                          ),
                        )
                      else
                        _buildMatesRow(),
                      if (_selectedMates.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildPerPersonList(),
                        const SizedBox(height: 16),
                        _buildPayeeHint(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildSaveButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        color: dark,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  /// 사용자가 입력한 AUD 금액의 KRW 환산값을 미리 보여준다.
  ///
  /// 토스 결제는 KRW 로 진행되기 때문에, 입력 시점에 실제 결제 금액을
  /// 확인할 수 있도록 "≈ ₩50,000 (1 AUD = 1,000 KRW)" 형식으로 표기한다.
  Widget _buildKrwPreview() {
    final krw = audToKrw(_totalAmount);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz, size: 14, color: grey03),
          const SizedBox(width: 4),
          Text(
            '≈ ${formatKrw(krw)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkgreen,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '(1 AUD = 1,000 KRW)',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: grey03,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return CommonTextField(
      label: 'Total Bill',
      controller: _amountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      prefixIcon: const Text(
        '\$',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: green,
        ),
      ),
      prefixIconPadding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
      suffixIcon: GestureDetector(
        onTap: () {
          _amountCtrl.clear();
          setState(() {});
        },
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: grey02, width: 1.3),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.close, size: 13, color: grey03),
        ),
      ),
      hintText: '0',
      onChanged: (_) => setState(() {}),
      bottomPadding: 0,
    );
  }

  Widget _buildMatesRow() {
    if (_selectedMates.isEmpty) {
      return _buildAddMateBigButton();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildAddMateSmallButton(),
          const SizedBox(width: 14),
          for (final m in _selectedMates) ...[
            _buildMateChip(m),
            const SizedBox(width: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildAddMateBigButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _openSelectMate,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Add Mate',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMateSmallButton() {
    return GestureDetector(
      onTap: _openSelectMate,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: grey02, width: 1.4),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, size: 18, color: dark),
          ),
          const SizedBox(height: 6),
          const SizedBox(
            width: 60,
            child: Text(
              '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMateChip(ChatRoomListModel m) {
    final hasImg = m.profileImageUrl != null && m.profileImageUrl!.isNotEmpty;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey[300],
              backgroundImage: hasImg
                  ? NetworkImage(m.profileImageUrl!) as ImageProvider
                  : const AssetImage('assets/icons/default.png'),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: () => _removeMate(m),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.close, size: 12, color: dark),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(
            m.otherMemberName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: dark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerPersonList() {
    final me = _me;
    final per = _perPerson;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          if (me != null)
            _buildPerPersonRow(
              name: '${me.name} (me)',
              imageUrl: me.profileImageUrl,
              amount: per,
            ),
          for (final mate in _selectedMates)
            _buildPerPersonRow(
              name: mate.otherMemberName,
              imageUrl: mate.profileImageUrl,
              amount: per,
            ),
        ],
      ),
    );
  }

  Widget _buildPerPersonRow({
    required String name,
    required String? imageUrl,
    required double amount,
  }) {
    final hasImg = imageUrl != null && imageUrl.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[300],
            backgroundImage: hasImg
                ? NetworkImage(imageUrl) as ImageProvider
                : const AssetImage('assets/icons/default.png'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
          ),
          Text(
            _fmtMoney(amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: darkgreen,
            ),
          ),
        ],
      ),
    );
  }

  /// 만든 사람이 정산자(payee)라는 점을 명확히 알려주는 안내 박스.
  ///
  /// "본인 Pending이 왜 비어 있지?" 라는 흔한 혼동을 미리 차단한다.
  /// 메이트들의 결제 진행은 Finance 메인의 거래 내역에서 "Awaiting" 으로 보인다.
  Widget _buildPayeeHint() {
    final me = _me;
    final mateCount = _selectedMates.length;
    final per = _perPerson;
    final receivable = per * mateCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE57F), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: darkgreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me == null
                      ? "You'll receive payments from your mates"
                      : "${me.name}, you'll receive payments",
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: darkgreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mateCount == 0
                      ? "Each mate will pay their share to you. Your own share is already covered."
                      : 'Each of your $mateCount mate${mateCount == 1 ? '' : 's'} will pay ${_fmtMoney(per)} to you — totalling ${_fmtMoney(receivable)}. Your own share is already covered.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: PrimaryButton(
        formKey: _formKey,
        text: 'Save',
        isLoading: _isSubmitting,
        onAction: () async {
          await _submit();
          return false;
        },
        successMessage: '',
        failMessage: '',
        enabled: _canSubmit,
      ),
    );
  }
}
