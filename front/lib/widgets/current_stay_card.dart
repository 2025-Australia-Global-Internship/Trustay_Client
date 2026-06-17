// widgets/current_stay_card.dart
//
// "Current Stay" / "My Contracts" 화면에서 ContractModel 한 건을 보여주는 카드.
// 디자인 컨벤션은 MyListingCard 와 동일하게 맞췄다.

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/contract_model.dart';

class CurrentStayCard extends StatelessWidget {
  final ContractModel contract;
  final int myMemberId;
  final VoidCallback? onTap;

  /// 사용자가 세입자(tenant) 로서 이 매물에서 "나가기" 를 눌렀을 때.
  /// null 이면 버튼을 노출하지 않는다.
  final VoidCallback? onLeave;

  const CurrentStayCard({
    super.key,
    required this.contract,
    required this.myMemberId,
    this.onTap,
    this.onLeave,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return green;
      case 'SIGNED':
        return darkgreen;
      case 'EXPIRED':
        return grey04;
      case 'DRAFT':
      default:
        return grey03;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'ACTIVE';
      case 'SIGNED':
        return 'SIGNED';
      case 'EXPIRED':
        return 'EXPIRED';
      case 'DRAFT':
      default:
        return 'PENDING';
    }
  }

  String _formatAud(int? amount) {
    if (amount == null) return '-';
    // 1,000 단위 콤마. 통화는 AUD 통일.
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      buf.write(s[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write(',');
    }
    return '$buf AUD';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = contract.houseImageUrl ?? '';
    final title = contract.houseTitle?.trim().isNotEmpty == true
        ? contract.houseTitle!
        : 'Untitled listing';
    final address = contract.houseAddress?.trim().isNotEmpty == true
        ? contract.houseAddress!
        : 'Address unavailable';
    final period = '${contract.startDate ?? '-'} ~ ${contract.endDate ?? '-'}';
    final isLandlord = contract.isLandlord(myMemberId);
    final roleLabel = isLandlord
        ? 'You are the Landlord'
        : 'You are the Tenant';
    final counterparty = isLandlord
        ? contract.tenantName
        : contract.landlordName;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 100,
                        height: 80,
                        color: grey01,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image,
                                  color: grey02,
                                ),
                              )
                            : const Icon(Icons.home, color: grey02),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                contract.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: _statusColor(
                                  contract.status,
                                ).withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _statusLabel(contract.status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _statusColor(contract.status),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: dark,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: grey04),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('Role', roleLabel),
                      const SizedBox(height: 8),
                      _kv(isLandlord ? 'Tenant' : 'Landlord', counterparty),
                      const SizedBox(height: 8),
                      _kv('Period', period),
                      const SizedBox(height: 8),
                      _kv('Monthly', _formatAud(contract.monthlyRent)),
                    ],
                  ),
                ),
                if (!isLandlord && contract.isActive && onLeave != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: onLeave,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: darkgreen,
                        side: const BorderSide(color: darkgreen, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text(
                        'Leave homestay',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 11,
              color: grey03,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: dark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
