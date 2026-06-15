import 'dart:io';

import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/services/chat_service.dart';
import 'package:front/models/chat_message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/services/sharehouse_service.dart';
import 'package:front/models/sharehouse_detail_model.dart';
import 'package:front/pages/mypage/sharehouse_detail_page.dart';
import 'package:image_picker/image_picker.dart';

import 'contract_scan_upload_page.dart';
import 'contract_detail_page.dart';
import 'contract_view_page.dart';

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
  bool _isMenuExpanded = false; // 플러스 버튼 메뉴 오픈 여부
  String? _token;

  // ── 숙소 정보 관리 변수 추가 ──
  SharehouseDetailModel? _houseDetail;
  bool _isHouseLoading = true;

  // ── 이미지 전송 관련 ──
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  // ── 메시지 페이징 (위로 스크롤 시 더 오래된 메시지 로드) ──
  static const int _historyPageSize = 15;
  int _historyNextPage = 0;
  bool _historyHasMore = true;
  bool _isLoadingMoreHistory = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      // 첫 페이지(가장 최근 N개)
      final history = await ChatService.getChatHistory(
        widget.roomId,
        widget.myMemberId,
        page: 0,
        size: _historyPageSize,
      );
      if (!mounted) return;
      setState(() {
        _messages = history;
        _historyNextPage = 1;
        _historyHasMore = history.length >= _historyPageSize;
        _isLoading = false;
      });
      // 첫 진입은 애니메이션 없이 즉시 가장 최근 메시지로.
      _scrollToBottom(animate: false);
    } catch (e) {
      print('❌ 채팅 내역 로드 실패: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// 더 오래된 메시지 페이지를 가져와 리스트 **앞쪽**에 prepend.
  /// 화면 점프를 막기 위해 prepend 후 동일한 메시지가 보이도록 스크롤 위치를 보정한다.
  Future<void> _loadMoreHistory() async {
    if (_isLoadingMoreHistory || !_historyHasMore || _isLoading) return;
    setState(() => _isLoadingMoreHistory = true);
    try {
      final older = await ChatService.getChatHistory(
        widget.roomId,
        widget.myMemberId,
        page: _historyNextPage,
        size: _historyPageSize,
      );
      if (!mounted) return;
      if (older.isEmpty) {
        setState(() {
          _historyHasMore = false;
          _isLoadingMoreHistory = false;
        });
        return;
      }

      // 현재 스크롤 위치 보정 기준점.
      final beforeMax = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : 0.0;
      final beforePixels = _scrollController.hasClients
          ? _scrollController.position.pixels
          : 0.0;

      setState(() {
        _messages.insertAll(0, older);
        _historyNextPage += 1;
        _historyHasMore = older.length >= _historyPageSize;
        _isLoadingMoreHistory = false;
      });

      // 새 컨텐츠가 위에 추가됐으니, 사용자가 보고 있던 메시지가 그대로 보이도록
      // (maxScrollExtent 증가분 만큼) 스크롤을 아래로 밀어준다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final delta = _scrollController.position.maxScrollExtent - beforeMax;
        if (delta > 0) {
          _scrollController.jumpTo(beforePixels + delta);
        }
      });
    } catch (e) {
      print('❌ 이전 메시지 로드 실패: $e');
      if (!mounted) return;
      setState(() => _isLoadingMoreHistory = false);
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

  /// 메시지 리스트를 맨 아래(가장 최신)로 이동.
  /// - [animate]: false 면 즉시 점프(첫 진입에 사용), true 면 부드럽게 스크롤.
  ///
  /// 처음 로드 직후엔 ListView 가 아직 컨트롤러에 attach 되기 전이라
  /// `hasClients` 가 false 일 수 있다. 따라서 다음 프레임이 그려진 뒤에 실행한다.
  /// 이미지 등으로 layout 이 한 번 더 늘어나는 경우를 위해 한 프레임 더 양보한다.
  void _scrollToBottom({bool animate = true}) {
    void jump() {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      jump();
      // 이미지 로드 등으로 maxScrollExtent 가 살짝 더 늘어나는 케이스를 위해
      // 다음 프레임에 한 번 더 보정한다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        jump();
      });
    });
  }

  @override
  void dispose() {
    _socket.unsubscribeRoom(widget.roomId);
    _socket.disconnect();
    _textController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 스크롤이 위쪽 ~80px 이내에 닿으면 더 오래된 페이지를 prefetch.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels <= 80) {
      _loadMoreHistory();
    }
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

                // 더 오래된 메시지를 가져오는 동안 표시되는 작은 인디케이터.
                // 하우스 카드 바로 아래에 떠 있다.
                if (_isLoadingMoreHistory)
                  const Positioned(
                    top: 116,
                    left: 0,
                    right: 0,
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
          height: 70,
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
                    width: 22,
                    height: 22,
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
                    width: 26,
                    height: 26,
                  ),
                ),
              ),

              const SizedBox(width: 7),

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
                    width: 26,
                    height: 26,
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openHouseDetail,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
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
                width: 50,
                height: 50,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: dark,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      "Posted by $hostName",
                      style: const TextStyle(
                        fontSize: 11,
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
                width: 84,
                height: 74,
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
      ),
    );
  }

  // 하우스 카드 탭 시 쉐어하우스 상세 페이지로 이동
  void _openHouseDetail() {
    if (_isHouseLoading || _houseDetail == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharehouseDetailPage(houseId: widget.houseId),
      ),
    );
  }

  // 플러스 메뉴 아이템 클릭 디스패치
  void _handleMenuItemTap(String label) {
    switch (label) {
      case 'Image':
        _pickAndSendImage(ImageSource.gallery);
        break;
      case 'Camera':
        _pickAndSendImage(ImageSource.camera);
        break;
      case 'Contract':
        _openContractFlow();
        break;
      default:
        print("$label 클릭됨 — 아직 구현되지 않음");
    }
  }

  /// "+" 메뉴 → Contract.
  /// 종이 계약서를 스캔해서 채팅방에 공유하면 OCR + PDF + CONTRACT 메시지가 자동 broadcast 된다.
  /// 그 다음 양측 합의 후 계약 제안/서명 흐름은 메시지 버블에서 이어진다.
  Future<void> _openContractFlow() async {
    setState(() => _isMenuExpanded = false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractScanUploadPage(
          roomId: widget.roomId,
          memberId: widget.myMemberId,
        ),
      ),
    );
    // 업로드 성공 시 서버가 CONTRACT 메시지를 broadcast → STOMP 구독 콜백이 자동으로 받음.
  }

  /// 현재 사용자가 이 매물(=채팅방)에서 어떤 역할로 계약에 참여하는지.
  /// `LANDLORD` = 매물의 호스트, 그 외는 `TENANT`.
  /// 매물 정보가 아직 로드되지 않았으면 TENANT 로 가정 (드물게 발생할 수 있으므로 안전한 기본값).
  String get _myContractRole {
    final hostId = _houseDetail?.hostId;
    if (hostId != null && hostId == widget.myMemberId) return 'LANDLORD';
    return 'TENANT';
  }

  /// CONTRACT 메시지(스캔본) 탭 → 스캔본 상세
  void _openPaperContractDetail(int documentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractDetailPage(
          documentId: documentId,
          memberId: widget.myMemberId,
          roomId: widget.roomId,
          iAm: _myContractRole,
        ),
      ),
    );
  }

  /// CONTRACT_PROPOSAL / CONTRACT_SIGNED 메시지 탭 → 계약 상세
  void _openContractView(int contractId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractViewPage(
          contractId: contractId,
          memberId: widget.myMemberId,
        ),
      ),
    );
  }

  // 갤러리/카메라에서 이미지 선택 → 채팅 이미지 업로드 REST 호출
  //
  // 백엔드가 IMAGE 타입 ChatMessage 로 저장 후 STOMP 구독 채널에
  // 자동 브로드캐스트하기 때문에, 클라이언트는 별도의 WebSocket SEND 없이
  // 기존 구독 콜백(_handleIncomingMessage)으로 새 메시지를 수신한다.
  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_isUploadingImage) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) return; // 사용자가 취소

      // 선택 후 메뉴는 자동으로 접어준다
      if (mounted) {
        setState(() {
          _isMenuExpanded = false;
          _isUploadingImage = true;
        });
      }

      await ChatService.sendImageMessage(
        roomId: widget.roomId,
        senderId: widget.myMemberId,
        imageFile: File(picked.path),
      );
      // 응답으로도 ChatMessageRes 가 내려오지만 STOMP 가 같은 메시지를
      // 자동 브로드캐스트하므로 중복을 피하기 위해 응답은 무시한다.
    } catch (e) {
      print('❌ 이미지 전송 실패: $e');
      _showSnack('이미지 전송에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // IMAGE 메시지 탭 시 전체 화면 미리보기
  void _showImagePreview(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (_) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
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
    final type = msg.messageType;
    final BorderRadius bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(19),
      topRight: const Radius.circular(19),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    final Widget body;
    final double maxWidthFactor;
    if (type == 'IMAGE') {
      body = _buildImageBubble(msg, bubbleRadius);
      maxWidthFactor = 0.65;
    } else if (type == 'CONTRACT') {
      body = _buildContractScanBubble(msg, isMe, bubbleRadius);
      maxWidthFactor = 0.78;
    } else if (type == 'CONTRACT_PROPOSAL') {
      body = _buildContractProposalBubble(msg, isMe, bubbleRadius);
      maxWidthFactor = 0.78;
    } else if (type == 'CONTRACT_SIGNED') {
      body = _buildContractSignedBubble(msg, isMe, bubbleRadius);
      maxWidthFactor = 0.78;
    } else {
      body = _buildTextBubble(msg, isMe, bubbleRadius);
      maxWidthFactor = 0.65;
    }

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
                maxWidth: MediaQuery.of(context).size.width * maxWidthFactor,
              ),
              child: body,
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

  /// CONTRACT 타입 — 종이 계약서 스캔본(PDF) 도착 카드
  Widget _buildContractScanBubble(
    ChatMessageModel msg,
    bool isMe,
    BorderRadius radius,
  ) {
    return _ContractCardBase(
      radius: radius,
      isMe: isMe,
      onTap: () {
        if (msg.paperContractDocumentId != null) {
          _openPaperContractDetail(msg.paperContractDocumentId!);
        }
      },
      icon: Icons.document_scanner_outlined,
      title: 'Contract scan shared',
      subtitle: 'A scanned contract (OCR + PDF) is ready to review.',
      ctaLabel: 'Open',
    );
  }

  /// CONTRACT_PROPOSAL 타입 — 한쪽이 보낸 계약 조건 제안 카드
  Widget _buildContractProposalBubble(
    ChatMessageModel msg,
    bool isMe,
    BorderRadius radius,
  ) {
    return _ContractCardBase(
      radius: radius,
      isMe: isMe,
      onTap: () {
        if (msg.contractId != null) _openContractView(msg.contractId!);
      },
      icon: Icons.handshake_outlined,
      title: 'Contract proposal',
      subtitle: msg.message,
      ctaLabel: isMe ? 'Review your proposal' : 'Review and sign',
    );
  }

  /// CONTRACT_SIGNED 타입 — 양측 서명 완료 알림 카드
  Widget _buildContractSignedBubble(
    ChatMessageModel msg,
    bool isMe,
    BorderRadius radius,
  ) {
    return _ContractCardBase(
      radius: radius,
      isMe: isMe,
      highlight: true,
      onTap: () {
        if (msg.contractId != null) _openContractView(msg.contractId!);
      },
      icon: Icons.verified,
      title: 'Contract signed',
      subtitle: 'Both parties have signed. The contract is now active.',
      ctaLabel: 'View signed contract',
    );
  }

  Widget _buildTextBubble(
    ChatMessageModel msg,
    bool isMe,
    BorderRadius radius,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
      decoration: BoxDecoration(
        color: isMe ? green : Colors.white,
        borderRadius: radius,
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
    );
  }

  Widget _buildImageBubble(ChatMessageModel msg, BorderRadius radius) {
    return GestureDetector(
      onTap: () => _showImagePreview(msg.message),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          color: const Color(0xFFFAFAFA),
          constraints: const BoxConstraints(
            minWidth: 120,
            minHeight: 120,
            maxHeight: 240,
          ),
          child: Image.network(
            msg.message,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                width: 180,
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: green,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stack) => const SizedBox(
              width: 180,
              height: 180,
              child: Center(
                child: Icon(Icons.broken_image, color: grey02, size: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 입력창 ──
  Widget _buildInputArea() {
    return Container(
      color: Colors.transparent, // 배경을 흰색으로 고정하여 메시지가 가려지도록 설정
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 기존 입력창 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SafeArea(
              top: false,
              bottom: !_isMenuExpanded, // 메뉴가 열리면 하단 SafeArea 여백을 메뉴 아래로 양보
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 68,
                  maxHeight: 155,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(43),
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
                    // + 버튼 (클릭 시 토글 및 애니메이션 효과)
                    Padding(
                      padding: const EdgeInsets.only(left: 13),
                      child: GestureDetector(
                        onTap: _isUploadingImage
                            ? null
                            : () {
                                setState(() {
                                  _isMenuExpanded = !_isMenuExpanded;
                                });
                              },
                        child: AnimatedRotation(
                          turns: 0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: green, width: 1.1),
                            ),
                            child: _isUploadingImage
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: green,
                                    ),
                                  )
                                : const Icon(Icons.add, size: 20, color: green),
                          ),
                        ),
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
                          hintStyle: const TextStyle(
                            color: grey03,
                            fontSize: 14,
                          ),
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
          ),

          // ── 플러스 버튼 누르면 펼쳐지는 하단 확장 메뉴판 ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: _isMenuExpanded ? 250 : 0,
            decoration: const BoxDecoration(color: Colors.white),
            child: FadeTransition(
              opacity: AlwaysStoppedAnimation(_isMenuExpanded ? 1.0 : 0.0),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _buildExpandedMenu(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedMenu() {
    // 메뉴 아이템 데이터 구조화
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': 'assets/icons/image.svg',
        'label': 'Image',
        'defaultIcon': Icons.image,
      },
      {
        'icon': 'assets/icons/camera.svg',
        'label': 'Camera',
        'defaultIcon': Icons.camera_alt,
      },
      {
        'icon': 'assets/icons/contract-fill.svg',
        'label': 'Contract',
        'defaultIcon': Icons.description,
      },
      {
        'icon': 'assets/icons/wallet.svg',
        'label': 'Wallet',
        'defaultIcon': Icons.account_balance_wallet,
      },
      {
        'icon': 'assets/icons/schedule.svg',
        'label': 'Schedule',
        'defaultIcon': Icons.calendar_today,
      },
      {
        'icon': 'assets/icons/map-fill.svg',
        'label': 'Location',
        'defaultIcon': Icons.location_on,
      },
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 한 줄에 4개씩 배치
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            mainAxisExtent: 85, // 아이템 하나의 세로 길이 제한
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];

            final isWallet = item['label'] == 'Wallet';
            final isMap = item['label'] == 'Location';

            return GestureDetector(
              onTap: () => _handleMenuItemTap(item['label'] as String),
              child: Column(
                children: [
                  // 원형 아이콘 배경
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFAFA),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        item['icon'],
                        width: isMap ? 24 : 22,
                        height: isMap ? 24 : 22,
                        color: isWallet ? darkgreen : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 하단 라벨 텍스트
                  Text(
                    item['label'],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: darkgreen,
                    ),
                  ),
                ],
              ),
            );
          },
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

/// 계약 관련 메시지(CONTRACT, CONTRACT_PROPOSAL, CONTRACT_SIGNED) 의 공통 카드 위젯.
/// 일반 텍스트/이미지 버블과 구분되도록 흰색 카드 + 아이콘 + 제목/설명 + CTA 한 줄로 통일한다.
class _ContractCardBase extends StatelessWidget {
  final BorderRadius radius;
  final bool isMe;
  final bool highlight;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaLabel;

  const _ContractCardBase({
    required this.radius,
    required this.isMe,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = highlight ? const Color(0xFFEFF6E5) : Colors.white;
    final Color accent = highlight ? darkgreen : darkgreen;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: grey04,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    ctaLabel,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
