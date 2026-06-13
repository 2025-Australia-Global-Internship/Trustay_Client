/// 백엔드 `ContractRes` 응답 1:1 대응.
class ContractModel {
  final int id;
  final String status; // DRAFT / SIGNED / ACTIVE / EXPIRED

  final int? roomId;
  final int? houseId;
  final String? houseTitle;
  /// 매물 주소. Sharehouse 가 사라지거나 미연결이면 null.
  final String? houseAddress;
  /// 매물 대표 이미지 URL. 없으면 null.
  final String? houseImageUrl;

  final int landlordId;
  final String landlordName;
  final int tenantId;
  final String tenantName;

  final String? startDate; // yyyy-MM-dd
  final String? endDate;

  final int? monthlyRent;
  final int? deposit;

  final String? landlordSignatureUrl;
  final String? landlordSignedAt;
  final String? tenantSignatureUrl;
  final String? tenantSignedAt;

  final int? paperContractDocumentId;
  final String? paperContractPdfUrl;
  final String? signedPdfUrl;

  final String? regTime;

  ContractModel({
    required this.id,
    required this.status,
    this.roomId,
    this.houseId,
    this.houseTitle,
    this.houseAddress,
    this.houseImageUrl,
    required this.landlordId,
    required this.landlordName,
    required this.tenantId,
    required this.tenantName,
    this.startDate,
    this.endDate,
    this.monthlyRent,
    this.deposit,
    this.landlordSignatureUrl,
    this.landlordSignedAt,
    this.tenantSignatureUrl,
    this.tenantSignedAt,
    this.paperContractDocumentId,
    this.paperContractPdfUrl,
    this.signedPdfUrl,
    this.regTime,
  });

  bool get isDraft => status == 'DRAFT';
  bool get isActive => status == 'ACTIVE';
  bool get isExpired => status == 'EXPIRED';
  bool get isFullySigned =>
      landlordSignatureUrl != null && tenantSignatureUrl != null;

  bool isLandlord(int memberId) => landlordId == memberId;
  bool isTenant(int memberId) => tenantId == memberId;
  bool involves(int memberId) =>
      landlordId == memberId || tenantId == memberId;

  /// 이 회원이 아직 서명을 안 했고, 상대방의 제안에 대해 응답해야 하는 상태인지.
  bool needsMySignature(int memberId) {
    if (isLandlord(memberId)) return landlordSignatureUrl == null;
    if (isTenant(memberId)) return tenantSignatureUrl == null;
    return false;
  }

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'DRAFT',
      roomId: (json['roomId'] as num?)?.toInt(),
      houseId: (json['houseId'] as num?)?.toInt(),
      houseTitle: json['houseTitle'] as String?,
      houseAddress: json['houseAddress'] as String?,
      houseImageUrl: json['houseImageUrl'] as String?,
      landlordId: (json['landlordId'] as num?)?.toInt() ?? 0,
      landlordName: json['landlordName']?.toString() ?? '',
      tenantId: (json['tenantId'] as num?)?.toInt() ?? 0,
      tenantName: json['tenantName']?.toString() ?? '',
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      monthlyRent: (json['monthlyRent'] as num?)?.toInt(),
      deposit: (json['deposit'] as num?)?.toInt(),
      landlordSignatureUrl: json['landlordSignatureUrl'] as String?,
      landlordSignedAt: json['landlordSignedAt']?.toString(),
      tenantSignatureUrl: json['tenantSignatureUrl'] as String?,
      tenantSignedAt: json['tenantSignedAt']?.toString(),
      paperContractDocumentId:
          (json['paperContractDocumentId'] as num?)?.toInt(),
      paperContractPdfUrl: json['paperContractPdfUrl'] as String?,
      signedPdfUrl: json['signedPdfUrl'] as String?,
      regTime: json['regTime']?.toString(),
    );
  }
}
