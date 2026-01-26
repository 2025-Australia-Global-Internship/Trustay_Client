package com.maritel.trustay.constant;

import lombok.Getter;
import org.springframework.context.annotation.Bean;

import java.util.regex.Pattern;

@Getter
public class PatternConstants {
    // 어노테이션에서 쓸 수 있도록 public static final 상수로 선언
    public static final String EMAIL_REGEX = "^[a-zA-Z0-9_+&*-]+(?:\\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,7}$";
    public static final String NAME_REGEX = "^[a-zA-Z0-9가-힣]{2,25}$";
    public static final String PASSWORD_REGEX = "^[a-zA-Z0-9!@#$%^&*?_]{8,50}$";
    public static final String BIRTH_REGEX = "^\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])$";
    public static final String PHONE_REGEX = "^(0\\d{1,2})-(\\d{3,4})-(\\d{4})$";
    public static final String ACCOUNT_REGEX = "([0-9,\\-]{3,6}\\-[0-9,\\-]{2,6}\\-[0-9,\\-])\n";

    public static final String EMAIL_MESSAGE = "이메일 형식이 올바르지 않습니다.";
    public static final String NAME_MESSAGE = "이름은 문자만 입력 가능합니다.";
    public static final String PASSWORD_MESSAGE = "비밀번호는 영문자, 숫자, 특수문자(!@#$%^&*?_)만 포함하여 8~50자 사이여야 합니다.";
    public static final String BIRTH_MESSAGE = "생년월일 형식은 yyyy-mm-dd입니다.";
    public static final String PHONE_MESSAGE = "전화번호 형식은 000-0000-0000입니다.";
    public static final String ACCOUNT_MESSAGE = "올바른 계좌번호 형식이 아닙니다.";

}
