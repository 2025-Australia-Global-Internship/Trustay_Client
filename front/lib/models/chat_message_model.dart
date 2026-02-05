class ChatMessageModel {
  final int messageId;
  final int senderId;
  final String senderName;
  final String message;
  final String messageType; // "TALK", "ENTER" 등
  final String regTime;

  ChatMessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.messageType,
    required this.regTime,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      messageId: json['messageId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      messageType: json['messageType'] ?? 'TALK',
      regTime: json['regTime'] ?? '',
    );
  }
}