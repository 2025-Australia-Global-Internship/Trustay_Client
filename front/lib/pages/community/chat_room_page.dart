import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:front/services/chat_service.dart';
import 'package:front/models/chat_message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatRoomPage extends StatefulWidget {
  final int roomId;
  final String roomName;
  final int myMemberId;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.myMemberId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  StompClient? stompClient;
  List<ChatMessageModel> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  bool _isLoading = true;
  bool _isConnected = false;
  String? _token;

  // [중요] 서버의 WebSocketConfig와 정확히 일치하는 주소
  final String socketUrl = 'wss://trustay.digitalbasis.com/ws-stomp';
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _getToken();
    await _loadChatHistory();
    _connectWebSocket();
  }

  Future<void> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      // API를 통해 이전 대화 내역 불러오기
      // (ChatService에 해당 기능이 구현되어 있다고 가정)
      // List<ChatMessageModel> history = await _chatService.getChatHistory(widget.roomId);

      // setState(() {
      //   _messages = history;
      //   _isLoading = false;
      // });

      // 임시: 로딩 상태만 해제
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('채팅 내역 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  void _connectWebSocket() {
    if (_token == null) {
      print("❌ 토큰이 없어 소켓 연결 불가");
      return;
    }

    stompClient = StompClient(
      config: StompConfig(
        url: socketUrl,

        onConnect: _onConnect,

        // [핵심 1] 소켓 연결 시 에러 처리
        onWebSocketError: (dynamic error) => print("❌ 소켓 연결 에러: $error"),
        onStompError: (frame) => print("❌ STOMP 에러: ${frame.body}"),
        onDisconnect: (frame) => print("⚠️ 소켓 연결 끊김"),

        // [핵심 2] 400 에러 방지를 위한 헤더 설정
        // Handshake 단계에서는 Authorization을 뺍니다. (SecurityConfig에서 ignoring 설정됨)
        webSocketConnectHeaders: {'Origin': 'https://trustay.digitalbasis.com'},

        // [핵심 3] STOMP 연결 단계에서 토큰 인증
        stompConnectHeaders: {'Authorization': 'Bearer $_token'},
      ),
    );

    stompClient?.activate();
  }

  void _onConnect(StompFrame frame) {
    setState(() {
      _isConnected = true;
    });
    print("✅ 소켓 연결 성공!");

    // [구독] 해당 방의 메시지 구독
    stompClient?.subscribe(
      destination: '/sub/chat/room/${widget.roomId}',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final Map<String, dynamic> jsonBody = jsonDecode(frame.body!);
            final newMessage = ChatMessageModel.fromJson(jsonBody);

            setState(() {
              _messages.add(newMessage);
            });
            _scrollToBottom();
          } catch (e) {
            print("메시지 파싱 에러: $e");
          }
        }
      },
    );
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty || !_isConnected) return;

    final String messageContent = _textController.text;

    // [발송] 메시지 전송
    stompClient?.send(
      destination: '/pub/chat/send',
      body: jsonEncode({
        'roomId': widget.roomId,
        'senderId': widget.myMemberId,
        'message': messageContent,
        'messageType': 'TEXT', // 서버 Enum과 일치해야 함
      }),
      headers: {'Authorization': 'Bearer $_token'},
    );

    _textController.clear();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // 약간의 딜레이 후 스크롤 (렌더링 완료 대기)
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    stompClient?.deactivate();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        backgroundColor: Colors.white,
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
                msg.senderName ?? 'Unknown',
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
