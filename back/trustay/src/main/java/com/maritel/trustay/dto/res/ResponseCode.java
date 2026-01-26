package com.maritel.trustay.dto.res;

import lombok.Getter;

@Getter
public enum ResponseCode {
    /* Success  */
    SUCCESS(200, "요청이 성공적으로 처리되었습니다."),

    /* 404 Not Found */
    NOT_FOUND(404, "존재하지 않는 계정입니다"),

    /* Already Exist */
    ALREADY_EXIST_USER_EMAIL(1001, "입력하신 이메일이 이미 존재합니다."),
    ALREADY_EXIST_USER_MOBILE(1001, "입력하신 휴대폰 번호가 이미 존재합니다."),
    ALREADY_EXIST_USER_PUSH_TOKEN(1001, "해당 푸시 토큰이 이미 존재합니다."),
    ALREADY_EXIST_USER_SNS_CONNECTIED(1001, "이미 연동된 계정이 존재합니다."),

    /* Not Matched */
    NOT_MATCHED(1002, "입력하신 정보가 일치하지 않습니다."),
    NOT_MATCHED_PASSWORD(1002, "입력하신 비밀번호가 일치하지 않습니다."),

    /* Not Valid */
    NOT_VALID(4000, "처리할 수 없는 데이터입니다."),

    /* Bad Request & Not Entered */
    NOT_ENTERED_REQUEST_BODY(4001, "요청 파라미터가 누락되었습니다."),
    NOT_ENTERED_REQUEST_BODY_FIELD(4002, "정보가 입력되지 않았습니다."),
    NOT_ENTERED_REQUEST_PARAM(4002, "파라미터 정보가 누락되었습니다."),
    NOT_ENTERED_FILE(4002, "파일이 누락되었습니다."),

    /* Forbidden */
    FORBIDDEN(4030, "접근 권한이 없습니다."),
    FORBIDDEN_NOT_VALID(4031, "유효하지 않은 계정입니다."),
    FORBIDDEN_NOT_VALID_PASSWORD(4031, "유효하지 않은 비밀번호 패턴입니다."),

    /* Not Found */
    NOT_FOUND_USER(4041, "유저를 찾을 수 없습니다."),
    NOT_FOUND_GALLERY(4041, "존재하지 않는 게시물입니다"),
    NOT_FOUND_COUNTRY_CODE(4041, "국가 코드가 존재하지 않습니다."),
    NOT_FOUND_CITY(4041, "도시가 존재하지 않습니다."),
    NOT_FOUND_REASON_OF_JOIN(4041, "가입 사유가 존재하지 않습니다."),
    NOT_FOUND_TERMS(4041, "약관 문서가 존재하지 않습니다."),
    NOT_FOUND_SNS_STATUS(4041, "처리할 수 없는 SNS 연동 상태입니다."),
    NOT_FOUND_BLOCK(4041, "차단 정보가 존재하지 않습니다."),
    NOT_FOUND_GOLF_CLUB(4041, "골프장이 존재하지 않습니다."),
    NOT_FOUND_GOLF_CLUB_CATEGORY(4041, "골프장 카테고리가 존재하지 않습니다."),
    NOT_FOUND_GOLF_CLUB_TAG(4041, "골프장 태그가 존재하지 않습니다."),
    NOT_FOUND_BOOKMARK(4041, "관심 골프장이 존재하지 않습니다."),
    NOT_FOUND_HOTEL(4041, "호텔이 존재하지 않습니다."),
    NOT_FOUND_HOTEL_ROOM(4041, "호텔 객실이 존재하지 않습니다"),
    NOT_FOUND_PICK_UP(4041, "픽업 서비스가 존재하지 않습니다."),
    NOT_FOUND_LOUNGE(4041, "라운지가 존재하지 않습니다"),
    NOT_FOUND_LOUNGE_LIKE(4041, "라운지 좋아요가 존재하지 않습니다"),
    NOT_FOUND_LOUNGE_COMMENT(4041, "라운지 댓글이 존재하지 않습니다"),
    NOT_FOUND_LOUNGE_COMMENT_LIKE(4041, "라운지 댓글 좋아요가 존재하지 않습니다"),
    NOT_FOUND_RESERVATION(4041, "예약이 존재하지 않습니다"),
    NOT_FOUND_REVIEW(4041, "리뷰가 존재하지 않습니다"),
    ;

    private final int code;
    private final String message;

    ResponseCode(final int code, final String message) {
        this.code = code;
        this.message = message;
    }
}
