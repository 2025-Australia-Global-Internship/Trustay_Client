class SharehouseDetailModel {
  final int id;
  final String title;
  final String description;
  final String address;
  final String houseType;
  final int rentPrice;
  final int roomCount;
  final int bathroomCount;
  final String? homeRules; // Java의 homeRulse 반영
  final String? features;
  final int viewCount;
  final String hostName;
  final double? lat;
  final double? lon;
  final List<String> imageUrls;
  final bool billsIncluded;
  final String roomType;
  final int bondType; // Integer로 변경됨
  final int minimumStay;
  final String gender;
  final String age;
  final String religion;
  final String dietaryPreference;

  SharehouseDetailModel({
    required this.id, required this.title, required this.description,
    required this.address, required this.houseType, required this.rentPrice,
    required this.roomCount, required this.bathroomCount, this.homeRules,
    this.features, required this.viewCount, required this.hostName,
    this.lat, this.lon, required this.imageUrls, required this.billsIncluded,
    required this.roomType, required this.bondType, required this.minimumStay,
    required this.gender, required this.age, required this.religion,
    required this.dietaryPreference,
  });

  factory SharehouseDetailModel.fromJson(Map<String, dynamic> json) {
    final d = json['data'] ?? json;
    return SharehouseDetailModel(
      id: d['id'] ?? 0,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      address: d['address'] ?? '',
      houseType: d['houseType']?.toString() ?? '',
      rentPrice: d['rentPrice'] ?? 0,
      roomCount: d['roomCount'] ?? 0,
      bathroomCount: d['bathroomCount'] ?? 0,
      homeRules: d['homeRulse'], // 백엔드 필드명 유지
      features: d['features'],
      viewCount: d['viewCount'] ?? 0,
      hostName: d['hostName'] ?? 'Unknown',
      lat: (d['lat'] as num?)?.toDouble(),
      lon: (d['lon'] as num?)?.toDouble(),
      imageUrls: d['imageUrls'] != null ? List<String>.from(d['imageUrls']) : [],
      billsIncluded: d['billsIncluded'] ?? false,
      roomType: d['roomType']?.toString() ?? '',
      bondType: d['bondType'] ?? 0,
      minimumStay: d['minimumStay'] ?? 0,
      gender: d['gender'] ?? '',
      age: d['age'] ?? '',
      religion: d['religion'] ?? '',
      dietaryPreference: d['dietaryPreference'] ?? '',
    );
  }
}