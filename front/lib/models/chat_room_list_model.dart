class ChatRoomListModel {
  final int roomId;
  final int houseId;
  final String houseTitle;
  /// 상대방 memberId — Split Bills 메이트 선택 등 클라이언트 활용용.
  /// 백엔드 응답 누락 시 0.
  final int otherMemberId;
  final String otherMemberName;
  final String lastMessage;
  final String lastSenderName;
  final String lastMessageTime;
  final String? profileImageUrl;

  ChatRoomListModel({
    required this.roomId,
    required this.houseId,
    required this.houseTitle,
    required this.otherMemberId,
    required this.otherMemberName,
    required this.lastMessage,
    required this.lastSenderName,
    required this.lastMessageTime,
    this.profileImageUrl,
  });

  factory ChatRoomListModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomListModel(
      roomId: (json['roomId'] as num?)?.toInt() ?? 0,
      houseId: (json['houseId'] as num?)?.toInt() ?? 0,
      houseTitle: json['houseTitle'] ?? '',
      otherMemberId: (json['otherMemberId'] as num?)?.toInt() ?? 0,
      otherMemberName: json['otherMemberName'] ?? 'Unknown',
      lastMessage: json['lastMessage'] ?? '',
      lastSenderName: json['lastSenderName'] ?? '',
      lastMessageTime: json['lastMessageTime'] ?? '',
      profileImageUrl: json['profileImageUrl'],
    );
  }

}