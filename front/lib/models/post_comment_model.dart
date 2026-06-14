/// 서버 [CommentRes] 응답에 대응
///
/// 백엔드는 soft delete 를 사용한다.
/// - `isDeleted == true` 인 댓글은 본문이 "(This comment was deleted.)" 로 대체된 채로 함께 내려온다.
/// - 클라이언트는 비활성 스타일로 표시한다.
class PostCommentModel {
  final int id;
  final int postId;
  final int? authorId;
  final String authorName;
  final String? authorProfileImageUrl;
  final String content;
  final bool isDeleted;
  final String? regTime;
  final String? modTime;

  PostCommentModel({
    required this.id,
    required this.postId,
    this.authorId,
    required this.authorName,
    this.authorProfileImageUrl,
    required this.content,
    this.isDeleted = false,
    this.regTime,
    this.modTime,
  });

  factory PostCommentModel.fromJson(Map<String, dynamic> json) {
    return PostCommentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      authorId: (json['authorId'] as num?)?.toInt(),
      authorName: json['authorName']?.toString() ?? '',
      authorProfileImageUrl: json['authorProfileImageUrl']?.toString(),
      content: json['content']?.toString() ?? '',
      isDeleted: json['isDeleted'] == true,
      regTime: json['regTime']?.toString(),
      modTime: json['modTime']?.toString(),
    );
  }
}
