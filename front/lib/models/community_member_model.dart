/// 서버 [CommunityMemberRes] 응답에 대응.
/// 커뮤니티 상세 화면의 상단 멤버 아바타 행 등에 사용.
class CommunityMemberModel {
  final int memberId;
  final String name;
  final String? profileImageUrl;

  const CommunityMemberModel({
    required this.memberId,
    required this.name,
    this.profileImageUrl,
  });

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    return CommunityMemberModel(
      memberId: (json['memberId'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
