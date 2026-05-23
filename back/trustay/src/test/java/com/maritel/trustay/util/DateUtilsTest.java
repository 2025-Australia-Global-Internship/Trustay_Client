package com.maritel.trustay.util;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Date;

import static org.junit.jupiter.api.Assertions.assertEquals;

class DateUtilsTest {

    @Test
    void toLocalDateTime_parsesDefaultDateTimeFormat() {
        LocalDateTime parsed = DateUtils.toLocalDateTime("2026-04-22 13:45:59");

        assertEquals(2026, parsed.getYear());
        assertEquals(4, parsed.getMonthValue());
        assertEquals(22, parsed.getDayOfMonth());
        assertEquals(13, parsed.getHour());
        assertEquals(45, parsed.getMinute());
        assertEquals(59, parsed.getSecond());
    }

    @Test
    void getToLocalDate_formatsDateAsKoreanDate() {
        String formatted = DateUtils.getToLocalDate(LocalDate.of(2026, 4, 22));

        assertEquals("2026년 04월 22일", formatted);
    }

    @Test
    void dateAndLocalDateTime_conversionRoundTrip_keepsTimeComponents() {
        LocalDateTime original = LocalDateTime.of(2026, 4, 22, 9, 10, 11);

        Date date = DateUtils.toDate(original);
        LocalDateTime converted = DateUtils.toLocalDateTime(date);

        assertEquals(original.getYear(), converted.getYear());
        assertEquals(original.getMonthValue(), converted.getMonthValue());
        assertEquals(original.getDayOfMonth(), converted.getDayOfMonth());
        assertEquals(original.getHour(), converted.getHour());
        assertEquals(original.getMinute(), converted.getMinute());
        assertEquals(original.getSecond(), converted.getSecond());
    }
}
