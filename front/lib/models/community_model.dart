/// 서버 [CommunityRes] 응답에 대응
class CommunityModel {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;

  /// 서버는 enum 이름을 문자열로 내려준다(예: "FITNESS", "FOOD_AND_DRINK").
  /// 알 수 없는 값이거나 비어 있으면 [CommunityCategory.other].
  final CommunityCategory category;

  final int memberCount;

  /// 오너의 memberId. 클라이언트에서 "현재 사용자가 오너인지" 판단할 때 사용.
  final int? ownerMemberId;
  final String ownerName;
  final String? regTime; // ISO 8601

  /// 현재 사용자가 이 커뮤니티의 멤버인지 (서버 [CommunityRes.joinedByMe]).
  /// 미로그인/비제공이면 false. 디테일 화면의 "가입 / 글쓰기" 버튼 분기에 사용.
  final bool joinedByMe;

  CommunityModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.category = CommunityCategory.other,
    this.memberCount = 0,
    this.ownerMemberId,
    this.ownerName = '',
    this.regTime,
    this.joinedByMe = false,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      category: CommunityCategoryX.fromServer(json['category'] as String?),
      memberCount: json['memberCount'] ?? 0,
      ownerMemberId: (json['ownerMemberId'] as num?)?.toInt(),
      ownerName: json['ownerName'] ?? '',
      regTime: json['regTime']?.toString(),
      joinedByMe: json['joinedByMe'] == true,
    );
  }
}

/// 백엔드 [CommunityCategory] enum 과 1:1 매핑.
enum CommunityCategory {
  fitness,
  social,
  travel,
  study,
  pets,
  foodAndDrink,
  hobby,
  entertainment,
  lifestyle,
  other,
}

extension CommunityCategoryX on CommunityCategory {
  /// 서버로 보낼 때 사용하는 enum 이름 (예: "FITNESS", "FOOD_AND_DRINK").
  String get serverValue {
    switch (this) {
      case CommunityCategory.fitness:
        return 'FITNESS';
      case CommunityCategory.social:
        return 'SOCIAL';
      case CommunityCategory.travel:
        return 'TRAVEL';
      case CommunityCategory.study:
        return 'STUDY';
      case CommunityCategory.pets:
        return 'PETS';
      case CommunityCategory.foodAndDrink:
        return 'FOOD_AND_DRINK';
      case CommunityCategory.hobby:
        return 'HOBBY';
      case CommunityCategory.entertainment:
        return 'ENTERTAINMENT';
      case CommunityCategory.lifestyle:
        return 'LIFESTYLE';
      case CommunityCategory.other:
        return 'OTHER';
    }
  }

  /// 화면 표시용 라벨.
  String get label {
    switch (this) {
      case CommunityCategory.fitness:
        return 'Fitness';
      case CommunityCategory.social:
        return 'Social';
      case CommunityCategory.travel:
        return 'Travel';
      case CommunityCategory.study:
        return 'Study';
      case CommunityCategory.pets:
        return 'Pets';
      case CommunityCategory.foodAndDrink:
        return 'Food & Drink';
      case CommunityCategory.hobby:
        return 'Hobby';
      case CommunityCategory.entertainment:
        return 'Entertainment';
      case CommunityCategory.lifestyle:
        return 'Lifestyle';
      case CommunityCategory.other:
        return 'Other';
    }
  }

  static CommunityCategory fromServer(String? raw) {
    if (raw == null || raw.isEmpty) return CommunityCategory.other;
    switch (raw) {
      case 'FITNESS':
        return CommunityCategory.fitness;
      case 'SOCIAL':
        return CommunityCategory.social;
      case 'TRAVEL':
        return CommunityCategory.travel;
      case 'STUDY':
        return CommunityCategory.study;
      case 'PETS':
        return CommunityCategory.pets;
      case 'FOOD_AND_DRINK':
        return CommunityCategory.foodAndDrink;
      case 'HOBBY':
        return CommunityCategory.hobby;
      case 'ENTERTAINMENT':
        return CommunityCategory.entertainment;
      case 'LIFESTYLE':
        return CommunityCategory.lifestyle;
      default:
        return CommunityCategory.other;
    }
  }
}
