class HouseDummy {
  final int id;
  final String title;
  final String address;
  final String houseType;
  final String approvalStatus;
  final List<String> imageUrls;
  final int price;
  final int beds;
  final int baths;
  final int currentResidents;

  HouseDummy({
    required this.id,
    required this.title,
    required this.address,
    required this.houseType,
    required this.approvalStatus,
    required this.imageUrls,
    required this.price,
    required this.beds,
    required this.baths,
    required this.currentResidents,
  });
}
