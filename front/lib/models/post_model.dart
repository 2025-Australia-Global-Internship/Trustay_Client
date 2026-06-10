/// 서버 [PostRes] 응답에 대응
class PostModel {
  final int id;
  final int? communityId;
  final int? sharehouseId;
  final String title;
  final String content;
  final bool isNotice;
  final int viewCount;
  final int likeCount;
  final String authorName;
  final String? authorEmail;
  final String? profileImageUrl;
  final List<String> imageUrls;
  final String? regTime;
  final String? modTime;

  PostModel({
    required this.id,
    this.communityId,
    this.sharehouseId,
    required this.title,
    required this.content,
    this.isNotice = false,
    this.viewCount = 0,
    this.likeCount = 0,
    required this.authorName,
    this.authorEmail,
    this.profileImageUrl,
    this.imageUrls = const [],
    this.regTime,
    this.modTime,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? 0,
      communityId: json['communityId'] as int?,
      sharehouseId: json['sharehouseId'] as int?,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isNotice: json['isNotice'] ?? false,
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      authorName: json['authorName'] ?? '',
      authorEmail: json['authorEmail'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : const [],
      regTime: json['regTime']?.toString(),
      modTime: json['modTime']?.toString(),
    );
  }
}
