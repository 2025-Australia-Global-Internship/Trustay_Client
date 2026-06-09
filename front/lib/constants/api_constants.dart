class ApiConstants {
  // 기본 도메인(끝에 슬래시 없음)
  // static const String baseUrl = 'http://10.0.2.2:8080'; //    -- 로컬
  // static const String baseUrl = 'https://trustay.digitalbasis.com'; // -- 서버
  static const String baseUrl =
      'http://trustay.mirim-it-show.site:8080'; // -- 서버

  /// HTTP(S) baseUrl을 WebSocket(WSS) 스킴으로 변환
  /// 예) http://host:8080 → ws://host:8080
  ///     https://host    → wss://host
  static String get wsBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return 'wss://${baseUrl.substring('https://'.length)}';
    }
    if (baseUrl.startsWith('http://')) {
      return 'ws://${baseUrl.substring('http://'.length)}';
    }
    return baseUrl;
  }
}
