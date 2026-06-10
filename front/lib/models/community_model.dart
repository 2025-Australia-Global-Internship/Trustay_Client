/// 서버 [CommunityRes] 응답에 대응
class CommunityModel {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int memberCount;
  final String ownerName;
  final String? regTime; // ISO 8601

  CommunityModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.memberCount = 0,
    this.ownerName = '',
    this.regTime,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      memberCount: json['memberCount'] ?? 0,
      ownerName: json['ownerName'] ?? '',
      regTime: json['regTime']?.toString(),
    );
  }
}
