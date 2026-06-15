import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/colors.dart';
import '../../models/contract_model.dart';
import '../../services/auth_service.dart';
import '../../services/contract_service.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/gradient_layout.dart';
import '../community/contract_view_page.dart';

/// "My Contracts" — 내가 참여한 계약(서명 완료/진행 중) 목록과
/// 저장된 PDF(서명 완료본 또는 첨부 스캔본)를 빠르게 열람할 수 있는 화면.
class MyContractsPage extends StatefulWidget {
  const MyContractsPage({super.key});

  @override
  State<MyContractsPage> createState() => _MyContractsPageState();
}

class _MyContractsPageState extends State<MyContractsPage> {
  List<ContractModel> _contracts = [];
  bool _loading = true;
  bool _hasError = false;
  String? _errorMessage;

  // 페이징 상태
  static const int _pageSize = 10;
  int _nextPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 250) {
      _loadMore();
    }
  }

  /// 정렬 헬퍼: regTime 내림차순.
  void _sortByRegTimeDesc(List<ContractModel> list) {
    list.sort((a, b) {
      final ar = a.regTime ?? '';
      final br = b.regTime ?? '';
      return br.compareTo(ar);
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = null;
      _nextPage = 0;
      _hasMore = true;
    });
    try {
      final list =
          await ContractService.getMyContracts(page: 0, size: _pageSize);
      _sortByRegTimeDesc(list);
      if (!mounted) return;
      setState(() {
        _contracts = list;
        _nextPage = 1;
        _hasMore = list.length >= _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  /// 다음 페이지 로드 후 list에 append. 서버가 이미 정렬해 보내주지만
  /// 안전을 위해 로컬에서도 다시 한 번 정렬한다.
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _loading) return;
    setState(() => _isLoadingMore = true);
    try {
      final next = await ContractService.getMyContracts(
        page: _nextPage,
        size: _pageSize,
      );
      if (!mounted) return;
      final merged = <ContractModel>[..._contracts, ...next];
      _sortByRegTimeDesc(merged);
      setState(() {
        _contracts = merged;
        _nextPage += 1;
        _hasMore = next.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the PDF externally.")),
      );
    }
  }

  Future<void> _openDetail(ContractModel c) async {
    final memberId = AuthService.currentUserNotifier.value?.memberId;
    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractViewPage(
          contractId: c.id,
          memberId: memberId,
        ),
      ),
    );
    // 뒤로 돌아왔을 때 서명 상태가 바뀌었을 수 있으므로 재조회.
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: GradientLayout(
        child: Column(
          children: [
            const CustomHeader(
              center: Text(
                'My Contracts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
              showBack: true,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: green,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }
    if (_hasError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage ?? 'Failed to load contracts.',
                  style: const TextStyle(color: grey03, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_contracts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/contract-fill.svg',
                  width: 64,
                  height: 64,
                  colorFilter: const ColorFilter.mode(grey01, BlendMode.srcIn),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No contracts yet.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: grey02,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your saved contracts will show up here.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: grey02,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 마지막 항목 다음에 로딩/끝 안내를 보여주기 위한 tail 슬롯.
    final int extraTail = (_isLoadingMore || !_hasMore) ? 1 : 0;
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      itemCount: _contracts.length + extraTail,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= _contracts.length) {
          if (_isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: green,
                  ),
                ),
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'No more contracts',
                style: TextStyle(fontSize: 12, color: grey03),
              ),
            ),
          );
        }
        return _ContractCard(
          contract: _contracts[index],
          onTap: () => _openDetail(_contracts[index]),
          onOpenPdf: _openPdf,
        );
      },
    );
  }
}

class _ContractCard extends StatelessWidget {
  final ContractModel contract;
  final VoidCallback onTap;
  final Future<void> Function(String url) onOpenPdf;

  const _ContractCard({
    required this.contract,
    required this.onTap,
    required this.onOpenPdf,
  });

  @override
  Widget build(BuildContext context) {
    final c = contract;
    final pdfUrl = c.signedPdfUrl ?? c.paperContractPdfUrl;
    final pdfLabel = c.signedPdfUrl != null
        ? 'Open signed PDF'
        : (c.paperContractPdfUrl != null ? 'Open scan PDF' : null);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumbnail(imageUrl: c.houseImageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.houseTitle?.isNotEmpty == true
                                    ? c.houseTitle!
                                    : 'Untitled listing',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: dark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(status: c.status),
                          ],
                        ),
                        if ((c.houseAddress ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            c.houseAddress!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: grey04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${c.startDate ?? '-'} ~ ${c.endDate ?? '-'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: dark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.monthlyRent == null
                              ? 'Monthly: -'
                              : 'Monthly ${_money(c.monthlyRent!)} AUD'
                                  '${c.deposit != null ? '  ·  Deposit ${_money(c.deposit!)} AUD' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: grey04,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (pdfUrl != null && pdfLabel != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkgreen,
                      side: const BorderSide(color: darkgreen),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => onOpenPdf(pdfUrl),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: Text(
                      pdfLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_bottom,
                          size: 14, color: grey03),
                      SizedBox(width: 6),
                      Text(
                        'PDF will be generated after both parties sign.',
                        style: TextStyle(
                          fontSize: 11,
                          color: grey03,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
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

class _Thumbnail extends StatelessWidget {
  final String? imageUrl;
  const _Thumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF1F1F1),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported,
                      size: 22, color: grey02),
                ),
              )
            : Container(
                color: const Color(0xFFF1F1F1),
                alignment: Alignment.center,
                child: const Icon(Icons.home_outlined,
                    size: 22, color: grey02),
              ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
