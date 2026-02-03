class User {
  final int memberId;
  final String name;
  final String email;
  final String? profileImageUrl;
  String? location;

  User({
    required this.memberId,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.location,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      memberId: json['memberId'],
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      location: json['location'] ?? "Melbourne",
    );
  }
}
