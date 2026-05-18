import 'api_constants.dart';

class ApiEndpoints {
  // base segments
  static const String authBase = '${ApiConstants.baseUrl}/api/trustay/auth';
  static const String chatBase = '${ApiConstants.baseUrl}/api/chat';
  static const String communitiesBase = '${ApiConstants.baseUrl}/api/trustay/communities';
  static const String membersBase = '${ApiConstants.baseUrl}/api/trustay/members';
  static const String paperContractsBase = '${ApiConstants.baseUrl}/api/paper-contracts';
  static const String paymentsBase = '${ApiConstants.baseUrl}/api/trustay/payments';
  static const String postsBase = '${ApiConstants.baseUrl}/api/trustay/posts';
  static const String sharehousesBase = '${ApiConstants.baseUrl}/api/trustay/sharehouses';

  // Auth
  static const String authLogin = '$authBase/login';
  static const String authOauth = '$authBase/oauth';
  static const String authLogout = '$authBase/logout';

  // Chat
  static const String createRoom = '$chatBase/room';
  static String chatRoomMessages(int roomId, int memberId) => '$chatBase/room/$roomId/messages/$memberId';
  static String myChatRooms(int memberId) => '$chatBase/rooms/$memberId';
  static String leaveChatRoom(int roomId) => '$chatBase/room/$roomId/leave';

  // STOMP (WebSocket) — 상대 경로로 사용
  static const String stompSend = '/chat/send';
  static String stompSubscribeRoom(int roomId) => '/sub/chat/room/$roomId';

  // Communities
  static const String communitiesRoot = communitiesBase;
  static const String communitiesTrending = '$communitiesBase/trending';
  static const String communitiesCreated = '$communitiesBase/created';
  static const String communitiesJoined = '$communitiesBase/joined';
  static String communityById(int communityId) => '$communitiesBase/$communityId';
  static String communityJoin(int communityId) => '$communitiesBase/$communityId/join';
  static String communityLeave(int communityId) => '$communitiesBase/$communityId/leave';
  static String communityUpdate(int communityId) => '$communitiesBase/$communityId';
  static String communityDelete(int communityId) => '$communitiesBase/$communityId';

  // Members
  static const String signup = '$membersBase/signup';
  static const String profile = '$membersBase/profile';
  static const String profileImage = '$membersBase/profile/image';

  // Paper contracts
  static const String paperScan = '$paperContractsBase/scan';
  static String paperDocument(String documentId) => '$paperContractsBase/$documentId';

  // Payments
  static const String tossClientConfig = '$paymentsBase/toss/client-config';
  static const String rentPrepare = '$paymentsBase/rent/prepare';
  static const String dutchCreate = '$paymentsBase/dutch';
  static const String paymentConfirm = '$paymentsBase/confirm';
  static const String myPendingPayments = '$paymentsBase/me/pending';

  // Posts
  static const String postsRoot = postsBase;
  static String postById(int postId) => '$postsBase/$postId';
  static String postsByCommunity(int communityId) => '$postsBase/community/$communityId';
  static String postsBySharehouse(int sharehouseId) => '$postsBase/sharehouse/$sharehouseId';
  static const String postsFeed = '$postsBase/feed';

  // Sharehouses
  static const String uploadImages = '$sharehousesBase/images';
  static const String sharehousesRoot = sharehousesBase;
  static String sharehouseById(int houseId) => '$sharehousesBase/$houseId';
  static String sharehouseMy(int houseId) => '$sharehousesBase/my/$houseId';
  static const String sharehousesMyList = '$sharehousesBase/my';
  static String sharehouseWish(int houseId) => '$sharehousesBase/$houseId/wish';
  static const String sharehousesWishlist = '$sharehousesBase/wishlist';
  static String sharehouseApproval(int houseId, String status) => '$sharehousesBase/$houseId/approval?status=$status';
}
