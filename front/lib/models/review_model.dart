/// 백엔드 `ReviewRes` 1:1 대응.
class ReviewModel {
  final int id;
  final int? houseId;
  /// 대상 매물 제목 (My Reviews 카드 노출용). 매물 삭제 시 null.
  final String? houseTitle;
  /// 대상 매물 주소. 매물 삭제 시 null.
  final String? houseAddress;
  /// 대상 매물 대표 이미지 URL.
  final String? houseImageUrl;
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
    required this.houseTitle,
    required this.houseAddress,
    required this.houseImageUrl,
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
      houseTitle: json['houseTitle'] as String?,
      houseAddress: json['houseAddress'] as String?,
      houseImageUrl: json['houseImageUrl'] as String?,
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
