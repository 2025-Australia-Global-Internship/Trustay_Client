import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/services/chat_service.dart';
import 'package:front/models/chat_message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/models/sharehouse_detail_model.dart';

class ChatRoomPage extends StatefulWidget {
  final int roomId;
  final int houseId;
  final String roomName;
  final int myMemberId;
  final String? otherProfileImageUrl;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    required this.houseId,
    required this.roomName,
    required this.myMemberId,
    this.otherProfileImageUrl,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final ChatSocketService _socket = ChatSocketService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isConnected = false;
  String? _token;

  // ── 숙소 정보 관리 변수 추가 ──
  SharehouseDetailModel? _houseDetail;
  bool _isHouseLoading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadToken();
    // 채팅 내역과 숙소 정보를 동시에 병렬로 로드합니다.
    await Future.wait([_loadChatHistory(), _loadHouseDetail()]);
    await _connectAndSubscribe();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  // ── houseId로 숙소 상세 정보 가져오기 ──
  Future<void> _loadHouseDetail() async {
    try {
      final detail = await SharehouseService.getSharehouseDetail(
        widget.houseId,
      );
      if (!mounted) return;
      setState(() {
        _houseDetail = detail;
        _isHouseLoading = false;
      });
    } catch (e) {
      print('❌ 숙소 정보 로드 실패: $e');
      if (!mounted) return;
      setState(() => _isHouseLoading = false);
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await ChatService.getChatHistory(
        widget.roomId,
        widget.myMemberId,
      );
      if (!mounted) return;
      setState(() {
        _messages = history;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('❌ 채팅 내역 로드 실패: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectAndSubscribe() async {
    if (_token == null) return;
    await _socket.connect(
      token: _token!,
      autoReconnect: true,
      onConnected: () {
        if (!mounted) return;
        setState(() => _isConnected = true);
        _socket.subscribeRoom(
          roomId: widget.roomId,
          onMessage: _handleIncomingMessage,
        );
      },
      onError: (msg) {
        if (!mounted) return;
        setState(() => _isConnected = false);
      },
    );
  }

  void _handleIncomingMessage(ChatMessageModel msg) {
    if (!mounted) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || !_isConnected) return;
    final ok = _socket.sendMessage(
      roomId: widget.roomId,
      senderId: widget.myMemberId,
      message: text,
      messageType: 'TEXT',
    );
    if (ok) _textController.clear();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _socket.unsubscribeRoom(widget.roomId);
    _socket.disconnect();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // 연한 회색 배경
      body: Column(
        children: [
          // 1. 상단 헤더 고정 (Stack 밖에 있으므로 완전히 고정되며 배경을 뚫지 못합니다)
          _buildChatHeader(),

          // 2. 중앙 영역 (하우스 카드와 채팅 리스트가 겹치는 영역)
          Expanded(
            child: Stack(
              children: [
                // 바닥에 깔리는 채팅 메시지 리스트
                Positioned.fill(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _scrollController,
                          // ★ 중요: 하우스 카드가 가리는 높이(약 110px)만큼만 상단 패딩을 줍니다.
                          // 헤더는 이제 Stack 밖에 있으므로 헤더 높이를 더해줄 필요가 없습니다.
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 110,
                            bottom: 16,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg.senderId == widget.myMemberId;

                            final showDateDivider =
                                index == 0 ||
                                !_isSameDay(
                                  _parseTime(_messages[index - 1].regTime),
                                  _parseTime(msg.regTime),
                                );

                            return Column(
                              children: [
                                if (showDateDivider)
                                  _buildDateDivider(msg.regTime),
                                _buildMessageBubble(msg, isMe),
                              ],
                            );
                          },
                        ),
                ),

                // 채팅 위에 고정되어 떠 있는 하우스 정보 카드
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildHouseInfoCard(),
                ),
              ],
            ),
          ),

          // 3. 하단 입력창 고정 (Stack 밖에 있으므로 완전히 고정됩니다)
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 뒤로가기
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  color: grey01,
                  onPressed: () => Navigator.pop(context),
                  icon: SvgPicture.asset(
                    'assets/icons/arrow_back.svg',
                    width: 25,
                    height: 25,
                    color: dark,
                  ),
                ),
              ),

              const SizedBox(width: 13),

              // 이름
              Expanded(
                child: Text(
                  widget.roomName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
              ),

              // 전화
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/icons/call.svg',
                    width: 29,
                    height: 29,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 영상통화
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/icons/video-call.svg',
                    width: 29,
                    height: 29,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHouseInfoCard() {
    if (_isHouseLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_houseDetail == null) return const SizedBox.shrink();

    // 데이터 바인딩 파트
    final title = _houseDetail!.title;
    final hostName = _houseDetail!.hostName;
    final hasImages = _houseDetail!.imageUrls.isNotEmpty;
    final houseThumbnail = hasImages ? _houseDetail!.imageUrls.first : "";
    final hostProfile = widget.otherProfileImageUrl ?? "";

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 11, 11, 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. 좌측 원형 상대방(호스트) 프로필 이미지
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFAFAFA),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: hostProfile.isNotEmpty
                    ? Image.network(hostProfile, fit: BoxFit.cover)
                    : const Icon(Icons.person, color: grey02),
              ),
            ),
            const SizedBox(width: 14),

            // 2. 중앙 타이틀 및 작성자 텍스트 정보 (리뷰 영역 제외)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: dark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Posted by $hostName",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: grey04,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // 3. 우측 쉐어하우스 썸네일 이미지 (모서리가 둥근 사각형)
            Container(
              width: 94,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: houseThumbnail.isNotEmpty
                    ? Image.network(houseThumbnail, fit: BoxFit.cover)
                    : const Icon(Icons.home, color: grey02),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 날짜 구분선 ──
  Widget _buildDateDivider(String? timeString) {
    final label = _formatDateLabel(timeString);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: Color(0xFFEBEBEB), thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: grey03,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: Color(0xFFEBEBEB), thickness: 1),
          ),
        ],
      ),
    );
  }

  // ── 메시지 버블 ──
  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 17,
                ),
                decoration: BoxDecoration(
                  color: isMe ? green : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(19),
                    topRight: const Radius.circular(19),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg.message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: isMe ? Colors.white : dark,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _formatTimeOnly(msg.regTime),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: grey04,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 입력창 ──
  Widget _buildInputArea() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68, maxHeight: 160),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(33),

            // 보더 제거
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // + 버튼
              Padding(
                padding: const EdgeInsets.only(left: 13),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: green, width: 1.1),
                  ),
                  child: const Icon(Icons.add, size: 20, color: green),
                ),
              ),

              // 세로 구분선
              Container(
                width: 1.1,
                height: 23,
                color: grey01,
                margin: const EdgeInsets.only(left: 15),
              ),

              // 입력창
              Expanded(
                child: TextField(
                  cursorColor: grey03,
                  controller: _textController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  enabled: _isConnected,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                  decoration: InputDecoration(
                    hintText: _isConnected ? "Write..." : "Connecting...",
                    hintStyle: const TextStyle(color: grey03, fontSize: 14),

                    // 높이 증가
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 18,
                    ),

                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),

              // 전송 버튼
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isConnected ? green : grey01,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 11, 12),
                      child: SvgPicture.asset(
                        'assets/icons/send.svg',
                        width: 18,
                        height: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 헬퍼: 시간 파싱 ──
  DateTime? _parseTime(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final utc = s.endsWith('Z') ? s : '${s}Z';
      return DateTime.parse(utc);
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateLabel(String? s) {
    final dt = _parseTime(s);
    if (dt == null) return '';
    final now = DateTime.now();
    if (_isSameDay(dt, now)) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(dt, yesterday)) return 'Yesterday';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  String _formatTimeOnly(String? s) {
    final dt = _parseTime(s);
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'am' : 'pm';
    return '$h:$m $period';
  }
}
