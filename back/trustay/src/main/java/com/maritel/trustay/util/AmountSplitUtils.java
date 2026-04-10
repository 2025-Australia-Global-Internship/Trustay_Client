package com.maritel.trustay.util;

import lombok.AccessLevel;
import lombok.NoArgsConstructor;

/**
 * 총액을 N명에게 원 단위로 균등 분배합니다. 나머지 원은 앞쪽 인원에게 1원씩 배정합니다.
 */
@NoArgsConstructor(access = AccessLevel.PRIVATE)
public final class AmountSplitUtils {

    public static long[] splitEvenly(long totalAmount, int participantCount) {
        if (participantCount < 1) {
            throw new IllegalArgumentException("participantCount must be >= 1");
        }
        if (totalAmount < 0) {
            throw new IllegalArgumentException("totalAmount must be >= 0");
        }
        long base = totalAmount / participantCount;
        long remainder = totalAmount % participantCount;
        long[] shares = new long[participantCount];
        for (int i = 0; i < participantCount; i++) {
            shares[i] = base + (i < remainder ? 1L : 0L);
        }
        return shares;
    }
}
