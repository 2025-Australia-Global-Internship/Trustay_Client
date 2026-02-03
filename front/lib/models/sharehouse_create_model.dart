// ─── Request ─────────────────────────────────────────────────────────────────
class SharehouseCreateRequest {
  final String title;
  final String description;
  final String address;
  final String houseType; // APARTMENT, HOUSE, UNIT, TOWNHOUSE
  final int rentPrice;
  final int roomCount;
  final int bathroomCount;
  final int currentResidents;
  final List<String> options;
  final List<String> imageUrls;

  SharehouseCreateRequest({
    required this.title,
    required this.description,
    required this.address,
    required this.houseType,
    required this.rentPrice,
    required this.roomCount,
    required this.bathroomCount,
    required this.currentResidents,
    required this.options,
    required this.imageUrls,
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
    'options': options,
    'imageUrls': imageUrls,
  };
}

// ─── Response ────────────────────────────────────────────────────────────────
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
  final String houseType; // APARTMENT, HOUSE, UNIT, TOWNHOUSE
  final String approvalStatus; // PENDING, ...
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
