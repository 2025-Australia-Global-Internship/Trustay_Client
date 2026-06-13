/// 서버 `ChatMessageRes` 응답에 1:1 대응.
///
/// 메시지 타입은 백엔드 `MessageType` enum 과 동일:
/// - `TEXT`              : 일반 텍스트
/// - `IMAGE`             : 업로드된 이미지 URL
/// - `CONTRACT`          : 종이 계약서 스캔 PDF URL (paperContractDocumentId 와 연결)
/// - `CONTRACT_PROPOSAL` : 한쪽이 보낸 계약 제안. 본문은 요약 텍스트, contractId 와 연결
/// - `CONTRACT_SIGNED`   : 양측 서명 완료된 계약. 본문은 서명 PDF URL, contractId 와 연결
class ChatMessageModel {
  final int messageId;

  /// 메시지가 속한 채팅방 ID. STOMP 재연결 후 멀티룸 라우팅에 사용.
  final int roomId;

  /// 메시지가 속한 채팅방의 매물 ID. 어떤 하우스에 대한 채팅인지 식별.
  final int houseId;

  final int senderId;
  final String senderName;

  /// TEXT/CONTRACT_PROPOSAL 이면 본문, IMAGE/CONTRACT/CONTRACT_SIGNED 이면 파일 URL.
  final String message;

  final String messageType;

  /// ISO-8601 문자열 (예: `2026-06-10T20:23:11.123`).
  final String regTime;

  /// `messageType == 'CONTRACT'` 일 때 스캔 문서 ID.
  final int? paperContractDocumentId;

  /// `messageType == 'CONTRACT_PROPOSAL' | 'CONTRACT_SIGNED'` 일 때 정식 계약 ID.
  final int? contractId;

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
    this.contractId,
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
      contractId: (json['contractId'] as num?)?.toInt(),
    );
  }
}
