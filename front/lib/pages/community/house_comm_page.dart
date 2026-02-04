import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

// [중요] MyPage처럼 AuthService와 모델을 import 합니다.
import 'package:front/services/auth_service.dart';
import 'package:front/models/user_model.dart';

import '../../models/chat_room_list_model.dart';
import '../../services/chat_service.dart';

class HouseCommPage extends StatefulWidget {
  const HouseCommPage({super.key});

  @override
  State<HouseCommPage> createState() => _HouseCommPageState();
}

class _HouseCommPageState extends State<HouseCommPage> {
  int _houseSubTabIndex = 0; // 0: Notice, 1: Chat

  final ChatService _chatService = ChatService();
  List<ChatRoomListModel> _chatRooms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 채팅 탭이 기본이라면 여기서 로드, 아니라면 탭 전환 시 로드
    if (_houseSubTabIndex == 1) {
      _loadUserAndChats();
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '';
    try {
      // 1. 서버가 보내준 시간(23:24)을 UTC로 인식하도록 'Z'를 붙입니다.
      // (서버 시간: 23:24, 한국: 08:24, 호주: 10:24 or 11:24)
      String utcString = timeString.endsWith('Z')
          ? timeString
          : '${timeString}Z';

      // 2. UTC 시간을 내 폰의 시간대(호주)로 변환합니다.
      DateTime localDate = DateTime.parse(utcString).toLocal();

      // 3. 오늘인지 확인 후 포맷팅
      final DateTime now = DateTime.now();
      final bool isToday =
          localDate.year == now.year &&
          localDate.month == now.month &&
          localDate.day == now.day;

      if (isToday) {
        // 오늘이면 시간 표시 (예: 10:24 AM)
        return DateFormat('hh:mm a').format(localDate);
      } else {
        // 오늘이 아니면 날짜 표시 (예: 02/03)
        return DateFormat('MM/dd').format(localDate);
      }
    } catch (e) {
      // 에러 시 원본 문자열 반환
      return timeString;
    }
  }

  // [수정] MyPage 패턴 적용: AuthService로 유저 정보 가져온 뒤 채팅 목록 요청
  Future<void> _loadUserAndChats() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 1. AuthService를 통해 내 프로필 정보 가져오기 (mypage_page.dart와 동일 방식)
      User user = await AuthService.fetchProfile();

      // 2. 가져온 user의 memberId로 채팅 목록 API 호출
      final rooms = await _chatService.getMyChatRooms(user.memberId);

      if (mounted) {
        setState(() {
          _chatRooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [SliverToBoxAdapter(child: _buildHouseSubTabs())];
        },
        body: _buildContent(),
      ),
      floatingActionButton: _houseSubTabIndex == 0
          ? _buildFloatingButton()
          : null,
    );
  }

  Widget _buildHouseSubTabs() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1.2),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHouseSubTab('Notice', 'assets/icons/notice.svg', 0),
            SizedBox(width: 24),
            _buildHouseSubTab('Chat', 'assets/icons/chat.svg', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseSubTab(String label, String svgPath, int index) {
    final isSelected = _houseSubTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _houseSubTabIndex = index;
        });
        if (index == 1) {
          _loadUserAndChats(); // 탭 전환 시 데이터 로드
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SvgPicture.asset(
                  svgPath,
                  width: 18,
                  height: 18,
                  color: isSelected ? darkgreen : grey03,
                ),
                SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? darkgreen : grey03,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1.2,
            width: 175,
            decoration: BoxDecoration(
              color: isSelected ? darkgreen : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return _houseSubTabIndex == 0 ? _buildNoticeContent() : _buildChatContent();
  }

  Widget _buildNoticeContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/edit-note.svg',
            color: grey01,
            width: 72,
            height: 72,
          ),
          SizedBox(height: 16),
          Text(
            'No notices yet',
            style: TextStyle(
              fontSize: 14,
              color: grey02,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Check back later for updates',
            style: TextStyle(
              fontSize: 14,
              color: grey02,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: green));
    }

    if (_chatRooms.isEmpty) {
      return Center(
        child: Text(
          'No active chats.',
          style: TextStyle(
            fontSize: 14,
            color: grey02,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _chatRooms.length,
      itemBuilder: (context, index) {
        final item = _chatRooms[index];
        final unreadCount = 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: InkWell(
            onTap: () {
              // TODO: Navigate to chat room detail (pass item.roomId)
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      (item.profileImageUrl != null &&
                          item.profileImageUrl!.isNotEmpty)
                      ? NetworkImage(item.profileImageUrl!)
                      : null,
                  child:
                      (item.profileImageUrl == null ||
                          item.profileImageUrl!.isEmpty)
                      ? Text(
                          item.otherMemberName.isNotEmpty
                              ? item.otherMemberName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: grey03,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.otherMemberName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _formatTime(item.lastMessageTime),
                            style: TextStyle(
                              fontSize: 9,
                              color: grey02,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.lastMessage,
                              style: TextStyle(fontSize: 12, color: grey04),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            SizedBox(width: 6),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: green,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount.toString(),
                                  style: TextStyle(
                                    color: yellow,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: green,
          elevation: 4,
          child: SvgPicture.asset(
            'assets/icons/pencil.svg',
            width: 25,
            height: 25,
            color: yellow,
          ),
        ),
      ),
    );
  }
}
