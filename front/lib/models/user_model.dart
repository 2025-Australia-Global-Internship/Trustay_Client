class User {
  final int memberId;
  final String name;
  final String email;
  final String? profileImageUrl;

  /// 서버 GET /api/trustay/members/profile 응답에 포함되는 추가 정보
  final String? birth; // 형식: yyyy-MM-dd (서버 BIRTH_REGEX)
  final String? phone; // 형식: 0XX-XXXX-XXXX (서버 PHONE_REGEX)
  final String? gender;
  final String? address; // 서버 Profile.address (도시/지역)
  final String? accountInfo;
  final List<String> roles;

  /// 클라이언트 단에서만 사용하는 표시용 위치 문자열.
  /// 서버의 `address` 가 우선이며, 없을 때 기본값으로 채움.
  String? location;

  User({
    required this.memberId,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.birth,
    this.phone,
    this.gender,
    this.address,
    this.accountInfo,
    this.roles = const [],
    this.location,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final dynamic rolesField = json['roles'];
    final List<String> roleList = rolesField is List
        ? rolesField.map((e) => e.toString()).toList()
        : <String>[];

    final String? serverAddress = json['address'] as String?;

    return User(
      memberId: json['memberId'],
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      birth: json['birth'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      address: serverAddress,
      accountInfo: json['accountInfo'] as String?,
      roles: roleList,
      // 서버 address가 있으면 그걸 우선 사용, 없으면 기존 location 또는 기본값
      location: serverAddress ?? (json['location'] as String? ?? 'Melbourne'),
    );
  }

  /// 필요 최소한의 필드만 갱신한 사본 생성
  User copyWith({
    String? name,
    String? profileImageUrl,
    String? birth,
    String? phone,
    String? gender,
    String? address,
    String? accountInfo,
    String? location,
  }) {
    return User(
      memberId: memberId,
      name: name ?? this.name,
      email: email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      birth: birth ?? this.birth,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      accountInfo: accountInfo ?? this.accountInfo,
      roles: roles,
      location: location ?? this.location,
    );
  }
}
