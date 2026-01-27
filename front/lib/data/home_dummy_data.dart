import '../models/house_dummy.dart';

final List<HouseDummy> popularHousesDummy = [
  HouseDummy(
    id: 1,
    title: '3 Rooms in Share House',
    address: 'Greenwich Village',
    houseType: 'HOUSE',
    approvalStatus: 'APPROVED',
    imageUrls: ['https://images.unsplash.com/photo-1560185127-6ed189bf02f4'],
    price: 320,
    beds: 3,
    baths: 2,
    people: 3,
  ),
  HouseDummy(
    id: 2,
    title: 'Cozy Apartment',
    address: 'Downtown',
    houseType: 'APARTMENT',
    approvalStatus: 'APPROVED',
    imageUrls: ['https://images.unsplash.com/photo-1502673530728-f79b4cab31b1'],
    price: 280,
    beds: 2,
    baths: 1,
    people: 2,
  ),
];
