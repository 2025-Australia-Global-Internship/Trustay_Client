import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:front/constants/colors.dart';
import 'package:front/models/post_comment_model.dart';
import 'package:front/models/post_model.dart';
import 'package:front/models/user_model.dart';
import 'package:front/services/post_service.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';

/// PDF #2 — Notice Board (단일 공지 상세 + 댓글).
///
/// 진입 시 `postId` 만 받아 상세 + 댓글 목록을 동시에 가져온다.
/// 백엔드는 댓글 soft delete 를 지원하며, **작성자 본인만** 자신의 댓글을 삭제할 수 있다.
/// [isHost] 는 정보용으로만 들고 있으며(향후 확장 대비) 댓글 권한과는 무관하다.
class NoticeDetailPage extends StatefulWidget {
  final int postId;
  final User? currentUser;
  final bool isHost;

  const NoticeDetailPage({
    super.key,
    required this.postId,
    this.currentUser,
    this.isHost = false,
  });

  @override
  State<NoticeDetailPage> createState() => _NoticeDetailPageState();
}

class _NoticeDetailPageState extends State<NoticeDetailPage> {
  PostModel? _post;
  List<PostCommentModel> _comments = const [];

  bool _loading = true;
  bool _posting = false;
  String? _error;

  final TextEditingController _commentCtl = TextEditingController();
  final FocusNode _commentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 데이터 로딩
  // ---------------------------------------------------------------------------
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        PostService.getPost(widget.postId),
        PostService.getComments(widget.postId),
      ]);

      if (!mounted) return;
      setState(() {
        _post = results[0] as PostModel;
        _comments = results[1] as List<PostCommentModel>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '공지를 불러오지 못했어요.';
        _loading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtl.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      final created = await PostService.createComment(
        postId: widget.postId,
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, created];
        _commentCtl.clear();
        _posting = false;
      });
      _commentFocus.unfocus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    }
  }

  Future<void> _confirmDeleteComment(PostCommentModel c) async {
    final user = widget.currentUser;
    // 백엔드 규칙: 작성자 본인만 삭제 가능 (soft delete).
    final canDelete =
        user != null && c.authorId == user.memberId && !c.isDeleted;
    if (!canDelete) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text(
          'Other people will see "(This comment was deleted.)" instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await PostService.deleteComment(postId: widget.postId, commentId: c.id);
      if (!mounted) return;
      // soft delete 후 목록 새로고침 — 백엔드에서 placeholder 본문으로 다시 받아온다.
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    return msg.replaceFirst('Exception: ', '');
  }

  // ---------------------------------------------------------------------------
  // 포맷팅
  // ---------------------------------------------------------------------------
  DateTime? _parseLocal(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final raw = iso.endsWith('Z') ? iso : '${iso}Z';
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _fmtDate(String? iso) {
    final dt = _parseLocal(iso);
    if (dt == null) return '';
    return DateFormat('dd MMM, yyyy').format(dt);
  }

  String _fmtTime(String? iso) {
    final dt = _parseLocal(iso);
    if (dt == null) return '';
    // 'hh:mm a' 는 12시간 + AM/PM 표기 (예: 05:31 PM)
    return DateFormat('hh:mm a').format(dt);
  }

  String _timeAgo(String? iso) {
    final dt = _parseLocal(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd MMM').format(dt);
  }

  // ---------------------------------------------------------------------------
  // 빌드
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // GradientLayout 은 상단 180px 만 그라데이션을 그리므로,
      // 나머지 영역이 검게 비치지 않도록 Scaffold 배경을 light cream 으로 깐다.
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      body: GradientLayout(
        child: Column(
          children: [
            const CustomHeader(
              center: Text(
                'Notice Board',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
            ),
            Expanded(child: _buildBody()),
            _buildCommentComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }
    if (_error != null || _post == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error ?? '공지를 찾을 수 없어요.',
            style: const TextStyle(fontSize: 14, color: grey02),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: green,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          _buildPostBlock(_post!),
          const SizedBox(height: 16),
          Container(height: 1, color: grey01.withOpacity(0.7)),
          const SizedBox(height: 20),
          Text(
            'Comments (${_comments.isEmpty ? '0' : _comments.length.toString().padLeft(2, '0')})',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
          const SizedBox(height: 25),
          if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Be the first to comment',
                  style: TextStyle(
                    fontSize: 13,
                    color: grey03,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ..._comments.map(_buildCommentItem),
        ],
      ),
    );
  }

  Widget _buildPostBlock(PostModel post) {
    final bool hasAvatar =
        post.profileImageUrl != null && post.profileImageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: Colors.grey[300],
              backgroundImage: hasAvatar
                  ? NetworkImage(post.profileImageUrl!) as ImageProvider
                  : const AssetImage('assets/icons/default.png'),
            ),
            const SizedBox(width: 12),
            Text(
              post.authorName.isEmpty ? 'Host' : post.authorName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: dark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (post.title.isNotEmpty) ...[
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
          const SizedBox(height: 5),
        ],
        Text(
          post.content,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: dark,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (post.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.network(
                post.imageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: grey01,
                  child: const Center(child: Icon(Icons.image, color: grey02)),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            SvgPicture.asset(
              'assets/icons/calendar.svg',
              width: 14,
              height: 14,
              color: grey03,
            ),
            const SizedBox(width: 6),
            Text(
              _fmtDate(post.regTime),
              style: const TextStyle(
                fontSize: 11,
                color: grey03,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 14),
            const Icon(Icons.access_time, size: 17, color: grey02),
            const SizedBox(width: 4),
            Text(
              _timeAgo(post.regTime),
              style: const TextStyle(
                fontSize: 11,
                color: grey03,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentItem(PostCommentModel c) {
    final user = widget.currentUser;
    final bool isMine = user != null && c.authorId == user.memberId;
    final bool canDelete = isMine && !c.isDeleted;
    final bool hasAvatar =
        c.authorProfileImageUrl != null && c.authorProfileImageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                backgroundImage: hasAvatar
                    ? NetworkImage(c.authorProfileImageUrl!) as ImageProvider
                    : const AssetImage('assets/icons/default.png'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.authorName.isEmpty ? 'User' : c.authorName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: c.isDeleted ? grey03 : dark,
                          ),
                        ),

                        if (canDelete) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _confirmDeleteComment(c),
                            child: SvgPicture.asset(
                              'assets/icons/dots-linear.svg',
                              width: 16,
                              height: 16,
                              color: dark,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _fmtDate(c.regTime),
                          style: const TextStyle(
                            fontSize: 11,
                            color: grey03,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: grey03,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Text(
                          _fmtTime(c.regTime),
                          style: const TextStyle(
                            fontSize: 11,
                            color: grey03,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.content,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: c.isDeleted ? grey03 : dark,
              fontStyle: c.isDeleted ? FontStyle.italic : FontStyle.normal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentComposer() {
    return Container(
      color: Colors.transparent, // 배경을 투명하게 하여 메시지 창과 동일한 레이어감 유지
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: SafeArea(
          top: false,
          child: Container(
            constraints: const BoxConstraints(minHeight: 68, maxHeight: 155),
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
                // + 버튼 (디자인 유지, 클릭 기능 없음)
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

                // 댓글 입력창
                Expanded(
                  child: TextField(
                    cursorColor: grey03,
                    controller: _commentCtl,
                    focusNode: _commentFocus,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dark,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Write a comment...",
                      hintStyle: TextStyle(color: grey03, fontSize: 14),
                      contentPadding: EdgeInsets.symmetric(
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
                    onTap: _posting ? null : _submitComment,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _posting ? grey01 : green,
                      ),
                      child: Padding(
                        padding: _posting
                            ? const EdgeInsets.all(12)
                            : const EdgeInsets.fromLTRB(14, 12, 11, 12),
                        child: _posting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : SvgPicture.asset(
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
    );
  }
}
