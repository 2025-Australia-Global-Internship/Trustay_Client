/// 서버 `RecentSearchRes` 응답 또는 로컬 저장 형식 모두를 담을 수 있는 모델.
///
/// - 서버에서 내려온 경우: `id` 는 레코드 PK. 칩의 X 버튼 → DELETE 시 사용.
/// - 로컬 폴백(미로그인 등) 경우: `id = null`. 화면에서 삭제 호출은 무시.
class SearchHistory {
  final int? id;
  final String query;
  final DateTime timestamp;

  SearchHistory({this.id, required this.query, required this.timestamp});

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'query': query,
    'timestamp': timestamp.toIso8601String(),
  };

  /// 로컬 저장본(`SharedPreferences`) 역직렬화.
  factory SearchHistory.fromJson(Map<String, dynamic> json) => SearchHistory(
    id: json['id'] is int ? json['id'] as int : null,
    query: json['query'] ?? '',
    timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
        DateTime.now(),
  );

  /// 서버 응답 `RecentSearchRes` 매핑.
  ///   { "id": 17, "keyword": "Bondi", "searchedAt": "2026-06-10T19:55:01.123" }
  factory SearchHistory.fromApi(Map<String, dynamic> json) => SearchHistory(
    id: (json['id'] as num?)?.toInt(),
    query: (json['keyword'] ?? '').toString(),
    timestamp:
        DateTime.tryParse(json['searchedAt']?.toString() ?? '') ?? DateTime.now(),
  );
}
