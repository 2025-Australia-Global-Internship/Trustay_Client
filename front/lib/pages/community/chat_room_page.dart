import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/services/chat_service.dart';
import 'package:front/models/chat_message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// 1) 토큰 → 2) 채팅 내역 → 3) 소켓 연결 + 구독
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
    if (_token == null) {
      print('❌ 토큰이 없어 소켓 연결 불가');
      return;
    }
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
    setState(() {
      _messages.add(msg);
    });
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

    if (ok) {
      _textController.clear();
    }
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
    // 구독 해제 + 소켓 종료 (자동 재연결도 중단)
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
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: hasOtherImage
                  ? NetworkImage(widget.otherProfileImageUrl!)
                        as ImageProvider
                  : const AssetImage('assets/icons/default.png'),
            ),
            const SizedBox(width: 10),
            Text(widget.roomName),
          ],
        ),
        backgroundColor: Color(0xFFFAFAFA),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 채팅 리스트
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == widget.myMemberId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),
          // 입력창
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? yellow
              : Colors.white, // yellow는 constants/colors.dart 정의값
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          border: isMe ? null : Border.all(color: grey01),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Text(
                msg.senderName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            if (!isMe) const SizedBox(height: 4),
            Text(
              msg.message,
              style: const TextStyle(fontSize: 14, color: dark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: _isConnected ? "메시지를 입력하세요..." : "연결 중...",
                  hintStyle: const TextStyle(color: grey03),
                  filled: true,
                  fillColor: grey01.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                enabled: _isConnected,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: _isConnected ? green : grey02,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
