class SharehouseCreateRequest {
  final String title;
  final String shortDescription;
  final String address;
  final String detailedAddress;
  final String propertyType; // HOUSE, APARTMENT, UNIT, TOWNHOUSE
  final String billsIncluded; // YES, NO, PARTIALLY
  final String roomType; // PRIVATE_ROOM, SHARED_ROOM
  final bool isEntirePlace;
  final int rentPerWeek;
  final int bond; // weeks
  final int minimumStay; // weeks
  final List<String>
  homeRules; // NO_SMOKING, NO_PARTIES, PETS_ALLOWED, GUESTS_ALLOWED
  final List<String> features; // DOUBLE_BED, QUEEN_BED, BED_SIDE_TABLE, etc.
  final List<String> imageUrls;
  final String gender; // MALE, FEMALE, ANY

  SharehouseCreateRequest({
    required this.title,
    required this.shortDescription,
    required this.address,
    required this.detailedAddress,
    required this.propertyType,
    required this.billsIncluded,
    required this.roomType,
    required this.isEntirePlace,
    required this.rentPerWeek,
    required this.bond,
    required this.minimumStay,
    required this.homeRules,
    required this.features,
    required this.imageUrls,
    required this.gender,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'shortDescription': shortDescription,
    'address': address,
    'detailedAddress': detailedAddress,
    'propertyType': propertyType,
    'billsIncluded': billsIncluded,
    'roomType': roomType,
    'isEntirePlace': isEntirePlace,
    'rentPerWeek': rentPerWeek,
    'bond': bond,
    'minimumStay': minimumStay,
    'homeRules': homeRules,
    'features': features,
    'imageUrls': imageUrls,
    'gender': gender,
  };
}
