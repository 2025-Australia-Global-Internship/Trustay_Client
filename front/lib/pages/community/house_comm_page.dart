import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HouseCommPage extends StatefulWidget {
  const HouseCommPage({super.key});

  @override
  State<HouseCommPage> createState() => _HouseCommPageState();
}

class _HouseCommPageState extends State<HouseCommPage> {
  int _houseSubTabIndex = 0; // 0: Notice, 1: Chat

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
          ? _buildFloatingButton() // Notice일 때만 표시
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
          Icon(Icons.edit_note, size: 64, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            '아직 공지사항이 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            '새로운 공지사항을 작성해보세요',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent() {
    final chatItems = List.generate(
      5,
      (index) => {
        'name': index == 0 ? 'Stella' : 'User ${index + 1}',
        'message': 'Lorem ipsum dolor sit amet. Non at...',
        'time': index == 0 ? '12:40 AM' : '${9 + index}:30 AM',
        'unread': index == 0 ? 2 : 0,
      },
    );

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: chatItems.length,
      itemBuilder: (context, index) {
        final item = chatItems[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 아바타
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey[300],
                child: Text(
                  item['name'].toString()[0],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: grey03,
                  ),
                ),
              ),
              SizedBox(width: 13),
              // 메시지 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름 + 시간
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['name'].toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item['time'].toString(),
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
                            item['message'].toString(),
                            style: TextStyle(fontSize: 12, color: grey04),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if ((item['unread'] as int) > 0) ...[
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
                                item['unread'].toString(),
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
