import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/services/chat_service.dart';
import 'package:front/models/chat_message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatRoomPage extends StatefulWidget {
  final int roomId;
  final String roomName;
  final int myMemberId;
  final String? otherProfileImageUrl;

  const ChatRoomPage({
    super.key,
    required this.roomId,
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

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadToken();
    await _loadChatHistory();
    await _connectAndSubscribe();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
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
    final hasOtherImage =
        widget.otherProfileImageUrl != null &&
        widget.otherProfileImageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA), // 연한 회색 배경
      body: Column(
        children: [
          _buildChatHeader(),

          // ── 채팅 메시지 리스트 ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == widget.myMemberId;

                      // 날짜 구분선: 전 메시지와 날짜 다를 때
                      final showDateDivider =
                          index == 0 ||
                          !_isSameDay(
                            _parseTime(_messages[index - 1].regTime),
                            _parseTime(msg.regTime),
                          );

                      return Column(
                        children: [
                          if (showDateDivider) _buildDateDivider(msg.regTime),
                          _buildMessageBubble(msg, isMe),
                        ],
                      );
                    },
                  ),
          ),
          // ── 입력창 ──
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
                    fontSize: 16,
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

            const SizedBox(height: 4),

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
                height: 22,
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
      return DateTime.parse(utc).toLocal();
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
