class User {
  final int memberId;
  final String name;
  final String email;
  final String? profileImageUrl;

  User({
    required this.memberId,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      memberId: json['memberId'],
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}
