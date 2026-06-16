import 'package:intl/intl.dart';

/// 호주달러(AUD) ↔ 원화(KRW) 고정 환율 유틸.
///
/// 토스페이먼츠 결제위젯은 KRW 정수만 받기 때문에, 우리 앱은 단위를
/// 다음과 같이 엄격하게 분리한다.
///
///   - DB / 서버 응답 `amount`            → KRW 정수
///   - 토스 결제 `setAmount({ value })`   → KRW 정수
///   - 사용자 입력 / 화면 표시           → AUD (소수 가능)
///
/// 이 파일은 두 단위 사이의 환산과 표기를 한 곳에서 처리하는 단일 진입점이다.
/// 운영 단계에서 외부 환율 API 가 붙으면 [kAudToKrwRate] 만 동적 값으로
/// 갈아끼우면 된다.
///
/// 데모 단계에서는 "1 AUD ≈ 1,000 KRW" 의 단순 라운드 환율을 사용한다.
const int kAudToKrwRate = 1000;

/// AUD 값을 KRW 정수로 환산한다. (소수점 이하 반올림)
///
/// 사용 위치 : 서버에 amount 를 보내기 직전, 토스에 setAmount 호출 직전 등
/// "단위를 KRW 로 바꿔야 하는 경계" 에서만 호출한다.
int audToKrw(num aud) => (aud * kAudToKrwRate).round();

/// KRW 값을 AUD 로 환산한다. (실수 반환 — 표시 단계에서 자릿수 결정)
///
/// 사용 위치 : 서버/DB 에서 받아온 KRW amount 를 화면에 AUD 로 표기할 때.
double krwToAud(num krw) => krw / kAudToKrwRate;

NumberFormat _audFormat({required int decimalDigits}) => NumberFormat.currency(
      locale: 'en_AU',
      symbol: '\$',
      decimalDigits: decimalDigits,
    );

final NumberFormat _krwFormat = NumberFormat.currency(
  locale: 'ko_KR',
  symbol: '₩',
  decimalDigits: 0,
);

/// AUD 단순 표기 — 예: "\$166" (또는 [showCents] 시 "\$166.00").
String formatAud(num aud, {bool showCents = false}) =>
    _audFormat(decimalDigits: showCents ? 2 : 0).format(aud);

/// KRW 단순 표기 — 예: "₩166,000".
String formatKrw(num krw) => _krwFormat.format(krw);

/// AUD 입력값을 받아 "\$166 (₩166,000)" 형식으로 환산 표기한다.
///
/// 입력 폼에서 사용자가 보는 미리보기, 1인당 분담 금액 표기 등에 사용한다.
String formatAudWithKrw(num aud, {bool showCents = false}) {
  final krw = audToKrw(aud);
  return '${formatAud(aud, showCents: showCents)} (${formatKrw(krw)})';
}

/// 서버/DB 의 KRW 정수 amount 를 받아 "\$166 (₩166,000)" 형식으로 표기한다.
///
/// 거래 내역 카드, 차트 라벨처럼 "원본은 KRW 인 값을 AUD 위주로 보여주는"
/// 자리에서 사용한다.
String formatKrwAsAudWithKrw(num krwAmount, {bool showCents = false}) {
  final aud = krwToAud(krwAmount);
  return '${formatAud(aud, showCents: showCents)} (${formatKrw(krwAmount)})';
}
