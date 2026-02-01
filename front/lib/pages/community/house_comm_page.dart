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
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [SliverToBoxAdapter(child: _buildHouseSubTabs())];
        },
        body: _buildContent(),
      ),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  Widget _buildHouseSubTabs() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
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
      10,
      (index) => {
        'name': index == 0 ? 'Stella' : 'User ${index + 1}',
        'message': 'Lorem ipsum dolor sit amet. Non at...',
        'time': index == 0 ? '12:40 AM' : '${9 + index}:30 AM',
        'unread': index == 0 ? 2 : 0,
      },
    );

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: chatItems.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, indent: 72, endIndent: 16),
      itemBuilder: (context, index) {
        final item = chatItems[index];
        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
            child: Text(
              item['name'].toString()[0],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item['name'].toString(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                item['time'].toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          subtitle: Text(
            item['message'].toString(),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: item['unread'] as int > 0
              ? Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item['unread'].toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFloatingButton() {
    return FloatingActionButton(
      onPressed: () {
        // Notice / Chat 새 글 작성
      },
      backgroundColor: Color(0xFF7D9B5B),
      elevation: 4,
      child: Icon(Icons.edit, color: Colors.white, size: 24),
    );
  }
}
