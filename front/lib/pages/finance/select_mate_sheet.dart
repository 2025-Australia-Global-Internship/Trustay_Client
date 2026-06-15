import 'package:flutter/material.dart';

import 'package:front/constants/colors.dart';
import 'package:front/models/chat_room_list_model.dart';

/// "Select Mate" 바텀 시트 (Personal_Details 디자인).
///
/// - 채팅 상대 목록 중에서 다중 선택해 메이트로 추가한다.
/// - 별 아이콘 토글로 선택 상태를 표시한다.
/// - 하단 "Add Mate" 버튼을 누르면 선택된 목록을 `pop` 으로 반환.
class SelectMateSheet extends StatefulWidget {
  final List<ChatRoomListModel> candidates;
  final List<ChatRoomListModel> initialSelected;

  const SelectMateSheet({
    super.key,
    required this.candidates,
    this.initialSelected = const [],
  });

  @override
  State<SelectMateSheet> createState() => _SelectMateSheetState();
}

class _SelectMateSheetState extends State<SelectMateSheet> {
  late final Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = {for (final m in widget.initialSelected) m.otherMemberId};
  }

  void _toggle(ChatRoomListModel m) {
    setState(() {
      if (_selectedIds.contains(m.otherMemberId)) {
        _selectedIds.remove(m.otherMemberId);
      } else {
        _selectedIds.add(m.otherMemberId);
      }
    });
  }

  void _confirm() {
    final selected = widget.candidates
        .where((m) => _selectedIds.contains(m.otherMemberId))
        .toList();
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: mq.viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: grey01,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'Select Mate',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: widget.candidates.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'No people to choose from yet.\nStart a chat first.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: grey03,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: widget.candidates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final m = widget.candidates[index];
                          final selected =
                              _selectedIds.contains(m.otherMemberId);
                          final hasImg = m.profileImageUrl != null &&
                              m.profileImageUrl!.isNotEmpty;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _toggle(m),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFFF9D6)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: hasImg
                                        ? NetworkImage(m.profileImageUrl!)
                                            as ImageProvider
                                        : const AssetImage(
                                            'assets/icons/default.png'),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      m.otherMemberName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: dark,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    selected ? Icons.star : Icons.star_border,
                                    color: selected ? yellow : grey01,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: dark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Add Mate',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: dark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
