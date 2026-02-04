class ChatRoomListModel {
  final int roomId;
  final int houseId;
  final String houseTitle;
  final String otherMemberName;
  final String lastMessage;
  final String lastSenderName;
  final String lastMessageTime;
  final String? profileImageUrl; // 추가 예정인 필드

  ChatRoomListModel({
    required this.roomId,
    required this.houseId,
    required this.houseTitle,
    required this.otherMemberName,
    required this.lastMessage,
    required this.lastSenderName,
    required this.lastMessageTime,
    this.profileImageUrl,
  });

  // JSON 변환 팩토리 (추후 API 연동 시 사용)
  factory ChatRoomListModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomListModel(
      roomId: json['roomId'] ?? 0,
      houseId: json['houseId'] ?? 0,
      houseTitle: json['houseTitle'] ?? '',
      otherMemberName: json['otherMemberName'] ?? 'Unknown',
      lastMessage: json['lastMessage'] ?? '',
      lastSenderName: json['lastSenderName'] ?? '',
      lastMessageTime: json['lastMessageTime'] ?? '',
      profileImageUrl: json['profileImageUrl'],
    );
  }

}