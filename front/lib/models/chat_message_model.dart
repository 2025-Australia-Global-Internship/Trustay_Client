/// 서버 `ChatMessageRes` 응답에 1:1 대응.
///
/// 명세 (2026-06-10 변경: `roomId`, `houseId` 가 모든 메시지에 함께 옴):
/// ```
/// {
///   "messageId": 101,
///   "roomId": 42,
///   "houseId": 12,
///   "senderId": 7,
///   "senderName": "Jeong",
///   "message": "...",
///   "messageType": "TEXT" | "IMAGE" | "CONTRACT",
///   "regTime": "2026-06-10T20:23:11.123",
///   "paperContractDocumentId": null | number
/// }
/// ```
class ChatMessageModel {
  final int messageId;

  /// 메시지가 속한 채팅방 ID. STOMP 재연결 후 멀티룸 라우팅에 사용.
  final int roomId;

  /// 메시지가 속한 채팅방의 매물 ID. 어떤 하우스에 대한 채팅인지 식별.
  final int houseId;

  final int senderId;
  final String senderName;

  /// TEXT 이면 본문, IMAGE/CONTRACT 이면 업로드된 파일 URL.
  final String message;

  /// 서버 enum 과 동일: `TEXT` / `IMAGE` / `CONTRACT`.
  final String messageType;

  /// ISO-8601 문자열 (예: `2026-06-10T20:23:11.123`).
  final String regTime;

  /// `messageType == 'CONTRACT'` 이고 스캔된 종이 계약서 문서와 연결된 경우에만 값이 들어옴.
  final int? paperContractDocumentId;

  ChatMessageModel({
    required this.messageId,
    required this.roomId,
    required this.houseId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.messageType,
    required this.regTime,
    this.paperContractDocumentId,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      messageId: (json['messageId'] as num?)?.toInt() ?? 0,
      roomId: (json['roomId'] as num?)?.toInt() ?? 0,
      houseId: (json['houseId'] as num?)?.toInt() ?? 0,
      senderId: (json['senderId'] as num?)?.toInt() ?? 0,
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      messageType: json['messageType'] ?? 'TEXT',
      regTime: json['regTime'] ?? '',
      paperContractDocumentId:
          (json['paperContractDocumentId'] as num?)?.toInt(),
    );
  }
}
