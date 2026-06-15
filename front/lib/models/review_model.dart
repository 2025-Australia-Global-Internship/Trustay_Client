/// 백엔드 `ReviewRes` 1:1 대응.
class ReviewModel {
  final int id;
  final int? houseId;
  final int authorId;
  final String authorName;
  final String? authorProfileImageUrl;
  final int rating; // 1~5
  final String? content;
  final String? regTime;
  final String? modTime;

  ReviewModel({
    required this.id,
    required this.houseId,
    required this.authorId,
    required this.authorName,
    required this.authorProfileImageUrl,
    required this.rating,
    required this.content,
    required this.regTime,
    required this.modTime,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      houseId: (json['houseId'] as num?)?.toInt(),
      authorId: (json['authorId'] as num?)?.toInt() ?? 0,
      authorName: json['authorName']?.toString() ?? '',
      authorProfileImageUrl: json['authorProfileImageUrl'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      content: json['content'] as String?,
      regTime: json['regTime']?.toString(),
      modTime: json['modTime']?.toString(),
    );
  }
}

/// 매물 한 건의 평점 요약 (`/reviews/house/{id}/summary` 응답).
class RatingSummary {
  final int houseId;
  final double averageRating;
  final int reviewCount;

  const RatingSummary({
    required this.houseId,
    required this.averageRating,
    required this.reviewCount,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      houseId: (json['houseId'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty = RatingSummary(
    houseId: 0,
    averageRating: 0.0,
    reviewCount: 0,
  );
}
