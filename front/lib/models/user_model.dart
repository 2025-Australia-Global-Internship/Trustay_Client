class User {
  final int memberId;
  final String name;
  final String email;
  final String? profileImageUrl;

  /// 백엔드 Profile.address 와 동일한 값 (예: "Melbourne, Australia")
  String? location;

  // 백엔드 ProfileRes 의 프로필 상세 정보
  String? birth; // yyyy-MM-dd
  String? phone; // 000-0000-0000
  String? gender; // 'male' | 'female'
  String? accountInfo;

  User({
    required this.memberId,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.location,
    this.birth,
    this.phone,
    this.gender,
    this.accountInfo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      memberId: json['memberId'],
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      // 서버는 address 로 내려주고, 클라에서는 location 으로 통일해서 사용
      location: (json['address'] as String?) ?? (json['location'] as String?),
      birth: json['birth'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      accountInfo: json['accountInfo'] as String?,
    );
  }
}
