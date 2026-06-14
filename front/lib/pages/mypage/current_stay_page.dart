import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/colors.dart';
import '../../models/contract_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/contract_service.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/current_stay_card.dart';
import '../../widgets/gradient_layout.dart';
import '../community/contract_view_page.dart';

/// "Current Stay" — 내가 (임대인 또는 임차인으로) 참여한 **ACTIVE** 계약 목록.
///
/// 디자인은 [ListingPage] 와 동일한 컨벤션을 따른다.
class CurrentStayPage extends StatefulWidget {
  const CurrentStayPage({super.key});

  @override
  State<CurrentStayPage> createState() => _CurrentStayPageState();
}

class _CurrentStayPageState extends State<CurrentStayPage> {
  List<ContractModel> _contracts = [];
  bool _isLoading = true;
  bool _hasError = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = AuthService.currentUserNotifier.value;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 화면 진입 시점 최신 프로필 확보 (memberId 가 비어 있을 가능성에 대비)
      _user ??= await AuthService.fetchProfile();
      final myId = _user?.memberId;

      final list = await ContractService.getMyContracts();
      if (!mounted) return;
      setState(() {
        // Current Stay 는 "현재 거주중인 곳" 이므로
        //   1) ACTIVE 상태이고
        //   2) 내가 세입자(tenant) 로 참여한 계약만 노출한다.
        // 내가 임대인(landlord) 으로 참여한 계약은 Listings 쪽 책임이라 제외.
        _contracts = list.where((c) {
          if (c.status != 'ACTIVE') return false;
          if (myId == null) return true; // memberId 불명일 땐 종전대로 모두 노출
          return c.isTenant(myId);
        }).toList();
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _openContract(ContractModel c) {
    final memberId = _user?.memberId;
    if (memberId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractViewPage(
          contractId: c.id,
          memberId: memberId,
        ),
      ),
    ).then((_) => _loadData());
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
                'Current Stay',
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
        title: 'Unable to load contracts.',
        subtitle: 'Pull down or try again later.',
      );
    }
    if (_contracts.isEmpty) {
      return _emptyState(
        title: 'No active stay yet.',
        subtitle: 'Once you sign a contract it will show up here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: green,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        itemCount: _contracts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 17),
        itemBuilder: (context, index) {
          final c = _contracts[index];
          return CurrentStayCard(
            contract: c,
            myMemberId: _user?.memberId ?? 0,
            onTap: () => _openContract(c),
          );
        },
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
              'assets/icons/house-user.svg',
              color: grey01,
              placeholderBuilder: (_) =>
                  const Icon(Icons.house, size: 86, color: grey02),
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
}
