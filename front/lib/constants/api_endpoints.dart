import 'api_constants.dart';

class ApiEndpoints {
  // base segments
  static const String authBase = '${ApiConstants.baseUrl}/api/trustay/auth';
  static const String chatBase = '${ApiConstants.baseUrl}/api/chat';
  static const String contractsBase = '${ApiConstants.baseUrl}/api/contracts';
  static const String communitiesBase =
      '${ApiConstants.baseUrl}/api/trustay/communities';
  static const String membersBase =
      '${ApiConstants.baseUrl}/api/trustay/members';
  static const String paperContractsBase =
      '${ApiConstants.baseUrl}/api/paper-contracts';
  static const String paymentsBase =
      '${ApiConstants.baseUrl}/api/trustay/payments';
  static const String postsBase = '${ApiConstants.baseUrl}/api/trustay/posts';
  static const String sharehousesBase =
      '${ApiConstants.baseUrl}/api/trustay/sharehouses';

  // Auth
  static const String authLogin = '$authBase/login';
  static const String authOauth = '$authBase/oauth';
  static const String authLogout = '$authBase/logout';

  // Chat
  static const String createRoom = '$chatBase/room';
  static String chatRoomMessages(int roomId, int memberId) =>
      '$chatBase/room/$roomId/messages/$memberId';
  static String myChatRooms(int memberId) => '$chatBase/rooms/$memberId';
  static String leaveChatRoom(int roomId, int memberId) =>
      '$chatBase/room/$roomId/leave?memberId=$memberId';
  // 채팅 이미지 업로드: 서버가 IMAGE 타입 ChatMessage 로 저장 후
  // /sub/chat/room/{roomId} 로 자동 브로드캐스트한다.
  static String chatRoomImage(int roomId, int senderId) =>
      '$chatBase/room/$roomId/image?senderId=$senderId';

  // STOMP (SockJS over HTTP)
  // - 백엔드가 `registry.addEndpoint("/ws-stomp").withSockJS()` 형태이므로
  //   클라이언트는 SockJS 프로토콜(HTTP 기반 핸드셰이크 → WS 업그레이드)로 접속해야 한다.
  //   따라서 URL은 ws://가 아니라 http(s):// 스킴이어야 한다.
  // - websocketEndpoint  : SockJS/STOMP 핸드셰이크 엔드포인트 (절대 URL, http/https)
  // - stompPublishSend   : 메시지 발행 destination (서버 @MessageMapping("/chat/send") + prefix /pub)
  // - stompSubscribeRoom : 방 구독 destination (서버 SimpleBroker /sub)
  static String get websocketEndpoint => '${ApiConstants.baseUrl}/ws-stomp';
  static const String stompPublishSend = '/pub/chat/send';
  static String stompSubscribeRoom(int roomId) => '/sub/chat/room/$roomId';

  // Communities
  static const String communitiesRoot = communitiesBase;
  static const String communitiesTrending = '$communitiesBase/trending';
  static const String communitiesCreated = '$communitiesBase/created';
  static const String communitiesJoined = '$communitiesBase/joined';
  static const String communitiesRecent = '$communitiesBase/recent';
  static const String communitiesRecentSearches =
      '$communitiesBase/recent-searches';
  static String communitiesRecentSearchById(int searchId) =>
      '$communitiesBase/recent-searches/$searchId';
  static String communityById(int communityId) =>
      '$communitiesBase/$communityId';
  static String communityMembers(int communityId) =>
      '$communitiesBase/$communityId/members';
  static String communityJoin(int communityId) =>
      '$communitiesBase/$communityId/join';
  static String communityLeave(int communityId) =>
      '$communitiesBase/$communityId/leave';
  static String communityUpdate(int communityId) =>
      '$communitiesBase/$communityId';
  static String communityDelete(int communityId) =>
      '$communitiesBase/$communityId';

  // Members
  static const String signup = '$membersBase/signup';
  static const String profile = '$membersBase/profile';
  static const String profileImage = '$membersBase/profile/image';

  // Paper contracts
  static const String paperScan = '$paperContractsBase/scan';
  static String paperDocument(String documentId) =>
      '$paperContractsBase/$documentId';
  static const String myPaperContracts = '$paperContractsBase/me';

  // Contracts (정식 계약 제안/서명/조회)
  static const String contractPropose = '$contractsBase/propose';
  static String contractSign(int contractId) =>
      '$contractsBase/$contractId/sign';
  static String contractById(int contractId) => '$contractsBase/$contractId';
  static const String myContracts = '$contractsBase/me';

  // Payments
  static const String tossClientConfig = '$paymentsBase/toss/client-config';
  static const String rentPrepare = '$paymentsBase/rent/prepare';
  static const String dutchCreate = '$paymentsBase/dutch';
  static const String paymentConfirm = '$paymentsBase/confirm';
  static const String myPendingPayments = '$paymentsBase/me/pending';
  static const String myPaymentHistory = '$paymentsBase/me/history';

  // Posts
  static const String postsRoot = postsBase;
  static String postById(int postId) => '$postsBase/$postId';
  static String postsByCommunity(int communityId) =>
      '$postsBase/community/$communityId';
  static String postsBySharehouse(int sharehouseId) =>
      '$postsBase/sharehouse/$sharehouseId';
  static const String postsFeed = '$postsBase/feed';
  static const String myPosts = '$postsBase/me';
  static String postLike(int postId) => '$postsBase/$postId/like';
  static String postComments(int postId) => '$postsBase/$postId/comments';
  static String postCommentById(int postId, int commentId) =>
      '$postsBase/$postId/comments/$commentId';

  // Sharehouses
  static const String uploadImages = '$sharehousesBase/images';
  static const String sharehousesRoot = sharehousesBase;
  static const String sharehousesRecent = '$sharehousesBase/recent';
  static const String sharehousesRecentSearches =
      '$sharehousesBase/recent-searches';
  static String sharehousesRecentSearchById(int searchId) =>
      '$sharehousesBase/recent-searches/$searchId';
  static String sharehouseById(int houseId) => '$sharehousesBase/$houseId';
  static String sharehouseMy(int houseId) => '$sharehousesBase/my/$houseId';
  static const String sharehousesMyList = '$sharehousesBase/my';
  static const String sharehouseMyCurrent = '$sharehousesBase/me/current';
  static String sharehouseWish(int houseId) =>
      '$sharehousesBase/$houseId/wish';
  static const String sharehousesWishlist = '$sharehousesBase/wishlist';
  static String sharehouseApproval(int houseId, String status) =>
      '$sharehousesBase/$houseId/approval?status=$status';
}
