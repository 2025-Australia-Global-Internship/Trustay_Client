import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/colors.dart';
import '../../index.dart' show goToFinanceTab;
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/gradient_layout.dart';

/// "My Wallet" — 사용자 개인의 정산 계좌 + 미결제 + 최근 거래 요약.
///
/// House Finances(하단 탭) 페이지는 공유 가계부 / 캘린더 중심이라면,
/// My Wallet 은 "내 계정 안의 돈 흐름" 에 집중한다:
///   1) 정산 계좌(Account Info) 카드 + Edit 진입
///   2) Pending Payments — 아직 결제하지 않은 청구건
///   3) Recent Activity — 최근 5건 + "See all" 로 Finance 탭 이동
class MyWalletPage extends StatefulWidget {
  const MyWalletPage({super.key});

  @override
  State<MyWalletPage> createState() => _MyWalletPageState();
}

class _MyWalletPageState extends State<MyWalletPage> {
  User? _user;
  List<PendingPayment> _pending = const <PendingPayment>[];
  List<PaymentHistoryItem> _recent = const <PaymentHistoryItem>[];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _user = AuthService.currentUserNotifier.value;
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        AuthService.fetchProfile(),
        PaymentService.getMyPending(size: 20),
        PaymentService.getMyHistory(size: 5),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as User;
        _pending = results[1] as List<PendingPayment>;
        _recent = results[2] as List<PaymentHistoryItem>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: GradientLayout(
        child: Column(
          children: [
            CustomHeader(
              center: const Text(
                'My Wallet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
              showBack: true,
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }
    if (_hasError) {
      return _emptyState(
        title: 'Unable to load wallet.',
        subtitle: 'Pull down or try again later.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: green,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
        children: [
          _accountCard(),
          const SizedBox(height: 24),
          _pendingSection(),
          const SizedBox(height: 28),
          _recentSection(),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // 1) Account Info 카드
  // ───────────────────────────────────────────────────────────
  Widget _accountCard() {
    final acct = _user?.accountInfo?.trim();
    final hasAcct = acct != null && acct.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkgreen, green],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/icons/wallet.svg',
                  width: 9,
                  height: 9,
                  fit: BoxFit.none,
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Settlement Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/person_details');
                  _loadAll();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  hasAcct ? 'Edit' : 'Add',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            hasAcct ? acct : 'No account registered yet',
            style: TextStyle(
              color: hasAcct ? Colors.white : Colors.white.withOpacity(0.7),
              fontSize: hasAcct ? 18 : 14,
              fontWeight: FontWeight.w800,
              letterSpacing: hasAcct ? 1.0 : 0.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _user?.name ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // 2) Pending Payments
  // ───────────────────────────────────────────────────────────
  Widget _pendingSection() {
    final total = _pending.fold<int>(0, (sum, p) => sum + p.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Pending Payments',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: dark,
              ),
            ),
            const SizedBox(width: 8),
            if (_pending.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_pending.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: darkgreen,
                  ),
                ),
              ),
            const Spacer(),
            if (_pending.isNotEmpty)
              Text(
                '\$${total} AUD',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: darkgreen,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_pending.isEmpty)
          _infoBox(
            icon: Icons.verified_outlined,
            text: 'You\'re all caught up. No pending payments.',
          )
        else
          Column(
            children: List.generate(_pending.length, (i) {
              final p = _pending[i];
              return Padding(
                padding: EdgeInsets.only(bottom: i == _pending.length - 1 ? 0 : 10),
                child: _pendingCard(p),
              );
            }),
          ),
      ],
    );
  }

  Widget _pendingCard(PendingPayment p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _paymentColor(p.paymentType).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              _paymentIcon(p.paymentType),
              size: 20,
              color: _paymentColor(p.paymentType),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleFor(p.paymentType),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  p.targetAccount != null && p.targetAccount!.isNotEmpty
                      ? 'To · ${p.targetAccount}'
                      : 'Order ${p.orderId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: grey04,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${p.amount}',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: darkgreen,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // 3) Recent Activity
  // ───────────────────────────────────────────────────────────
  Widget _recentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: dark,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                goToFinanceTab();
              },
              style: TextButton.styleFrom(
                foregroundColor: darkgreen,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recent.isEmpty)
          _infoBox(
            icon: Icons.history,
            text: 'No transactions yet.',
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: List.generate(_recent.length, (i) {
                final t = _recent[i];
                return Column(
                  children: [
                    _recentRow(t),
                    if (i < _recent.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF2F2F2),
                        indent: 14,
                        endIndent: 14,
                      ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _recentRow(PaymentHistoryItem t) {
    final dateStr = t.transactionDate != null
        ? _formatTxDate(t.transactionDate!)
        : '';
    final isConfirmed = t.status == 'CONFIRMED';
    // IN(Mate paid) 거래는 짙은 초록색으로 강조, 나머지는 기존 로직 유지.
    final amountColor =
        t.isIncoming ? darkgreen : (isConfirmed ? darkgreen : grey04);
    final amountText = t.isIncoming
        ? '+ \$${t.amount}'
        : '- \$${t.amount}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _paymentColor(t.paymentType).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              _paymentIcon(t.paymentType),
              size: 18,
              color: _paymentColor(t.paymentType),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleFor(t.paymentType),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: grey04,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.status,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: isConfirmed ? green : grey03,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // helpers
  // ───────────────────────────────────────────────────────────
  Widget _infoBox({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: grey04,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: SvgPicture.asset(
              'assets/icons/wallet-line.svg',
              color: grey01,
              placeholderBuilder: (_) => const Icon(
                Icons.account_balance_wallet_outlined,
                size: 86,
                color: grey02,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: grey02,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: grey02,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(String paymentType) {
    switch (paymentType) {
      case 'RENT':
        return 'Rent';
      case 'UTILITY':
        return 'Utility';
      case 'DUTCH':
        return 'Split Bills';
      default:
        return paymentType;
    }
  }

  Color _paymentColor(String paymentType) {
    switch (paymentType) {
      case 'RENT':
        return green;
      case 'UTILITY':
        return darkgreen;
      case 'DUTCH':
        return const Color(0xFFD4A437);
      default:
        return grey04;
    }
  }

  IconData _paymentIcon(String paymentType) {
    switch (paymentType) {
      case 'RENT':
        return Icons.home_outlined;
      case 'UTILITY':
        return Icons.bolt_outlined;
      case 'DUTCH':
        return Icons.groups_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  String _formatTxDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hour12 = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${d.month}/${d.day} · ${two(hour12)}:${two(d.minute)}$ampm';
  }
}
