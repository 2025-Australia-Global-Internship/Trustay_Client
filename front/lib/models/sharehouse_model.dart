class SharehouseModel {
  final int id;
  final String title;
  final String address;
  final String houseType;
  final List<String> imageUrls;
  // 카드에 표시할 추가 정보
  final int rentPrice; 
  final int bathroomCount;
  final int roomCount;
  final int currentResidents;


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
    );
  }
}