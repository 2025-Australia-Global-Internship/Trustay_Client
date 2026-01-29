// models/listing_model.dart

class MyListingItem {
  final int id;
  final String title;
  final String address;
  final String houseType;
  final String approvalStatus;
  final List<String> imageUrls;

  MyListingItem({
    required this.id,
    required this.title,
    required this.address,
    required this.houseType,
    required this.approvalStatus,
    required this.imageUrls,
  });

  factory MyListingItem.fromJson(Map<String, dynamic> json) {
    return MyListingItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '제목 없음',
      address: json['address'] ?? '주소 정보 없음',
      houseType: json['houseType'] ?? 'UNKNOWN',
      approvalStatus: json['approvalStatus'] ?? 'WAITING',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
    );
  }
}