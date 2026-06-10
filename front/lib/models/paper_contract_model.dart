/// 서버 [PaperContractScanRes] 응답 (업로드 직후 반환)
class PaperContractScanResult {
  final int paperContractDocumentId;
  final String? pdfUrl;
  final String? ocrText;
  final String? status; // PaperContractScanStatus

  PaperContractScanResult({
    required this.paperContractDocumentId,
    this.pdfUrl,
    this.ocrText,
    this.status,
  });

  factory PaperContractScanResult.fromJson(Map<String, dynamic> json) {
    return PaperContractScanResult(
      paperContractDocumentId: json['paperContractDocumentId'] ?? 0,
      pdfUrl: json['pdfUrl'] as String?,
      ocrText: json['ocrText'] as String?,
      status: json['status']?.toString(),
    );
  }
}

/// 서버 [PaperContractDocumentRes] 응답
class PaperContractDocumentModel {
  final int id;
  final int? roomId;
  final int? houseId;
  final String? pdfUrl;
  final String? ocrText;
  final List<String> sourceImageUrls;
  final String? status;
  final String? regTime;

  PaperContractDocumentModel({
    required this.id,
    this.roomId,
    this.houseId,
    this.pdfUrl,
    this.ocrText,
    this.sourceImageUrls = const [],
    this.status,
    this.regTime,
  });

  factory PaperContractDocumentModel.fromJson(Map<String, dynamic> json) {
    return PaperContractDocumentModel(
      id: json['id'] ?? 0,
      roomId: json['roomId'] as int?,
      houseId: json['houseId'] as int?,
      pdfUrl: json['pdfUrl'] as String?,
      ocrText: json['ocrText'] as String?,
      sourceImageUrls: json['sourceImageUrls'] != null
          ? List<String>.from(json['sourceImageUrls'])
          : const [],
      status: json['status']?.toString(),
      regTime: json['regTime']?.toString(),
    );
  }
}
