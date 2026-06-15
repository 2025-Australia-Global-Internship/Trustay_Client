import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/colors.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/gradient_layout.dart';

/// 내 알림 목록 페이지.
///
/// - 무한 스크롤 페이지네이션
/// - Pull-to-refresh
/// - 단건 탭: 읽음 처리 + linkUrl 라우팅 (가능한 경우)
/// - 스와이프-삭제 (Dismissible)
/// - 헤더 오른쪽: 전체 읽음 처리
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const int _pageSize = 20;

  final ScrollController _scrollCtl = ScrollController();
  final List<NotificationModel> _items = [];

  int _page = 0;
  bool _isLast = false;
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _markingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollCtl.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollCtl.removeListener(_onScroll);
    _scrollCtl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 데이터 로드
  // ---------------------------------------------------------------------------
  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });
    try {
      final result =
          await NotificationService.fetchNotifications(page: 0, size: _pageSize);
      await NotificationService.fetchUnreadCount();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(result.items);
        _page = result.page;
        _isLast = result.isLast;
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendly(e);
        _initialLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final result =
          await NotificationService.fetchNotifications(page: 0, size: _pageSize);
      await NotificationService.fetchUnreadCount();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(result.items);
        _page = result.page;
        _isLast = result.isLast;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack(_friendly(e));
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _isLast) return;
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final result = await NotificationService.fetchNotifications(
        page: next,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _page = result.page;
        _isLast = result.isLast;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      _showSnack(_friendly(e));
    }
  }

  void _onScroll() {
    if (!_scrollCtl.hasClients) return;
    final pos = _scrollCtl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  // ---------------------------------------------------------------------------
  // 항목 액션
  // ---------------------------------------------------------------------------
  Future<void> _onTapItem(NotificationModel n) async {
    if (!n.isRead) {
      // 낙관적 갱신
      final idx = _items.indexWhere((e) => e.id == n.id);
      if (idx != -1) {
        setState(() => _items[idx] = _items[idx].copyWith(isRead: true));
      }
      try {
        await NotificationService.markAsRead(n.id);
      } catch (_) {
        // 실패해도 사용자 흐름은 막지 않는다. 다음 새로고침에서 정정됨.
      }
    }

    final link = n.linkUrl;
    if (link != null && link.isNotEmpty && mounted) {
      // 알려진 in-app 라우트에만 안전하게 매핑한다. 매핑이 없으면 무시.
      final route = _resolveInAppRoute(link);
      if (route != null) {
        Navigator.of(context).pushNamed(route);
      }
    }
  }

  Future<void> _deleteItem(NotificationModel n) async {
    final idx = _items.indexWhere((e) => e.id == n.id);
    if (idx == -1) return;
    final removed = _items[idx];
    setState(() => _items.removeAt(idx));

    try {
      await NotificationService.deleteNotification(n.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _items.insert(idx, removed));
      _showSnack(_friendly(e));
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    final hasUnread = _items.any((e) => !e.isRead);
    if (!hasUnread) return;
    setState(() => _markingAll = true);
    try {
      await NotificationService.markAllRead();
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          if (!_items[i].isRead) {
            _items[i] = _items[i].copyWith(isRead: true);
          }
        }
        _markingAll = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _markingAll = false);
      _showSnack(_friendly(e));
    }
  }

  /// 서버 `linkUrl` → 현재 앱의 라우트 이름으로 변환.
  /// 알려진 패턴만 매핑하고 나머지는 무시한다.
  String? _resolveInAppRoute(String linkUrl) {
    // 채팅, 매물, 결제 등 상세 페이지는 모두 별도 인자가 필요하므로
    // 현재 알려진 정적 라우트만 지원한다. 차후 ChatRoomPage/PaymentPage 등에
    // 라우트가 등록되면 이곳에서 분기하면 된다.
    const knownRoutes = {
      '/index',
      '/my_contracts',
      '/my_wallet',
      '/my_reviews',
      '/saved_listings',
      '/current_stay',
    };
    if (knownRoutes.contains(linkUrl)) return linkUrl;
    return null;
  }

  String _friendly(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------------
  // 빌드
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: GradientLayout(
        child: Column(
          children: [
            CustomHeader(
              showBack: true,
              center: const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
              trailing: TextButton(
                onPressed: _markingAll ? null : _markAllRead,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _markingAll ? '...' : 'Read all',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: green,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: const TextStyle(fontSize: 14, color: grey02),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadInitial,
                style: OutlinedButton.styleFrom(
                  foregroundColor: green,
                  side: const BorderSide(color: green),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        color: green,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'No notifications yet.\nWe will let you know when something new happens.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: grey03,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: green,
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollCtl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _items.length + (_isLast ? 0 : 1),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
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
            );
          }
          final item = _items[index];
          return _buildItem(item);
        },
      ),
    );
  }

  Widget _buildItem(NotificationModel n) {
    return Dismissible(
      key: ValueKey('notification_${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete notification?'),
            content: const Text('This will remove the notification from your list.'),
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
        return ok == true;
      },
      onDismissed: (_) => _deleteItem(n),
      child: Material(
        color: n.isRead ? Colors.white : const Color(0xFFFFFDEB),
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onTapItem(n),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: n.isRead ? grey01.withOpacity(0.6) : yellow,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationIcon(type: n.type, isRead: n.isRead),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title.isEmpty
                                  ? _defaultTitleFor(n.type)
                                  : n.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: n.isRead
                                    ? FontWeight.w700
                                    : FontWeight.w800,
                                color: dark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if ((n.body ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          n.body!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: dark,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _timeAgo(n.regTime),
                        style: const TextStyle(
                          fontSize: 11,
                          color: grey03,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _defaultTitleFor(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return 'New chat message';
      case NotificationType.payment:
        return 'Payment update';
      case NotificationType.approval:
        return 'Listing approval update';
      case NotificationType.community:
        return 'Community update';
      case NotificationType.system:
        return 'Notification';
    }
  }

  String _timeAgo(String iso) {
    final dt = _parseLocal(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }

  DateTime? _parseLocal(String iso) {
    if (iso.isEmpty) return null;
    try {
      final raw = iso.endsWith('Z') ? iso : '${iso}Z';
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }
}

// 알림 타입별 아이콘 (Material Icons 만 사용해 의존성 추가 없이 구성)
class _NotificationIcon extends StatelessWidget {
  final NotificationType type;
  final bool isRead;

  const _NotificationIcon({required this.type, required this.isRead});

  @override
  Widget build(BuildContext context) {
    final Color background;
    final IconData icon;
    switch (type) {
      case NotificationType.chat:
        background = const Color(0xFFDFE7B6);
        icon = Icons.chat_bubble_outline_rounded;
        break;
      case NotificationType.payment:
        background = const Color(0xFFFFE6A8);
        icon = Icons.payments_outlined;
        break;
      case NotificationType.approval:
        background = const Color(0xFFCFE8C2);
        icon = Icons.task_alt_rounded;
        break;
      case NotificationType.community:
        background = const Color(0xFFE6D4F3);
        icon = Icons.groups_outlined;
        break;
      case NotificationType.system:
        background = const Color(0xFFE0E0E0);
        icon = Icons.notifications_none_rounded;
        break;
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isRead ? background.withOpacity(0.6) : background,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: darkgreen),
    );
  }
}
