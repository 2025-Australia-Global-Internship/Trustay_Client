// ─── Request Model ───────────────────────────────────────────────────────────
class SharehouseCreateRequest {
  final String title;
  final String description;
  final String address;
  final String houseType; // APARTMENT, HOUSE, UNIT, TOWNHOUSE
  final int rentPrice;
  final int roomCount; // Bedroom 수
  final int bathroomCount; // Bathroom 수
  final int currentResidents; // Resident 수
  final List<String> homeRules; // ["No smoking", "No parties" 등]
  final List<String> features; // ["Double bed", "Washing Machine" 등]
  final List<String> imageUrls;
  final bool billsIncluded; // true / false
  final String roomType; // SHAREDROOM, PRIVATEROOM, ENTIREPLACE
  final int bondType; // 0 (Custom), 2, 4 (weeks)
  final int minimumStay; // 주 단위 숫자
  final String gender; // MALE, FEMALE, NON_BINARY
  final String age; // "No age rejection" 또는 숫자 포함 문자열
  final String religion;
  final String dietaryPreference;

  SharehouseCreateRequest({
    required this.title,
    required this.description,
    required this.address,
    required this.houseType,
    required this.rentPrice,
    required this.roomCount,
    required this.bathroomCount,
    required this.currentResidents,
    required this.homeRules,
    required this.features,
    required this.imageUrls,
    required this.billsIncluded,
    required this.roomType,
    required this.bondType,
    required this.minimumStay,
    required this.gender,
    required this.age,
    required this.religion,
    required this.dietaryPreference,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'address': address,
    'houseType': houseType,
    'rentPrice': rentPrice,
    'roomCount': roomCount,
    'bathroomCount': bathroomCount,
    'currentResidents': currentResidents,
    'homeRules': homeRules,
    'features': features,
    'imageUrls': imageUrls,
    'billsIncluded': billsIncluded,
    'roomType': roomType,
    'bondType': bondType,
    'minimumStay': minimumStay,
    'gender': gender,
    'age': age,
    'religion': religion,
    'dietaryPreference': dietaryPreference,
  };
}

// ─── Response Model (기존 유지) ────────────────────────────────────────────────
class SharehouseCreateResponse {
  final String dateTime;
  final String version;
  final int code;
  final String message;
  final SharehouseCreatedData data;

  SharehouseCreateResponse({
    required this.dateTime,
    required this.version,
    required this.code,
    required this.message,
    required this.data,
  });

  factory SharehouseCreateResponse.fromJson(Map<String, dynamic> json) =>
      SharehouseCreateResponse(
        dateTime: json['dateTime'],
        version: json['version'],
        code: json['code'],
        message: json['message'],
        data: SharehouseCreatedData.fromJson(json['data']),
      );
}

class SharehouseCreatedData {
  final int id;
  final String title;
  final String address;
  final int viewCount;
  final int wishCount;
  final String houseType;
  final String approvalStatus;
  final List<String> imageUrls;
  final bool wishedByMe;

  SharehouseCreatedData({
    required this.id,
    required this.title,
    required this.address,
    required this.viewCount,
    required this.wishCount,
    required this.houseType,
    required this.approvalStatus,
    required this.imageUrls,
    required this.wishedByMe,
  });

  factory SharehouseCreatedData.fromJson(Map<String, dynamic> json) =>
      SharehouseCreatedData(
        id: json['id'],
        title: json['title'],
        address: json['address'],
        viewCount: json['viewCount'],
        wishCount: json['wishCount'],
        houseType: json['houseType'],
        approvalStatus: json['approvalStatus'],
        imageUrls: List<String>.from(json['imageUrls']),
        wishedByMe: json['wishedByMe'],
      );
}
