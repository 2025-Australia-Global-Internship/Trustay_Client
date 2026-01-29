class SharehouseDetail {
  final int id;
  final String title;
  final String content; // 상세 설명
  final String address;
  final String addressDetail;
  final String houseType; // APARTMENT, VILLA 등
  final String roomType;  // SINGLE, TWIN 등
  final int deposit;      // 보증금
  final int monthlyRent;  // 월세
  final int maintenanceFee; // 관리비
  final List<String> imageUrls;
  final List<String> options; // 옵션 목록 (AC, BED, WIFI 등)
  final double latitude;  // 지도용
  final double longitude; // 지도용

  SharehouseDetail({
    required this.id,
    required this.title,
    required this.content,
    required this.address,
    required this.addressDetail,
    required this.houseType,
    required this.roomType,
    required this.deposit,
    required this.monthlyRent,
    required this.maintenanceFee,
    required this.imageUrls,
    required this.options,
    required this.latitude,
    required this.longitude,
  });

  factory SharehouseDetail.fromJson(Map<String, dynamic> json) {
    return SharehouseDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      address: json['address'] ?? '',
      addressDetail: json['addressDetail'] ?? '',
      houseType: json['houseType'] ?? 'UNKNOWN',
      roomType: json['roomType'] ?? 'UNKNOWN',
      deposit: json['deposit'] ?? 0,
      monthlyRent: json['monthlyRent'] ?? 0,
      maintenanceFee: json['maintenanceFee'] ?? 0,
      imageUrls: json['imageUrls'] != null 
          ? List<String>.from(json['imageUrls']) 
          : [],
      options: json['sharehouseOptions'] != null // 백엔드 DTO 필드명 확인 필요 (보통 options 또는 sharehouseOptions)
          ? List<String>.from(json['sharehouseOptions']) 
          : [],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}