class SharehouseModel {
  final int id;
  final String title;
  final String address;
  final String houseType;
  final List<String> imageUrls;
  final int rentPrice;
  final int bathroomCount;
  final int roomCount;
  final int currentResidents;

  /// 백엔드 SharehouseRes 응답에서 새로 추가된 보조 필드들.
  /// 서버 응답에 없을 수도 있으므로 모두 nullable / default 0 처리.
  final int viewCount;
  final int wishCount;
  final bool wishedByMe;
  final String? approvalStatus; // ApprovalStatus enum (PENDING / ACTIVE / REJECTED)
  final double? lat;
  final double? lon;

  SharehouseModel({
    required this.id,
    required this.title,
    required this.address,
    required this.houseType,
    required this.imageUrls,
    required this.rentPrice,
    required this.bathroomCount,
    required this.roomCount,
    required this.currentResidents,
    this.viewCount = 0,
    this.wishCount = 0,
    this.wishedByMe = false,
    this.approvalStatus,
    this.lat,
    this.lon,
  });

  factory SharehouseModel.fromJson(Map<String, dynamic> json) {
    return SharehouseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      address: json['address'] ?? '',
      houseType: json['houseType'] ?? 'UNKNOWN',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      rentPrice: json['rentPrice'] ?? 0,
      bathroomCount: json['bathroomCount'] ?? 0,
      roomCount: json['roomCount'] ?? 0,
      currentResidents: json['currentResidents'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      wishCount: json['wishCount'] ?? 0,
      wishedByMe: json['wishedByMe'] ?? false,
      approvalStatus: json['approvalStatus']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'houseType': houseType,
      'imageUrls': imageUrls,
      'rentPrice': rentPrice,
      'bathroomCount': bathroomCount,
      'roomCount': roomCount,
      'currentResidents': currentResidents,
      'viewCount': viewCount,
      'wishCount': wishCount,
      'wishedByMe': wishedByMe,
      'approvalStatus': approvalStatus,
      'lat': lat,
      'lon': lon,
    };
  }
}
